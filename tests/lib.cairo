use PausableComponent::InternalTrait;
mod utils;
use starknet::class_hash::class_hash_const;
use tokenized_bond::{TokenizedBond, ITokenizedBondDispatcher, ITokenizedBondDispatcherTrait};
use openzeppelin_access::ownable::OwnableComponent;
use openzeppelin_access::ownable::interface::{
    IOwnableTwoStepDispatcher, IOwnableTwoStepDispatcherTrait,
};
use openzeppelin_upgrades::upgradeable::UpgradeableComponent;
use openzeppelin_security::pausable::PausableComponent;
use openzeppelin_security::pausable::PausableComponent::{PausableImpl, InternalImpl};
use openzeppelin_token::erc1155::ERC1155Component;
use openzeppelin_token::erc1155::interface::{IERC1155Dispatcher, IERC1155DispatcherTrait};
use tokenized_bond::utils::constants::{
    OWNER, MINTER, ZERO_ADDRESS, INTEREST_RATE, INTEREST_RATE_ZERO, MINT_AMOUNT, TOKEN_NAME,
    TOKEN_ID, TIME_IN_THE_FUTURE, CUSTODIAL_FALSE, NOT_MINTER, NEW_MINTER, AMOUNT_TRANSFERRED,
    TRANSFER_AMOUNT, NEW_OWNER,
};
use snforge_std::{
    EventSpyAssertionsTrait, spy_events, start_cheat_caller_address, stop_cheat_caller_address,
    start_cheat_block_timestamp_global, stop_cheat_block_timestamp_global,
};
use starknet::get_block_timestamp;
use utils::{
    setup, setup_receiver, setup_contract_with_minter, setup_transfer, address_with_tokens,
    upgrade_class_hash, pauseable_component_state_for_testing,
};

#[test]
fn test_is_paused() {
    let mut state = pauseable_component_state_for_testing();

    assert(!state.is_paused(), 'Contract should not be paused');
    state.pause();
    assert(state.is_paused(), 'Contract should be paused');
}

#[test]
fn test_assert_paused_when_paused() {
    let mut state = pauseable_component_state_for_testing();
    state.pause();
    state.assert_paused();
}

#[test]
#[should_panic(expected: 'Pausable: not paused')]
fn test_assert_paused_when_not_paused() {
    let mut state = pauseable_component_state_for_testing();
    state.assert_paused();
}

#[test]
#[should_panic(expected: 'Pausable: paused')]
fn test_assert_not_paused_when_paused() {
    let mut state = pauseable_component_state_for_testing();
    state.pause();
    state.assert_not_paused();
}

#[test]
fn test_assert_not_paused_when_not_paused() {
    let mut state = pauseable_component_state_for_testing();
    state.assert_not_paused();
}

#[test]
fn test_pause_unpause_functionality() {
    let mut spy = spy_events();
    let mut tokenized_bond = ITokenizedBondDispatcher { contract_address: setup() };

    let expected_pause_event = PausableComponent::Event::Paused(
        PausableComponent::Paused { account: OWNER() },
    );
    let expected_event_unpaused = PausableComponent::Event::Unpaused(
        PausableComponent::Unpaused { account: OWNER() },
    );

    start_cheat_caller_address(tokenized_bond.contract_address, OWNER());
    tokenized_bond.pause();
    tokenized_bond.unpause();

    spy
        .assert_emitted(
            @array![
                (tokenized_bond.contract_address, expected_pause_event),
                (tokenized_bond.contract_address, expected_event_unpaused),
            ],
        );
}

#[test]
#[should_panic(expected: 'Caller is not the owner')]
fn test_pause_not_owner() {
    let mut tokenized_bond = ITokenizedBondDispatcher { contract_address: setup() };

    tokenized_bond.pause();
}

#[test]
#[should_panic(expected: 'Pausable: paused')]
fn test_pause_already_paused() {
    let mut tokenized_bond = ITokenizedBondDispatcher { contract_address: setup() };

    start_cheat_caller_address(tokenized_bond.contract_address, OWNER());
    tokenized_bond.pause();
    tokenized_bond.pause();
}

#[test]
#[should_panic(expected: 'Caller is not the owner')]
fn test_unpause_not_owner() {
    let mut tokenized_bond = ITokenizedBondDispatcher { contract_address: setup() };

    tokenized_bond.pause();
}

#[test]
#[should_panic(expected: 'Pausable: not paused')]
fn test_unpause_not_paused() {
    let mut tokenized_bond = ITokenizedBondDispatcher { contract_address: setup() };

    start_cheat_caller_address(tokenized_bond.contract_address, OWNER());
    tokenized_bond.unpause();
}

#[test]
fn test_add_minter() {
    let mut spy = spy_events();

    let mut tokenized_bond = ITokenizedBondDispatcher { contract_address: setup() };

    start_cheat_caller_address(tokenized_bond.contract_address, OWNER());

    tokenized_bond.add_minter(MINTER());

    let expected_tokenized_bond_event = TokenizedBond::Event::MinterAdded(
        TokenizedBond::MinterAdded { minter: MINTER() },
    );

    spy.assert_emitted(@array![(tokenized_bond.contract_address, expected_tokenized_bond_event)]);
}

#[test]
#[should_panic(expected: 'Caller is not the owner')]
fn test_add_minter_not_owner() {
    let mut tokenized_bond = ITokenizedBondDispatcher { contract_address: setup() };

    tokenized_bond.add_minter(MINTER());
}

#[test]
#[should_panic(expected: 'Minter already exists')]
fn test_add_minter_already_exists() {
    let mut tokenized_bond = ITokenizedBondDispatcher { contract_address: setup() };

    start_cheat_caller_address(tokenized_bond.contract_address, OWNER());

    tokenized_bond.add_minter(MINTER());
    tokenized_bond.add_minter(MINTER());
}

#[test]
#[should_panic(expected: 'Minter address cant be the zero')]
fn test_add_minter_zero_address() {
    let mut tokenized_bond = ITokenizedBondDispatcher { contract_address: setup() };

    start_cheat_caller_address(tokenized_bond.contract_address, OWNER());

    tokenized_bond.add_minter(ZERO_ADDRESS());
}

#[test]
fn test_remove_minter() {
    let mut spy = spy_events();

    let mut tokenized_bond = ITokenizedBondDispatcher { contract_address: setup() };

    start_cheat_caller_address(tokenized_bond.contract_address, OWNER());

    tokenized_bond.add_minter(MINTER());
    tokenized_bond.remove_minter(MINTER());

    let expected_tokenized_bond_event = TokenizedBond::Event::MinterRemoved(
        TokenizedBond::MinterRemoved { minter: MINTER() },
    );

    spy.assert_emitted(@array![(tokenized_bond.contract_address, expected_tokenized_bond_event)]);
}

#[test]
#[should_panic(expected: 'Caller is not the owner')]
fn test_remove_minter_not_owner() {
    let mut tokenized_bond = ITokenizedBondDispatcher { contract_address: setup() };

    start_cheat_caller_address(tokenized_bond.contract_address, MINTER());

    tokenized_bond.remove_minter(MINTER());
}

#[test]
fn test_mint_success() {
    let mut tokenized_bond = ITokenizedBondDispatcher { contract_address: setup() };
    let minter = setup_receiver();
    let erc_1155 = IERC1155Dispatcher { contract_address: tokenized_bond.contract_address };
    start_cheat_caller_address(tokenized_bond.contract_address, OWNER());

    tokenized_bond.add_minter(minter);

    start_cheat_caller_address(tokenized_bond.contract_address, minter);

    tokenized_bond
        .mint(
            TIME_IN_THE_FUTURE(),
            INTEREST_RATE(),
            TOKEN_ID(),
            MINT_AMOUNT(),
            CUSTODIAL_FALSE(),
            TOKEN_NAME(),
        );

    let minter_balance = erc_1155.balance_of(account: minter, token_id: TOKEN_ID());
    assert(minter_balance == MINT_AMOUNT(), 'Minter balance is not correct');
}

#[test]
#[should_panic(expected: 'Token already exists')]
fn test_token_already_minted() {
    let mut tokenized_bond = ITokenizedBondDispatcher { contract_address: setup() };
    let receiver = setup_receiver();
    start_cheat_caller_address(tokenized_bond.contract_address, OWNER());

    tokenized_bond.add_minter(receiver);

    start_cheat_caller_address(tokenized_bond.contract_address, receiver);

    tokenized_bond
        .mint(
            TIME_IN_THE_FUTURE(),
            INTEREST_RATE(),
            TOKEN_ID(),
            MINT_AMOUNT(),
            CUSTODIAL_FALSE(),
            TOKEN_NAME(),
        );
    tokenized_bond
        .mint(
            TIME_IN_THE_FUTURE(),
            INTEREST_RATE(),
            TOKEN_ID(),
            MINT_AMOUNT(),
            CUSTODIAL_FALSE(),
            TOKEN_NAME(),
        );
}

#[test]
#[should_panic(expected: 'Caller is not a minter')]
fn test_mint_when_caller_is_not_minter() {
    let mut tokenized_bond = ITokenizedBondDispatcher { contract_address: setup() };
    start_cheat_caller_address(tokenized_bond.contract_address, OWNER());

    start_cheat_caller_address(tokenized_bond.contract_address, MINTER());

    tokenized_bond
        .mint(
            TIME_IN_THE_FUTURE(),
            INTEREST_RATE(),
            TOKEN_ID(),
            MINT_AMOUNT(),
            CUSTODIAL_FALSE(),
            TOKEN_NAME(),
        );
}

#[test]
#[should_panic(expected: 'Expiration date is in the past')]
fn test_mint_with_expired_date() {
    let mut tokenized_bond = ITokenizedBondDispatcher { contract_address: setup() };
    start_cheat_caller_address(tokenized_bond.contract_address, OWNER());
    let time_in_the_past = get_block_timestamp();
    start_cheat_block_timestamp_global(block_timestamp: 88);
    tokenized_bond.add_minter(MINTER());

    start_cheat_caller_address(tokenized_bond.contract_address, MINTER());

    tokenized_bond
        .mint(
            time_in_the_past,
            INTEREST_RATE(),
            TOKEN_ID(),
            MINT_AMOUNT(),
            CUSTODIAL_FALSE(),
            TOKEN_NAME(),
        );

    stop_cheat_block_timestamp_global()
}

#[test]
#[should_panic(expected: 'Interest rate 0')]
fn test_mint_when_interest_rate_is_zero() {
    let mut tokenized_bond = ITokenizedBondDispatcher { contract_address: setup() };
    start_cheat_caller_address(tokenized_bond.contract_address, OWNER());

    tokenized_bond.add_minter(MINTER());

    start_cheat_caller_address(tokenized_bond.contract_address, MINTER());

    tokenized_bond
        .mint(
            TIME_IN_THE_FUTURE(),
            INTEREST_RATE_ZERO(),
            TOKEN_ID(),
            MINT_AMOUNT(),
            CUSTODIAL_FALSE(),
            TOKEN_NAME(),
        );
}

#[test]
fn test_burn_token() {
    let mut tokenized_bond = ITokenizedBondDispatcher { contract_address: setup() };
    let minter = setup_receiver();
    let erc_1155 = IERC1155Dispatcher { contract_address: tokenized_bond.contract_address };
    start_cheat_caller_address(tokenized_bond.contract_address, OWNER());

    tokenized_bond.add_minter(minter);
    start_cheat_caller_address(tokenized_bond.contract_address, minter);

    tokenized_bond
        .mint(
            TIME_IN_THE_FUTURE(),
            INTEREST_RATE(),
            TOKEN_ID(),
            MINT_AMOUNT(),
            CUSTODIAL_FALSE(),
            TOKEN_NAME(),
        );
    let pre_burn_minter_balance = erc_1155.balance_of(account: minter, token_id: TOKEN_ID());
    assert(pre_burn_minter_balance == MINT_AMOUNT(), 'pre burn balance is incorrect');
    start_cheat_caller_address(tokenized_bond.contract_address, minter);

    tokenized_bond.burn(TOKEN_ID(), MINT_AMOUNT());

    let post_burn_minter_balance = erc_1155.balance_of(account: minter, token_id: TOKEN_ID());
    assert(post_burn_minter_balance == 0, 'post burn balance is incorrect');
}

#[test]
#[should_panic(expected: 'Token does not exist')]
fn test_burn_token_that_does_not_exist() {
    let mut tokenized_bond = ITokenizedBondDispatcher { contract_address: setup() };
    start_cheat_caller_address(tokenized_bond.contract_address, OWNER());

    tokenized_bond.add_minter(MINTER());
    start_cheat_caller_address(tokenized_bond.contract_address, MINTER());

    tokenized_bond.burn(TOKEN_ID(), MINT_AMOUNT());
}

#[test]
#[should_panic(expected: 'Caller is not token minter')]
fn test_burn_with_invalid_minter() {
    let mut tokenized_bond = ITokenizedBondDispatcher { contract_address: setup() };
    let minter = setup_receiver();
    start_cheat_caller_address(tokenized_bond.contract_address, OWNER());

    tokenized_bond.add_minter(minter);
    start_cheat_caller_address(tokenized_bond.contract_address, minter);
    tokenized_bond
        .mint(
            TIME_IN_THE_FUTURE(),
            INTEREST_RATE(),
            TOKEN_ID(),
            MINT_AMOUNT(),
            CUSTODIAL_FALSE(),
            TOKEN_NAME(),
        );
    start_cheat_caller_address(tokenized_bond.contract_address, NOT_MINTER());
    tokenized_bond.burn(TOKEN_ID(), MINT_AMOUNT());
}

#[test]
#[should_panic(expected: 'Invalid burn amount')]
fn test_burn_with_too_high_amount() {
    let mut tokenized_bond = ITokenizedBondDispatcher { contract_address: setup() };
    let minter = setup_receiver();
    let erc_1155 = IERC1155Dispatcher { contract_address: tokenized_bond.contract_address };
    start_cheat_caller_address(tokenized_bond.contract_address, OWNER());

    tokenized_bond.add_minter(minter);
    start_cheat_caller_address(tokenized_bond.contract_address, minter);

    tokenized_bond
        .mint(
            TIME_IN_THE_FUTURE(),
            INTEREST_RATE(),
            TOKEN_ID(),
            MINT_AMOUNT(),
            CUSTODIAL_FALSE(),
            TOKEN_NAME(),
        );
    let pre_burn_minter_balance = erc_1155.balance_of(account: minter, token_id: TOKEN_ID());
    assert(pre_burn_minter_balance == MINT_AMOUNT(), 'pre burn balance is incorrect');
    start_cheat_caller_address(tokenized_bond.contract_address, minter);
    let too_high_amount = MINT_AMOUNT() + 1;
    tokenized_bond.burn(TOKEN_ID(), too_high_amount);
}

#[test]
fn test_replace_minter_success() {
    let mut spy = spy_events();

    let mut tokenized_bond = ITokenizedBondDispatcher { contract_address: setup() };
    let minter = setup_receiver();
    let new_minter = setup_receiver();
    let erc_1155 = IERC1155Dispatcher { contract_address: tokenized_bond.contract_address };

    start_cheat_caller_address(tokenized_bond.contract_address, OWNER());

    tokenized_bond.add_minter(minter);
    start_cheat_caller_address(tokenized_bond.contract_address, minter);

    tokenized_bond
        .mint(
            TIME_IN_THE_FUTURE(),
            INTEREST_RATE(),
            TOKEN_ID(),
            MINT_AMOUNT(),
            CUSTODIAL_FALSE(),
            TOKEN_NAME(),
        );

    start_cheat_caller_address(tokenized_bond.contract_address, OWNER());
    tokenized_bond.replace_minter(minter, new_minter);

    let expected_tokenized_bond_event = TokenizedBond::Event::MinterReplaced(
        TokenizedBond::MinterReplaced {
            token_id: TOKEN_ID(), old_minter: minter, new_minter: new_minter,
        },
    );
    let new_minter_balance = erc_1155.balance_of(account: new_minter, token_id: TOKEN_ID());
    let old_minter_balance = erc_1155.balance_of(account: minter, token_id: TOKEN_ID());

    assert(old_minter_balance == 0, 'Old minter balance incorrect');
    assert(new_minter_balance == MINT_AMOUNT(), 'New minter balance incorrect');

    start_cheat_caller_address(tokenized_bond.contract_address, new_minter);
    tokenized_bond.burn(token_id: TOKEN_ID(), amount: 1);
    let new_minter_balance_after_burn = erc_1155
        .balance_of(account: new_minter, token_id: TOKEN_ID());
    assert(new_minter_balance_after_burn == MINT_AMOUNT() - 1, 'New minter balance incorrect');
    spy.assert_emitted(@array![(tokenized_bond.contract_address, expected_tokenized_bond_event)]);
}

#[test]
#[should_panic(expected: 'Caller is not the owner')]
fn test_replace_minter_when_caller_is_not_owner() {
    let mut tokenized_bond = ITokenizedBondDispatcher { contract_address: setup() };

    stop_cheat_caller_address(tokenized_bond.contract_address);
    tokenized_bond.replace_minter(MINTER(), NEW_MINTER());
}

#[test]
#[should_panic(expected: 'Old minter does not exist')]
fn test_replace_minter_when_old_minter_does_not_exist() {
    let mut tokenized_bond = ITokenizedBondDispatcher { contract_address: setup() };
    start_cheat_caller_address(tokenized_bond.contract_address, OWNER());

    tokenized_bond.replace_minter(MINTER(), NEW_MINTER());
}

#[test]
#[should_panic(expected: 'New minter already exists')]
fn test_replace_minter_when_new_minter_already_exists() {
    let mut tokenized_bond = ITokenizedBondDispatcher { contract_address: setup() };
    let minter = setup_receiver();
    let new_minter = setup_receiver();

    start_cheat_caller_address(tokenized_bond.contract_address, OWNER());

    tokenized_bond.add_minter(minter);
    tokenized_bond.add_minter(new_minter);

    start_cheat_caller_address(tokenized_bond.contract_address, minter);

    tokenized_bond
        .mint(
            TIME_IN_THE_FUTURE(),
            INTEREST_RATE(),
            TOKEN_ID(),
            MINT_AMOUNT(),
            CUSTODIAL_FALSE(),
            TOKEN_NAME(),
        );

    start_cheat_caller_address(tokenized_bond.contract_address, OWNER());
    tokenized_bond.replace_minter(minter, new_minter);
}

#[test]
fn test_resume_inter_transfer_success() {
    let mut spy = spy_events();
    let (tokenized_bond, _minter) = setup_contract_with_minter();

    start_cheat_caller_address(tokenized_bond.contract_address, OWNER());

    tokenized_bond.pause_inter_transfer(TOKEN_ID());
    tokenized_bond.resume_inter_transfer(TOKEN_ID());

    let expected_tokenized_bond_event = TokenizedBond::Event::TokenInterTransferAllowed(
        TokenizedBond::TokenInterTransferAllowed { token_id: TOKEN_ID(), is_transferable: true },
    );

    spy.assert_emitted(@array![(tokenized_bond.contract_address, expected_tokenized_bond_event)]);
}

#[test]
fn test_pause_inter_transfer_success() {
    let mut spy = spy_events();
    let (tokenized_bond, _minter) = setup_contract_with_minter();

    start_cheat_caller_address(tokenized_bond.contract_address, OWNER());

    tokenized_bond.pause_inter_transfer(TOKEN_ID());

    let expected_tokenized_bond_event = TokenizedBond::Event::TokenInterTransferAllowed(
        TokenizedBond::TokenInterTransferAllowed { token_id: TOKEN_ID(), is_transferable: false },
    );

    spy.assert_emitted(@array![(tokenized_bond.contract_address, expected_tokenized_bond_event)]);
}

#[test]
fn test_resume_itr_after_expiry() {
    let mut spy = spy_events();
    let (tokenized_bond, _minter) = setup_contract_with_minter();

    start_cheat_caller_address(tokenized_bond.contract_address, OWNER());

    tokenized_bond.pause_itr_after_expiry(TOKEN_ID());
    tokenized_bond.resume_itr_after_expiry(TOKEN_ID());

    let expected_tokenized_bond_event = TokenizedBond::Event::TokenItrAfterExpiryAllowed(
        TokenizedBond::TokenItrAfterExpiryAllowed { token_id: TOKEN_ID(), is_transferable: true },
    );

    spy.assert_emitted(@array![(tokenized_bond.contract_address, expected_tokenized_bond_event)]);
}

#[test]
fn test_pause_itr_after_expiry() {
    let mut spy = spy_events();
    let (tokenized_bond, _minter) = setup_contract_with_minter();

    start_cheat_caller_address(tokenized_bond.contract_address, OWNER());

    tokenized_bond.pause_itr_after_expiry(TOKEN_ID());

    let expected_tokenized_bond_event = TokenizedBond::Event::TokenItrAfterExpiryAllowed(
        TokenizedBond::TokenItrAfterExpiryAllowed { token_id: TOKEN_ID(), is_transferable: false },
    );

    spy.assert_emitted(@array![(tokenized_bond.contract_address, expected_tokenized_bond_event)]);
}

fn test_freeze_token_success() {
    let mut tokenized_bond = ITokenizedBondDispatcher { contract_address: setup() };
    let minter = setup_receiver();

    start_cheat_caller_address(tokenized_bond.contract_address, OWNER());
    tokenized_bond.add_minter(minter);

    start_cheat_caller_address(tokenized_bond.contract_address, minter);
    tokenized_bond
        .mint(
            TIME_IN_THE_FUTURE(),
            INTEREST_RATE(),
            TOKEN_ID(),
            MINT_AMOUNT(),
            CUSTODIAL_FALSE(),
            TOKEN_NAME(),
        );

    start_cheat_caller_address(tokenized_bond.contract_address, OWNER());
    tokenized_bond.freeze_token(TOKEN_ID());
}

#[test]
fn test_unfreeze_token_success() {
    let mut tokenized_bond = ITokenizedBondDispatcher { contract_address: setup() };
    let minter = setup_receiver();

    start_cheat_caller_address(tokenized_bond.contract_address, OWNER());
    tokenized_bond.add_minter(minter);

    start_cheat_caller_address(tokenized_bond.contract_address, minter);
    tokenized_bond
        .mint(
            TIME_IN_THE_FUTURE(),
            INTEREST_RATE(),
            TOKEN_ID(),
            MINT_AMOUNT(),
            CUSTODIAL_FALSE(),
            TOKEN_NAME(),
        );

    start_cheat_caller_address(tokenized_bond.contract_address, OWNER());
    tokenized_bond.freeze_token(TOKEN_ID());
    tokenized_bond.unfreeze_token(TOKEN_ID());

    tokenized_bond.freeze_token(TOKEN_ID());
}


#[test]
#[should_panic(expected: 'Caller is not the owner')]
fn test_unfreeze_token_not_owner() {
    let mut tokenized_bond = ITokenizedBondDispatcher { contract_address: setup() };
    tokenized_bond.unfreeze_token(TOKEN_ID());
}

#[test]
#[should_panic(expected: 'Token does not exist')]
fn test_unfreeze_nonexistent_token() {
    let mut tokenized_bond = ITokenizedBondDispatcher { contract_address: setup() };

    start_cheat_caller_address(tokenized_bond.contract_address, OWNER());
    tokenized_bond.unfreeze_token(TOKEN_ID());
}


#[test]
#[should_panic(expected: 'Caller is not the owner')]
fn test_freeze_token_not_owner() {
    let mut tokenized_bond = ITokenizedBondDispatcher { contract_address: setup() };
    tokenized_bond.freeze_token(TOKEN_ID());
}

#[test]
#[should_panic(expected: 'Token does not exist')]
fn test_freeze_nonexistent_token() {
    let mut tokenized_bond = ITokenizedBondDispatcher { contract_address: setup() };

    start_cheat_caller_address(tokenized_bond.contract_address, OWNER());
    tokenized_bond.freeze_token(TOKEN_ID());
}

#[test]
#[should_panic(expected: 'Token is frozen')]
fn test_freeze_already_frozen_token() {
    let mut tokenized_bond = ITokenizedBondDispatcher { contract_address: setup() };
    let minter = setup_receiver();

    start_cheat_caller_address(tokenized_bond.contract_address, OWNER());
    tokenized_bond.add_minter(minter);

    start_cheat_caller_address(tokenized_bond.contract_address, minter);
    tokenized_bond
        .mint(
            TIME_IN_THE_FUTURE(),
            INTEREST_RATE(),
            TOKEN_ID(),
            MINT_AMOUNT(),
            CUSTODIAL_FALSE(),
            TOKEN_NAME(),
        );

    start_cheat_caller_address(tokenized_bond.contract_address, OWNER());
    tokenized_bond.freeze_token(TOKEN_ID());
    tokenized_bond.freeze_token(TOKEN_ID());
}

#[test]
#[should_panic(expected: 'Token is not frozen')]
fn test_unfreeze_not_frozen_token() {
    let mut tokenized_bond = ITokenizedBondDispatcher { contract_address: setup() };
    let minter = setup_receiver();

    start_cheat_caller_address(tokenized_bond.contract_address, OWNER());
    tokenized_bond.add_minter(minter);

    start_cheat_caller_address(tokenized_bond.contract_address, minter);
    tokenized_bond
        .mint(
            TIME_IN_THE_FUTURE(),
            INTEREST_RATE(),
            TOKEN_ID(),
            MINT_AMOUNT(),
            CUSTODIAL_FALSE(),
            TOKEN_NAME(),
        );

    start_cheat_caller_address(tokenized_bond.contract_address, OWNER());
    tokenized_bond.unfreeze_token(TOKEN_ID());
}

#[test]
fn test_set_minter_as_operator_success() {
    let mut spy = spy_events();
    let (tokenized_bond, minter) = setup_contract_with_minter();

    start_cheat_caller_address(tokenized_bond.contract_address, OWNER());
    tokenized_bond.set_minter_as_operator(TOKEN_ID());

    let expected_event = TokenizedBond::Event::MinterOperatorSet(
        TokenizedBond::MinterOperatorSet { token_id: TOKEN_ID(), is_operator: true },
    );
    spy.assert_emitted(@array![(tokenized_bond.contract_address, expected_event)]);

    assert(tokenized_bond.minter_is_operator(TOKEN_ID(), minter), 'Minter should be operator');
}

#[test]
#[should_panic(expected: 'Caller is not the owner')]
fn test_set_minter_as_operator_not_owner() {
    let (tokenized_bond, _minter) = setup_contract_with_minter();
    start_cheat_caller_address(tokenized_bond.contract_address, NOT_MINTER());
    tokenized_bond.set_minter_as_operator(TOKEN_ID());
}

#[test]
#[should_panic(expected: 'Token does not exist')]
fn test_set_minter_as_operator_nonexistent_token() {
    let mut tokenized_bond = ITokenizedBondDispatcher { contract_address: setup() };
    start_cheat_caller_address(tokenized_bond.contract_address, OWNER());
    tokenized_bond.set_minter_as_operator(TOKEN_ID());
}

#[test]
#[should_panic(expected: 'Minter is already operator')]
fn test_set_minter_as_operator_already_operator() {
    let (tokenized_bond, _minter) = setup_contract_with_minter();
    start_cheat_caller_address(tokenized_bond.contract_address, OWNER());
    tokenized_bond.set_minter_as_operator(TOKEN_ID());
    tokenized_bond.set_minter_as_operator(TOKEN_ID());
}

#[test]
fn test_unset_minter_as_operator_success() {
    let mut spy = spy_events();
    let (tokenized_bond, _minter) = setup_contract_with_minter();

    start_cheat_caller_address(tokenized_bond.contract_address, OWNER());
    tokenized_bond.set_minter_as_operator(TOKEN_ID());
    tokenized_bond.unset_minter_as_operator(TOKEN_ID());

    let expected_event = TokenizedBond::Event::MinterOperatorSet(
        TokenizedBond::MinterOperatorSet { token_id: TOKEN_ID(), is_operator: false },
    );
    spy.assert_emitted(@array![(tokenized_bond.contract_address, expected_event)]);

    assert(
        !tokenized_bond.minter_is_operator(TOKEN_ID(), MINTER()), 'Minter should not be operator',
    );
}

#[test]
#[should_panic(expected: 'Minter is not operator')]
fn test_unset_minter_as_operator_not_operator() {
    let (tokenized_bond, _minter) = setup_contract_with_minter();
    start_cheat_caller_address(tokenized_bond.contract_address, OWNER());
    tokenized_bond.unset_minter_as_operator(TOKEN_ID());
}

#[test]
fn test_minter_is_operator_check() {
    let (tokenized_bond, minter) = setup_contract_with_minter();
    start_cheat_caller_address(tokenized_bond.contract_address, OWNER());

    assert(!tokenized_bond.minter_is_operator(TOKEN_ID(), minter), 'Should not be operator');

    tokenized_bond.set_minter_as_operator(TOKEN_ID());
    assert(tokenized_bond.minter_is_operator(TOKEN_ID(), minter), 'Should be operator');

    assert(
        !tokenized_bond.minter_is_operator(TOKEN_ID(), NOT_MINTER()), 'Non-minter not be operator',
    );
}

#[test]
fn test_check_owner_and_operator_as_token_owner() {
    let (tokenized_bond, minter) = setup_contract_with_minter();
    let receiver1 = setup_receiver();

    let transfer_destination = array![
        TokenizedBond::TransferDestination {
            receiver: receiver1, amount: TRANSFER_AMOUNT(), token_id: TOKEN_ID(),
        },
    ];

    let transfers = array![TokenizedBond::TransferParam { from: minter, to: transfer_destination }];

    start_cheat_caller_address(tokenized_bond.contract_address, minter);
    assert(tokenized_bond.check_owner_and_operator(transfers), 'Should pass as token owner');
}

#[test]
fn test_check_owner_and_operator_as_operator() {
    let (tokenized_bond, minter) = setup_contract_with_minter();
    let receiver1 = setup_receiver();

    let transfer_destination = array![
        TokenizedBond::TransferDestination {
            receiver: receiver1, amount: TRANSFER_AMOUNT(), token_id: TOKEN_ID(),
        },
    ];

    let transfers = array![TokenizedBond::TransferParam { from: minter, to: transfer_destination }];

    start_cheat_caller_address(tokenized_bond.contract_address, OWNER());
    tokenized_bond.set_minter_as_operator(TOKEN_ID());

    start_cheat_caller_address(tokenized_bond.contract_address, minter);
    assert(tokenized_bond.check_owner_and_operator(transfers), 'Should pass as operator');
}

#[test]
fn test_check_owner_and_operator_when_caller_has_zero_balance() {
    let mut tokenized_bond = ITokenizedBondDispatcher { contract_address: setup() };
    let caller = setup_receiver();
    let receiver = setup_receiver();
    start_cheat_caller_address(tokenized_bond.contract_address, OWNER());
    tokenized_bond.add_minter(caller);

    start_cheat_caller_address(tokenized_bond.contract_address, caller);

    let zero_balance_destination = array![
        TokenizedBond::TransferDestination {
            receiver: receiver, amount: TRANSFER_AMOUNT(), token_id: TOKEN_ID(),
        },
    ];

    let zero_balance_transfers = array![
        TokenizedBond::TransferParam { from: caller, to: zero_balance_destination },
    ];

    let result = tokenized_bond.check_owner_and_operator(zero_balance_transfers);
    assert(!result, 'Return false for zero balance');
}

#[test]
fn test_check_owner_operator_when_caller_is_minter_and_operator_of_the_token_with_zero_balance() {
    let (tokenized_bond, minter) = setup_contract_with_minter();
    start_cheat_caller_address(tokenized_bond.contract_address, OWNER());
    tokenized_bond.set_minter_as_operator(TOKEN_ID());

    let transfer_destination = array![
        TokenizedBond::TransferDestination {
            receiver: OWNER(), amount: TRANSFER_AMOUNT(), token_id: TOKEN_ID(),
        },
    ];

    let transfers = array![TokenizedBond::TransferParam { from: minter, to: transfer_destination }];

    start_cheat_caller_address(tokenized_bond.contract_address, minter);
    assert(tokenized_bond.check_owner_and_operator(transfers), 'Should pass with zero balance');
}

#[test]
fn test_check_owner_operator_when_from_address_is_not_caller() {
    let (tokenized_bond, minter) = setup_contract_with_minter();

    let different_from_address = setup_receiver();
    let transfer_destination = array![
        TokenizedBond::TransferDestination {
            receiver: setup_receiver(), amount: TRANSFER_AMOUNT(), token_id: TOKEN_ID(),
        },
    ];

    let transfers = array![TokenizedBond::TransferParam { from: minter, to: transfer_destination }];

    start_cheat_caller_address(tokenized_bond.contract_address, different_from_address);
    assert(!tokenized_bond.check_owner_and_operator(transfers), 'Fail for different from address');
}

#[test]
fn test_check_owner_and_operator_when_transfers_is_an_empty_array() {
    let (tokenized_bond, _minter) = setup_contract_with_minter();
    let transfers = array![];
    assert(!tokenized_bond.check_owner_and_operator(transfers), 'Empty transfers check failed');
}

#[test]
fn test_check_owner_operator_when_destinations_is_empty_array() {
    let (tokenized_bond, minter) = setup_contract_with_minter();

    let empty_destinations = array![];
    let transfers = array![TokenizedBond::TransferParam { from: minter, to: empty_destinations }];

    start_cheat_caller_address(tokenized_bond.contract_address, minter);
    assert(!tokenized_bond.check_owner_and_operator(transfers), 'fail for empty destinations');
}

#[test]
fn test_check_owner_operator_when_caller_is_not_operator_has_balance_greater_than_zero() {
    let (tokenized_bond, minter) = setup_contract_with_minter();

    let transfer_destination = array![
        TokenizedBond::TransferDestination {
            receiver: OWNER(), amount: TRANSFER_AMOUNT(), token_id: TOKEN_ID(),
        },
    ];

    let transfers = array![TokenizedBond::TransferParam { from: minter, to: transfer_destination }];

    start_cheat_caller_address(tokenized_bond.contract_address, minter);

    assert(tokenized_bond.check_owner_and_operator(transfers), 'Should pass with balance');
}

fn test_make_transfer_success() {
    let mut spy = spy_events();
    let (tokenized_bond, minter) = setup_contract_with_minter();
    let receiver = setup_receiver();
    let transfer = setup_transfer(from: minter, to: receiver, amount: AMOUNT_TRANSFERRED());

    let expected_event = ERC1155Component::Event::TransferSingle(
        ERC1155Component::TransferSingle {
            operator: minter,
            from: minter,
            to: receiver,
            id: TOKEN_ID(),
            value: AMOUNT_TRANSFERRED(),
        },
    );

    start_cheat_caller_address(tokenized_bond.contract_address, minter);
    tokenized_bond.make_transfer(transfer);

    spy.assert_emitted(@array![(tokenized_bond.contract_address, expected_event)]);
}

#[test]
#[should_panic(expected: 'Caller is not minter or owner')]
fn test_make_transfer_when_caller_is_not_the_minter() {
    let (tokenized_bond, _minter) = setup_contract_with_minter();
    let transfers = setup_transfer(
        NOT_MINTER(), to: setup_receiver(), amount: AMOUNT_TRANSFERRED(),
    );

    start_cheat_caller_address(tokenized_bond.contract_address, NOT_MINTER());
    tokenized_bond.make_transfer(transfers);
}

#[test]
#[should_panic(expected: 'Token ITR is paused')]
fn test_make_transfer_when_token_itr_is_paused() {
    let (tokenized_bond, minter) = setup_contract_with_minter();
    let from = address_with_tokens(tokenized_bond, minter);
    let to = setup_receiver();
    let transfer = setup_transfer(from, to, AMOUNT_TRANSFERRED());

    start_cheat_caller_address(tokenized_bond.contract_address, OWNER());
    tokenized_bond.pause_inter_transfer(TOKEN_ID());

    start_cheat_caller_address(tokenized_bond.contract_address, from);
    tokenized_bond.make_transfer(transfer);
}

#[test]
#[should_panic(expected: 'Inter after expiry is paused')]
fn test_make_transfer_when_inter_transfer_after_expiry_is_paused() {
    let (tokenized_bond, minter) = setup_contract_with_minter();
    let from = address_with_tokens(tokenized_bond, minter);
    let to = setup_receiver();
    let transfer = setup_transfer(from, to, AMOUNT_TRANSFERRED());

    start_cheat_caller_address(tokenized_bond.contract_address, OWNER());
    tokenized_bond.pause_itr_after_expiry(TOKEN_ID());

    start_cheat_block_timestamp_global(TIME_IN_THE_FUTURE());
    start_cheat_caller_address(tokenized_bond.contract_address, from);
    tokenized_bond.make_transfer(transfer);
}

#[test]
#[should_panic(expected: 'From is receiver')]
fn test_make_transfer_when_from_is_receiver() {
    let (tokenized_bond, minter) = setup_contract_with_minter();
    let from = address_with_tokens(tokenized_bond, minter);
    let transfer = setup_transfer(from, from, AMOUNT_TRANSFERRED());

    start_cheat_caller_address(tokenized_bond.contract_address, from);
    tokenized_bond.make_transfer(transfer);
}

#[test]
#[should_panic(expected: 'Insufficient balance')]
fn test_make_transfer_when_balance_is_insufficent() {
    let (tokenized_bond, minter) = setup_contract_with_minter();
    let from = address_with_tokens(tokenized_bond, minter);
    let to = setup_receiver();
    let transfer = setup_transfer(from, to, AMOUNT_TRANSFERRED() + 1);

    start_cheat_caller_address(tokenized_bond.contract_address, from);
    tokenized_bond.make_transfer(transfer);
}

#[test]
fn test_upgrade_success() {
    let mut spy = spy_events();
    let (tokenized_bond, _minter) = setup_contract_with_minter();
    let upgrade_class_hash = upgrade_class_hash();
    start_cheat_caller_address(tokenized_bond.contract_address, OWNER());
    tokenized_bond.upgrade(upgrade_class_hash);

    let expected_event = UpgradeableComponent::Event::Upgraded(
        UpgradeableComponent::Upgraded { class_hash: upgrade_class_hash },
    );
    spy.assert_emitted(@array![(tokenized_bond.contract_address, expected_event)]);
}

#[test]
#[should_panic(expected: 'Caller is not the owner')]
fn test_upgrade_not_owner() {
    let (tokenized_bond, _minter) = setup_contract_with_minter();
    tokenized_bond.upgrade(class_hash_const::<'UPGRADE'>());
}

#[test]
fn test_tokenized_bond_transfer_ownership() {
    let mut spy = spy_events();
    let (tokenized_bond, _minter) = setup_contract_with_minter();
    let ownable = IOwnableTwoStepDispatcher { contract_address: tokenized_bond.contract_address };

    assert(ownable.owner() == OWNER(), 'Initial wrong owner');

    start_cheat_caller_address(tokenized_bond.contract_address, OWNER());
    ownable.transfer_ownership(NEW_OWNER());
    start_cheat_block_timestamp_global(get_block_timestamp() + 99999);

    start_cheat_caller_address(tokenized_bond.contract_address, NEW_OWNER());
    ownable.accept_ownership();

    assert(ownable.owner() == NEW_OWNER(), 'transfer owner failed');

    let expected_event = OwnableComponent::Event::OwnershipTransferred(
        OwnableComponent::OwnershipTransferred { previous_owner: OWNER(), new_owner: NEW_OWNER() },
    );
    spy.assert_emitted(@array![(ownable.contract_address, expected_event)]);
}

#[test]
#[should_panic(expected: 'Caller is not the owner')]
fn test_tokenized_bond_transfer_ownership_not_owner() {
    let (tokenized_bond, _minter) = setup_contract_with_minter();
    let ownable = IOwnableTwoStepDispatcher { contract_address: tokenized_bond.contract_address };

    ownable.transfer_ownership(NEW_OWNER());
    assert(ownable.owner() == NEW_OWNER().into(), 'transfer owner failed');
}
