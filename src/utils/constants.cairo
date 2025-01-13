use starknet::{ContractAddress, contract_address_const};

pub fn OWNER() -> ContractAddress {
    contract_address_const::<'OWNER'>()
}

pub fn MINTER() -> ContractAddress {
    contract_address_const::<'MINTER'>()
}

pub fn ZERO_ADDRESS() -> ContractAddress {
    contract_address_const::<0>()
}

pub fn TOKEN_URI() -> ByteArray {
    let uri: ByteArray = "https://example.com/";
    uri
}