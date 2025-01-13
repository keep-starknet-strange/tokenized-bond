mod utils;
use tokenized_bond::{TokenizedBond, ITokenizedBondDispatcher, ITokenizedBondDispatcherTrait};
use tokenized_bond::utils::constants::{OWNER, MINTER, ZERO_ADDRESS};
use snforge_std::{EventSpyAssertionsTrait, spy_events, start_cheat_caller_address};
use utils::setup;

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