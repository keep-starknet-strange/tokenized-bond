mod utils;
use tokenized_bond::{TokenizedBond, ITokenizedBondDispatcher, ITokenizedBondDispatcherTrait};
use openzeppelin_token::erc1155::interface::{IERC1155Dispatcher, IERC1155DispatcherTrait};
use tokenized_bond::utils::constants::{OWNER, MINTER, ZERO_ADDRESS, INTEREST_RATE, MINT_AMOUNT, TOKEN_NAME, MINT_ID, TIME_IN_THE_FUTURE};
use snforge_std::{EventSpyAssertionsTrait, spy_events, start_cheat_caller_address};
use utils::{setup, setup_receiver};

#[test]
fn test_add_minter() {
    let mut spy = spy_events();

    let mut tokenized_bond = ITokenizedBondDispatcher { contract_address: setup()};

    start_cheat_caller_address(tokenized_bond.contract_address, OWNER());
    
    tokenized_bond.add_minter(MINTER());

    let expected_tokenized_bond_event = TokenizedBond::Event::MinterAdded(
        TokenizedBond::MinterAdded {
            minter: MINTER(),
        }
    );

    spy.assert_emitted(@array![(tokenized_bond.contract_address, expected_tokenized_bond_event)]);
}

#[test]
#[should_panic(expected: 'Caller is not the owner')]
fn test_add_minter_not_owner() {
    let mut tokenized_bond = ITokenizedBondDispatcher { contract_address: setup()};

    start_cheat_caller_address(tokenized_bond.contract_address, MINTER());
    
    tokenized_bond.add_minter(MINTER());
}

#[test]
#[should_panic(expected: 'Minter already exists')]
fn test_add_minter_already_exists() {
    let mut tokenized_bond = ITokenizedBondDispatcher { contract_address: setup()};

    start_cheat_caller_address(tokenized_bond.contract_address, OWNER());
    
    tokenized_bond.add_minter(MINTER());
    tokenized_bond.add_minter(MINTER());
}

#[test]
#[should_panic(expected: 'Minter address cant be the zero')]
fn test_add_minter_zero_address() {
    let mut tokenized_bond = ITokenizedBondDispatcher { contract_address: setup()};

    start_cheat_caller_address(tokenized_bond.contract_address, OWNER());
    
    tokenized_bond.add_minter(ZERO_ADDRESS());
}

#[test]
fn test_remove_minter() {
    let mut spy = spy_events();

    let mut tokenized_bond = ITokenizedBondDispatcher { contract_address: setup()};

    start_cheat_caller_address(tokenized_bond.contract_address, OWNER());
    
    tokenized_bond.add_minter(MINTER());
    tokenized_bond.remove_minter(MINTER());

    let expected_tokenized_bond_event = TokenizedBond::Event::MinterRemoved(
        TokenizedBond::MinterRemoved {
            minter: MINTER(),
        }
    );

    spy.assert_emitted(@array![(tokenized_bond.contract_address, expected_tokenized_bond_event)]);
}

#[test]
#[should_panic(expected: 'Caller is not the owner')]
fn test_remove_minter_not_owner() {
    let mut tokenized_bond = ITokenizedBondDispatcher { contract_address: setup()};

    start_cheat_caller_address(tokenized_bond.contract_address, MINTER());
    
    tokenized_bond.remove_minter(MINTER());
}

#[test]
fn test_mint_success() {
    let mut tokenized_bond = ITokenizedBondDispatcher { contract_address: setup()};
    let receiver = setup_receiver();
    let erc_1155 = IERC1155Dispatcher { contract_address: tokenized_bond.contract_address};
    start_cheat_caller_address(tokenized_bond.contract_address, OWNER());

    tokenized_bond.add_minter(receiver);

    start_cheat_caller_address(tokenized_bond.contract_address, receiver);

    tokenized_bond.mint(TIME_IN_THE_FUTURE(), INTEREST_RATE(), MINT_ID(), MINT_AMOUNT(), false, TOKEN_NAME());
    start_cheat_caller_address(tokenized_bond.contract_address, tokenized_bond.contract_address);

    let minter_balance = erc_1155.balance_of(account: receiver, token_id: MINT_ID());
    assert(minter_balance == MINT_AMOUNT(), 'Minter balance is not correct');
}