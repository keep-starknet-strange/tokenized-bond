use tokenized_bond::utils::constants::OWNER;
use tokenized_bond::ITokenizedBond;
use snforge_std::{declare, ContractClassTrait, DeclareResultTrait, start_cheat_caller_address};
use starknet::ContractAddress;

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

    declare_deploy("TokenizedBond", calldata)
}