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
    use starknet::storage::{StoragePointerWriteAccess, StoragePathEntry, Map};

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
    impl OwnableTwoStepMixinImpl = OwnableComponent::OwnableTwoStepMixinImpl<ContractState>;
        
        
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
    }

    #[derive(Drop, starknet::Event)]
    pub struct MinterAdded {
        pub minter: ContractAddress,
    }

    #[derive(Drop, starknet::Event)]
    pub struct MinterRemoved {
        pub minter: ContractAddress,
    }

    #[derive(Drop, Serde, starknet::Store)]
    pub struct Token {
        pub expiration_date: u64,
        pub interest_rate: u32,
        pub minter: ContractAddress,
        pub minter_is_operator: bool,
        pub token_frozen: bool,
        pub token_itr_paused: bool,
        pub name: ByteArray,
    }

    #[constructor]
    fn constructor(ref self: ContractState, owner: ContractAddress, token_uri: ByteArray) {
        self.erc1155.initializer(token_uri);
        self.ownable.initializer(owner);
    }

    #[abi(embed_v0)]
    impl TokenizedBond of ITokenizedBond<ContractState> {
        fn add_minter(ref self: ContractState, minter: ContractAddress) {
            self.ownable.assert_only_owner();
            assert(minter != ZERO_ADDRESS(), 'Minter address cant be the zero');
            assert(self.minters.entry(minter).read() == 0, 'Minter already exists');
            self.minters.entry(minter).write(1);
            self.emit(MinterAdded { minter });
        }

        fn remove_minter(ref self: ContractState, minter: ContractAddress) {
            self.ownable.assert_only_owner();
            self.minters.entry(minter).write(0);
            self.emit(MinterRemoved { minter });
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
            assert(self.tokens.entry(token_id).read().minter == ZERO_ADDRESS(), 'Token already exists');
            assert(self.minters.entry(get_caller_address()).read() == 1, 'Caller is not a minter');
            assert(expiration_date > get_block_timestamp(), 'Expiration date is in the past');
            assert(interest_rate  > 0, 'Interest rate 0');
            self.tokens.entry(token_id).write(Token {
                expiration_date,
                interest_rate,
                minter: get_caller_address(),
                minter_is_operator: false,
                token_frozen: false,
                token_itr_paused: false,
                name,
            });
            self.erc1155.mint_with_acceptance_check(
                get_caller_address(),
                token_id,
                amount,
                array![expiration_date.into()].span(),
            );
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
}