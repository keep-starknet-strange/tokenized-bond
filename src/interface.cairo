use starknet::ContractAddress;

#[starknet::interface]
pub trait ITokenizedBond<TState> {
    fn add_minter(ref self: TState, minter: ContractAddress);
    fn remove_minter(ref self: TState, minter: ContractAddress);
    fn mint(ref self: TState, expiration_date: u64, interest_rate: u32, token_id: u256, amount: u256, custodial: bool, name: ByteArray);
}
