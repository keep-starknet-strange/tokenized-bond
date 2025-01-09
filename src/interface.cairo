use starknet::ContractAddress;

#[starknet::interface]
pub trait ITokenizedBond<TState> {
    fn add_minter(ref self: TState, minter: ContractAddress);
    fn remove_minter(ref self: TState, minter: ContractAddress);
}