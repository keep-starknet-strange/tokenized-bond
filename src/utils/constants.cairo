use starknet::{ContractAddress, contract_address_const, get_block_timestamp};

pub fn OWNER() -> ContractAddress {
    contract_address_const::<'OWNER'>()
}

pub fn MINTER() -> ContractAddress {
    contract_address_const::<'MINTER'>()
}

pub fn ZERO_ADDRESS() -> ContractAddress {
    contract_address_const::<0>()
}

pub fn INTEREST_RATE() -> u32 {
    10
}

pub fn INTEREST_RATE_ZERO() -> u32 {
    0
}

pub fn MINT_AMOUNT() -> u256 {
    100
}

pub fn MINT_ID() -> u256 {
    42
}

pub fn TOKEN_NAME() -> ByteArray {
    let name: ByteArray = "Test Bond";
    name
}

pub fn URI() -> ByteArray {
    let uri: ByteArray = "URI";
    uri
}

pub fn TIME_IN_THE_FUTURE() -> u64 {
    get_block_timestamp() + 1000
}

pub fn TIME_IN_THE_PAST() -> u64 {
    get_block_timestamp() - 1000
}

