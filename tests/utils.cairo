use tokenized_bond::utils::constants::{
    OWNER, TOKEN_URI, TIME_IN_THE_FUTURE, INTEREST_RATE, TOKEN_ID, MINT_AMOUNT, CUSTODIAL_FALSE,
    TOKEN_NAME, AMOUNT_TRANSFERRED,
};
use tokenized_bond::{TokenizedBond, ITokenizedBondDispatcher, ITokenizedBondDispatcherTrait};
use snforge_std::{declare, ContractClassTrait, DeclareResultTrait, start_cheat_caller_address};
use starknet::{ContractAddress};

pub trait SerializedAppend<T> {
    fn append_serde(ref self: Array<felt252>, value: T);
}

impl SerializedAppendImpl<T, impl TSerde: Serde<T>, impl TDrop: Drop<T>> of SerializedAppend<T> {
    fn append_serde(ref self: Array<felt252>, value: T) {
        value.serialize(ref self);
    }
}

pub fn declare_deploy(contract_name: ByteArray, calldata: Array<felt252>) -> ContractAddress {
    let contract = declare(contract_name).unwrap().contract_class();
    let (contract_address, _) = contract.deploy(@calldata).unwrap();
    contract_address
}

pub fn setup() -> ContractAddress {
    let mut calldata: Array<felt252> = array![];
    calldata.append_serde(OWNER());
    calldata.append_serde(TOKEN_URI());
    declare_deploy("TokenizedBond", calldata)
}

pub fn setup_receiver() -> ContractAddress {
    // let state = COMPONENT_STATE();
    let mut calldata: Array<felt252> = array![];

    declare_deploy("MockERC1155Receiver", calldata)
}

pub fn setup_contract_with_minter() -> (ITokenizedBondDispatcher, ContractAddress) {
    let mut tokenized_bond = ITokenizedBondDispatcher { contract_address: setup() };
    let minter = setup_receiver();

    start_cheat_caller_address(tokenized_bond.contract_address, OWNER());
    tokenized_bond.add_minter(minter);

    start_cheat_caller_address(tokenized_bond.contract_address, minter);
    tokenized_bond
        .mint(
            TIME_IN_THE_FUTURE(),
            INTEREST_RATE(),
            TOKEN_ID(),
            MINT_AMOUNT(),
            CUSTODIAL_FALSE(),
            TOKEN_NAME(),
        );
    (tokenized_bond, minter)
}

pub fn setup_transfer(
    from: ContractAddress, to: ContractAddress, amount: u256,
) -> Array<TokenizedBond::TransferParam> {
    let destination = array![
        TokenizedBond::TransferDestination { receiver: to, amount: amount, token_id: TOKEN_ID() },
    ];

    array![TokenizedBond::TransferParam { from: from, to: destination }]
}

pub fn address_with_tokens(
    token_contract: ITokenizedBondDispatcher, minter: ContractAddress,
) -> ContractAddress {
    let address_with_tokens = setup_receiver();

    start_cheat_caller_address(token_contract.contract_address, minter);
    let transfer = setup_transfer(
        from: minter, to: address_with_tokens, amount: AMOUNT_TRANSFERRED(),
    );
    token_contract.make_transfer(transfer);
    address_with_tokens
}
