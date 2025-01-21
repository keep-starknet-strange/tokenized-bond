use starknet::ContractAddress;
use tokenized_bond::TokenizedBond::TransferParam;

#[starknet::interface]
pub trait ITokenizedBond<TState> {
    fn add_minter(ref self: TState, minter: ContractAddress);
    fn remove_minter(ref self: TState, minter: ContractAddress);
    fn replace_minter(ref self: TState, old_minter: ContractAddress, new_minter: ContractAddress);
    fn mint(
        ref self: TState,
        expiration_date: u64,
        interest_rate: u32,
        token_id: u256,
        amount: u256,
        custodial: bool,
        name: ByteArray,
    );
    fn burn(ref self: TState, token_id: u256, amount: u256);
    fn make_transfer(ref self: TState, to: Array<TransferParam>);
}
