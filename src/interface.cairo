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
    fn resume_inter_transfer(ref self: TState, token_id: u256);
    fn pause(ref self: TState);
    fn unpause(ref self: TState);
    fn pause_inter_transfer(ref self: TState, token_id: u256);
    fn resume_itr_after_expiry(ref self: TState, token_id: u256);
    fn pause_itr_after_expiry(ref self: TState, token_id: u256);
    fn freeze_token(ref self: TState, token_id: u256);
    fn unfreeze_token(ref self: TState, token_id: u256);
    fn make_transfer(ref self: TState, transfers: Array<TransferParam>);
    fn set_minter_as_operator(ref self: TState, token_id: u256);
    fn unset_minter_as_operator(ref self: TState, token_id: u256);
    fn minter_is_operator(self: @TState, token_id: u256, minter: ContractAddress) -> bool;
    fn check_owner_and_operator(self: @TState, transfers: Array<TransferParam>) -> bool;
}
