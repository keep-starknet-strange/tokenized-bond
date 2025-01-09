use starknet::{ContractAddress, contract_address_const};

pub fn OWNER() -> ContractAddress {
    contract_address_const::<'OWNER'>()
}

pub fn MINTER() -> ContractAddress {
    contract_address_const::<'MINTER'>()
}