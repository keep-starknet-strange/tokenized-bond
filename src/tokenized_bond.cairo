#[starknet::contract]
pub mod TokenizedBond {
    use tokenized_bond::ITokenizedBond;
    use tokenized_bond::utils::constants::ZERO_ADDRESS;
    use openzeppelin_access::ownable::OwnableComponent;
    use openzeppelin_introspection::src5::SRC5Component;
    use openzeppelin_security::pausable::PausableComponent;
    use openzeppelin_token::erc1155::ERC1155Component;
    use openzeppelin_upgrades::interface::IUpgradeable;
    use openzeppelin_upgrades::UpgradeableComponent;
    use starknet::{ClassHash, ContractAddress, get_block_timestamp, get_caller_address};
    use starknet::storage::{StoragePointerWriteAccess, StoragePathEntry, Map, Vec, MutableVecTrait};

    component!(path: ERC1155Component, storage: erc1155, event: ERC1155Event);
    component!(path: SRC5Component, storage: src5, event: SRC5Event);
    component!(path: PausableComponent, storage: pausable, event: PausableEvent);
    component!(path: OwnableComponent, storage: ownable, event: OwnableEvent);
    component!(path: UpgradeableComponent, storage: upgradeable, event: UpgradeableEvent);

    #[abi(embed_v0)]
    impl ERC1155MixinImpl = ERC1155Component::ERC1155MixinImpl<ContractState>;
    #[abi(embed_v0)]
    impl PausableImpl = PausableComponent::PausableImpl<ContractState>;
    #[abi(embed_v0)]
    impl OwnableTwoStepMixinImpl =
        OwnableComponent::OwnableTwoStepMixinImpl<ContractState>;


    impl ERC1155InternalImpl = ERC1155Component::InternalImpl<ContractState>;
    impl PausableInternalImpl = PausableComponent::InternalImpl<ContractState>;
    impl OwnableInternalImpl = OwnableComponent::InternalImpl<ContractState>;
    impl UpgradeableInternalImpl = UpgradeableComponent::InternalImpl<ContractState>;

    #[storage]
    struct Storage {
        #[substorage(v0)]
        erc1155: ERC1155Component::Storage,
        #[substorage(v0)]
        src5: SRC5Component::Storage,
        #[substorage(v0)]
        pausable: PausableComponent::Storage,
        #[substorage(v0)]
        ownable: OwnableComponent::Storage,
        #[substorage(v0)]
        upgradeable: UpgradeableComponent::Storage,
        minters: Map<ContractAddress, u8>,
        tokens: Map<u256, Token>,
        minter_tokens: Map<ContractAddress, Vec<u256>>,
    }

    #[event]
    #[derive(Drop, starknet::Event)]
    pub enum Event {
        #[flat]
        ERC1155Event: ERC1155Component::Event,
        #[flat]
        SRC5Event: SRC5Component::Event,
        #[flat]
        PausableEvent: PausableComponent::Event,
        #[flat]
        OwnableEvent: OwnableComponent::Event,
        #[flat]
        UpgradeableEvent: UpgradeableComponent::Event,
        MinterAdded: MinterAdded,
        MinterRemoved: MinterRemoved,
        MinterReplaced: MinterReplaced,
        TokenInterTransferAllowed: TokenInterTransferAllowed,
        TokenItrAfterExpiryAllowed: TokenItrAfterExpiryAllowed,
    }

    #[derive(Drop, starknet::Event)]
    pub struct MinterAdded {
        pub minter: ContractAddress,
    }

    #[derive(Drop, starknet::Event)]
    pub struct MinterRemoved {
        pub minter: ContractAddress,
    }

    #[derive(Drop, starknet::Event)]
    pub struct MinterReplaced {
        pub token_id: u256,
        pub old_minter: ContractAddress,
        pub new_minter: ContractAddress,
    }

    #[derive(Drop, starknet::Event)]
    pub struct TokenInterTransferAllowed {
        pub token_id: u256,
        pub is_transferable: bool,
    }

    #[derive(Drop, starknet::Event)]
    pub struct TokenItrAfterExpiryAllowed {
        pub token_id: u256,
        pub is_transferable: bool,
    }

    #[derive(Drop, Serde, starknet::Store)]
    pub struct Token {
        pub expiration_date: u64,
        pub interest_rate: u32,
        pub minter: ContractAddress,
        pub minter_is_operator: bool,
        pub token_frozen: bool,
        pub token_itr_paused: bool,
        pub token_itr_expiry_paused: bool,
        pub name: ByteArray,
    }

    pub mod Errors {
        pub const MINTER_ALREADY_EXISTS: felt252 = 'Minter already exists';
        pub const MINTER_DOES_NOT_EXIST: felt252 = 'Minter does not exist';
        pub const MINTER_IS_NOT_MINTER: felt252 = 'Caller is not a minter';
        pub const TOKEN_ALREADY_EXISTS: felt252 = 'Token already exists';
        pub const TOKEN_DOES_NOT_EXIST: felt252 = 'Token does not exist';
        pub const TOKEN_EXPIRATION_DATE_IN_THE_PAST: felt252 = 'Expiration date is in the past';
        pub const TOKEN_INTEREST_RATE_ZERO: felt252 = 'Interest rate 0';
        pub const TOKEN_INVALID_BURN_AMOUNT: felt252 = 'Invalid burn amount';
        pub const CALLER_IS_NOT_TOKEN_MINTER: felt252 = 'Caller is not token minter';
        pub const MINTER_ADDRESS_CANT_BE_THE_ZERO: felt252 = 'Minter address cant be the zero';
        pub const NEW_MINTER_ALREADY_EXISTS: felt252 = 'New minter already exists';
        pub const OLD_MINTER_DOES_NOT_EXIST: felt252 = 'Old minter does not exist';
        pub const CALLER_IS_NOT_A_MINTER: felt252 = 'Caller is not a minter';
        pub const TOKEN_IS_NOT_PAUSED: felt252 = 'Token transfer is not paused';
        pub const TOKEN_IS_PAUSED: felt252 = 'Token transfer is paused';
        pub const ITR_AFTER_EXPIRY_IS_NOT_PAUSED: felt252 = 'Inter after expiry not paused';
        pub const ITR_AFTER_EXPIRY_IS_PAUSED: felt252 = 'Inter after expiry is paused';
    }

    #[constructor]
    fn constructor(ref self: ContractState, owner: ContractAddress, token_uri: ByteArray) {
        self.erc1155.initializer(token_uri);
        self.ownable.initializer(owner);
    }

    #[abi(embed_v0)]
    impl TokenizedBond of ITokenizedBond<ContractState> {
        fn resume_inter_transfer(ref self: ContractState, token_id: u256) {
            self.ownable.assert_only_owner();
            assert(self.tokens.entry(token_id).read().token_itr_paused, Errors::TOKEN_IS_PAUSED);
            let mut token = self.tokens.entry(token_id).read();
            token.token_itr_paused = false;
            self.tokens.entry(token_id).write(token);
            // this logic in the solidity seems incorrect. I could be wrong
            self
                .emit(
                    TokenInterTransferAllowed {
                        token_id,
                        is_transferable: !self.tokens.entry(token_id).read().token_itr_paused,
                    },
                );
        }

        fn pause_inter_transfer(ref self: ContractState, token_id: u256) {
            self.ownable.assert_only_owner();
            assert(
                !self.tokens.entry(token_id).read().token_itr_paused, Errors::TOKEN_IS_NOT_PAUSED,
            );
            let mut token = self.tokens.entry(token_id).read();
            token.token_itr_paused = true;
            self.tokens.entry(token_id).write(token);
            self
                .emit(
                    TokenInterTransferAllowed {
                        token_id,
                        is_transferable: !self.tokens.entry(token_id).read().token_itr_paused,
                    },
                );
        }

        fn resume_itr_after_expiry(ref self: ContractState, token_id: u256) {
            self.ownable.assert_only_owner();
            assert(
                self.tokens.entry(token_id).read().token_itr_expiry_paused,
                Errors::ITR_AFTER_EXPIRY_IS_NOT_PAUSED,
            );
            let mut token = self.tokens.entry(token_id).read();
            token.token_itr_expiry_paused = false;
            self.tokens.entry(token_id).write(token);
            self
                .emit(
                    TokenItrAfterExpiryAllowed {
                        token_id,
                        is_transferable: !self.tokens.entry(token_id).read().token_itr_paused,
                    },
                );
        }

        fn pause_itr_after_expiry(ref self: ContractState, token_id: u256) {
            self.ownable.assert_only_owner();
            assert(
                !self.tokens.entry(token_id).read().token_itr_expiry_paused,
                Errors::ITR_AFTER_EXPIRY_IS_PAUSED,
            );
            let mut token = self.tokens.entry(token_id).read();
            token.token_itr_expiry_paused = true;
            self.tokens.entry(token_id).write(token);
            self
                .emit(
                    TokenItrAfterExpiryAllowed {
                        token_id,
                        is_transferable: !self
                            .tokens
                            .entry(token_id)
                            .read()
                            .token_itr_expiry_paused,
                    },
                );
        }

        fn add_minter(ref self: ContractState, minter: ContractAddress) {
            self.ownable.assert_only_owner();
            assert(minter != ZERO_ADDRESS(), Errors::MINTER_ADDRESS_CANT_BE_THE_ZERO);
            assert(self.minters.entry(minter).read() == 0, Errors::MINTER_ALREADY_EXISTS);
            self.minters.entry(minter).write(1);
            self.emit(MinterAdded { minter });
        }

        fn remove_minter(ref self: ContractState, minter: ContractAddress) {
            self.ownable.assert_only_owner();
            self.minters.entry(minter).write(0);
            self.emit(MinterRemoved { minter });
        }

        fn replace_minter(
            ref self: ContractState, old_minter: ContractAddress, new_minter: ContractAddress,
        ) {
            self.ownable.assert_only_owner();
            assert(self.minters.entry(old_minter).read() == 1, Errors::OLD_MINTER_DOES_NOT_EXIST);
            assert(self.minters.entry(new_minter).read() == 0, Errors::NEW_MINTER_ALREADY_EXISTS);
            let number_of_tokens_to_replace = self.minter_tokens.entry(old_minter).len();

            // replace old minter with new minter in all minted tokens
            for element in 0..number_of_tokens_to_replace {
                let token_id = self.minter_tokens.entry(old_minter).at(element).read();

                self.minter_tokens.entry(old_minter).at(element).write(0);
                let old_minter_balance = self.erc1155.balance_of(old_minter, token_id);

                // replace old minter with new minter in all minted tokens
                self
                    .erc1155
                    .mint_with_acceptance_check(
                        new_minter, token_id, old_minter_balance, array![].span(),
                    );
                self.erc1155.burn(old_minter, token_id, old_minter_balance);

                //add  new minter with respective tokens
                self.minter_tokens.entry(new_minter).append().write(token_id);
                let mut token = self.tokens.entry(token_id).read();
                token.minter = new_minter;
                self.tokens.entry(token_id).write(token);

                self.emit(MinterReplaced { token_id, old_minter, new_minter });
            };
            self.minters.entry(old_minter).write(0);
            self.minters.entry(new_minter).write(1);
            self.emit(MinterRemoved { minter: old_minter });
            self.emit(MinterAdded { minter: new_minter });
        }

        fn mint(
            ref self: ContractState,
            expiration_date: u64,
            interest_rate: u32,
            token_id: u256,
            amount: u256,
            custodial: bool,
            name: ByteArray,
        ) {
            let minter = get_caller_address();
            assert(
                self.tokens.entry(token_id).read().minter == ZERO_ADDRESS(),
                Errors::TOKEN_ALREADY_EXISTS,
            );
            assert(self.minters.entry(minter).read() == 1, Errors::CALLER_IS_NOT_A_MINTER);
            assert(
                expiration_date > get_block_timestamp(), Errors::TOKEN_EXPIRATION_DATE_IN_THE_PAST,
            );
            assert(interest_rate > 0, 'Interest rate 0');
            self
                .tokens
                .entry(token_id)
                .write(
                    Token {
                        expiration_date,
                        interest_rate,
                        minter: minter,
                        minter_is_operator: false,
                        token_frozen: false,
                        token_itr_paused: false,
                        token_itr_expiry_paused: false,
                        name,
                    },
                );
            self.minter_tokens.entry(minter).append().write(token_id);
            self.erc1155.mint_with_acceptance_check(minter, token_id, amount, array![].span());
        }

        fn burn(ref self: ContractState, token_id: u256, amount: u256) {
            let minter = get_caller_address();
            self.token_exists(token_id);
            self.only_token_minter(token_id);
            assert(
                self.erc1155.balance_of(minter, token_id) >= amount || amount == 0,
                Errors::TOKEN_INVALID_BURN_AMOUNT,
            );
            self.erc1155.burn(minter, token_id, amount);
        }
    }


    impl ERC1155HooksImpl of ERC1155Component::ERC1155HooksTrait<ContractState> {
        fn before_update(
            ref self: ERC1155Component::ComponentState<ContractState>,
            from: ContractAddress,
            to: ContractAddress,
            token_ids: Span<u256>,
            values: Span<u256>,
        ) {
            let contract_state = self.get_contract();
            contract_state.pausable.assert_not_paused();
        }
    }

    #[generate_trait]
    #[abi(per_item)]
    impl ExternalImpl of ExternalTrait {
        #[external(v0)]
        fn pause(ref self: ContractState) {
            self.ownable.assert_only_owner();
            self.pausable.pause();
        }

        #[external(v0)]
        fn unpause(ref self: ContractState) {
            self.ownable.assert_only_owner();
            self.pausable.unpause();
        }

        #[external(v0)]
        fn batch_mint(
            ref self: ContractState,
            account: ContractAddress,
            token_ids: Span<u256>,
            values: Span<u256>,
            data: Span<felt252>,
        ) {
            self.ownable.assert_only_owner();
            self.erc1155.batch_mint_with_acceptance_check(account, token_ids, values, data);
        }

        #[external(v0)]
        fn batchMint(
            ref self: ContractState,
            account: ContractAddress,
            tokenIds: Span<u256>,
            values: Span<u256>,
            data: Span<felt252>,
        ) {
            self.batch_mint(account, tokenIds, values, data);
        }

        #[external(v0)]
        fn set_base_uri(ref self: ContractState, base_uri: ByteArray) {
            self.ownable.assert_only_owner();
            self.erc1155._set_base_uri(base_uri);
        }

        #[external(v0)]
        fn setBaseUri(ref self: ContractState, baseUri: ByteArray) {
            self.set_base_uri(baseUri);
        }
    }

    #[abi(embed_v0)]
    impl UpgradeableImpl of IUpgradeable<ContractState> {
        fn upgrade(ref self: ContractState, new_class_hash: ClassHash) {
            self.ownable.assert_only_owner();
            self.upgradeable.upgrade(new_class_hash);
        }
    }

    #[generate_trait]
    impl InternalImpl of InternalTrait {
        fn only_token_minter(self: @ContractState, token_id: u256) {
            assert(
                self.tokens.entry(token_id).read().minter == get_caller_address(),
                Errors::CALLER_IS_NOT_TOKEN_MINTER,
            );
        }

        fn token_exists(self: @ContractState, token_id: u256) {
            assert(
                self.tokens.entry(token_id).read().minter != ZERO_ADDRESS(),
                Errors::TOKEN_DOES_NOT_EXIST,
            );
        }

        fn inter_transfer_allowed(
            self: @ContractState,
            token_id: u256,
            sender: ContractAddress,
            receiver: ContractAddress,
        ) -> bool {
            if !self.tokens.entry(token_id).read().token_itr_paused {
                return true;
            }
            if (self.tokens.entry(token_id).read().minter == sender
                || self.tokens.entry(token_id).read().minter == receiver) {
                return true;
            }
            return false;
        }

        fn is_inter_transfer_after_expiry(
            self: @ContractState, token_id: u256, receiever: ContractAddress,
        ) -> bool {
            if !self.tokens.entry(token_id).read().token_itr_expiry_paused {
                return true;
            }
            if self.tokens.entry(token_id).read().expiration_date > get_block_timestamp()
                || self.tokens.entry(token_id).read().minter == receiever {
                return true;
            }
            return false;
        }
    }
}
