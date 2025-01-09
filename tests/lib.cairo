mod utils;
use tokenized_bond::{TokenizedBond, ITokenizedBondDispatcher, ITokenizedBondDispatcherTrait};
use tokenized_bond::utils::constants::{OWNER, MINTER};
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