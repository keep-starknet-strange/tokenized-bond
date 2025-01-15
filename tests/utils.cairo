use tokenized_bond::utils::constants::{OWNER, TOKEN_URI};
use snforge_std::{declare, ContractClassTrait, DeclareResultTrait};
use starknet::{ContractAddress};

// type ComponentState = ERC1155Component::ComponentState<ERC1155Mock::ContractState>;

// fn COMPONENT_STATE() -> ComponentState {
//     ERC1155Component::component_state_for_testing()
// }

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
