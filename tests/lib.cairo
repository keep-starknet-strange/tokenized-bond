mod utils;
use tokenized_bond::{TokenizedBond, ITokenizedBondDispatcher, ITokenizedBondDispatcherTrait};
use openzeppelin_token::erc1155::interface::{IERC1155Dispatcher, IERC1155DispatcherTrait};
use tokenized_bond::utils::constants::{
    OWNER, MINTER, ZERO_ADDRESS, INTEREST_RATE, INTEREST_RATE_ZERO, MINT_AMOUNT, TOKEN_NAME,
    TOKEN_ID, TIME_IN_THE_FUTURE, CUSTODIAL_FALSE, NOT_MINTER, NEW_MINTER, TRANSFER_AMOUNT,
};
use snforge_std::{
    EventSpyAssertionsTrait, spy_events, start_cheat_caller_address, stop_cheat_caller_address,
    start_cheat_block_timestamp_global, stop_cheat_block_timestamp_global,
};
use starknet::get_block_timestamp;
use utils::{setup, setup_receiver, setup_contract_with_minter};

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
}

#[test]
#[should_panic(expected: 'Caller is not the owner')]
fn test_freeze_token_not_owner() {
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
fn test_check_owner_and_operator_success() {
    let (tokenized_bond, minter) = setup_contract_with_minter();
    start_cheat_caller_address(tokenized_bond.contract_address, minter);

    let transfer_destination = array![
        TokenizedBond::TransferDestination {
            receiver: OWNER(), amount: TRANSFER_AMOUNT(), token_id: TOKEN_ID(),
        },
    ];

    let transfers = array![TokenizedBond::TransferParam { from: minter, to: transfer_destination }];

    assert(tokenized_bond.check_owner_and_operator(transfers.clone()), 'Owner check should pass');
    start_cheat_caller_address(tokenized_bond.contract_address, OWNER());
    tokenized_bond.set_minter_as_operator(TOKEN_ID());

    start_cheat_caller_address(tokenized_bond.contract_address, minter);
    assert(
        tokenized_bond.check_owner_and_operator(transfers.clone()), 'Operator check should pass',
    );
}

#[test]
fn test_check_owner_and_operator_multiple_destinations() {
    let (tokenized_bond, minter) = setup_contract_with_minter();
    let receiver1 = setup_receiver();
    let receiver2 = setup_receiver();

    let multiple_destinations = array![
        TokenizedBond::TransferDestination {
            receiver: receiver1, amount: TRANSFER_AMOUNT(), token_id: TOKEN_ID(),
        },
        TokenizedBond::TransferDestination {
            receiver: receiver2, amount: TRANSFER_AMOUNT(), token_id: TOKEN_ID(),
        },
    ];

    let transfer_with_multiple_destinations = array![
        TokenizedBond::TransferParam { from: minter, to: multiple_destinations },
    ];

    start_cheat_caller_address(tokenized_bond.contract_address, minter);
    assert(
        tokenized_bond.check_owner_and_operator(transfer_with_multiple_destinations),
        'Failed for multiple destination',
    );
}

#[test]
fn test_check_owner_and_operator_empty_transfers() {
    let (tokenized_bond, _minter) = setup_contract_with_minter();
    let transfers = array![];
    start_cheat_caller_address(tokenized_bond.contract_address, NOT_MINTER());
    assert(!tokenized_bond.check_owner_and_operator(transfers), 'Empty transfers check failed');
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
fn test_check_owner_and_operator_zero_balance() {
    let mut tokenized_bond = ITokenizedBondDispatcher { contract_address: setup() };
    let minter = setup_receiver();
    let receiver1 = setup_receiver();
    start_cheat_caller_address(tokenized_bond.contract_address, OWNER());
    tokenized_bond.add_minter(minter);

    start_cheat_caller_address(tokenized_bond.contract_address, minter);

    let zero_balance_destination = array![
        TokenizedBond::TransferDestination {
            receiver: receiver1, amount: TRANSFER_AMOUNT(), token_id: TOKEN_ID(),
        },
    ];

    let zero_balance_transfers = array![
        TokenizedBond::TransferParam { from: minter, to: zero_balance_destination },
    ];

    let result = tokenized_bond.check_owner_and_operator(zero_balance_transfers);
    assert(!result, 'Return false for zero balance');
}

#[test]
fn test_check_owner_and_operator_multiple_transfers_when_caller_has_balance() {
    let (tokenized_bond, minter) = setup_contract_with_minter();
    let receiver1 = setup_receiver();
    let receiver2 = setup_receiver();

    let transfers = array![
        TokenizedBond::TransferParam {
            from: minter,
            to: array![
                TokenizedBond::TransferDestination {
                    receiver: receiver1, amount: TRANSFER_AMOUNT(), token_id: TOKEN_ID(),
                },
            ],
        },
        TokenizedBond::TransferParam {
            from: minter,
            to: array![
                TokenizedBond::TransferDestination {
                    receiver: receiver2, amount: TRANSFER_AMOUNT(), token_id: TOKEN_ID(),
                },
            ],
        },
    ];

    start_cheat_caller_address(tokenized_bond.contract_address, minter);
    assert(tokenized_bond.check_owner_and_operator(transfers), 'Invalid multiple transfer');
}

#[test]
fn test_check_owner_and_operator_multiple_transfers_when_caller_is_minter_operator() {
    let (tokenized_bond, minter) = setup_contract_with_minter();
    let receiver1 = setup_receiver();
    let receiver2 = setup_receiver();

    let transfers = array![
        TokenizedBond::TransferParam {
            from: minter,
            to: array![
                TokenizedBond::TransferDestination {
                    receiver: receiver1, amount: TRANSFER_AMOUNT(), token_id: TOKEN_ID(),
                },
            ],
        },
        TokenizedBond::TransferParam {
            from: minter,
            to: array![
                TokenizedBond::TransferDestination {
                    receiver: receiver2, amount: TRANSFER_AMOUNT(), token_id: TOKEN_ID(),
                },
            ],
        },
    ];

    start_cheat_caller_address(tokenized_bond.contract_address, OWNER());
    tokenized_bond.set_minter_as_operator(TOKEN_ID());

    start_cheat_caller_address(tokenized_bond.contract_address, minter);
    assert(tokenized_bond.check_owner_and_operator(transfers), 'Invalid operator transfer');
}

#[test]
fn test_check_owner_and_operator_denies_multiple_transfers_zero_balance_or_operator_rights() {
    let (tokenized_bond, minter) = setup_contract_with_minter();
    let receiver1 = setup_receiver();
    let receiver2 = setup_receiver();

    let transfers = array![
        TokenizedBond::TransferParam {
            from: minter,
            to: array![
                TokenizedBond::TransferDestination {
                    receiver: receiver1, amount: TRANSFER_AMOUNT(), token_id: TOKEN_ID(),
                },
            ],
        },
        TokenizedBond::TransferParam {
            from: minter,
            to: array![
                TokenizedBond::TransferDestination {
                    receiver: receiver2, amount: TRANSFER_AMOUNT(), token_id: TOKEN_ID(),
                },
            ],
        },
    ];

    start_cheat_caller_address(tokenized_bond.contract_address, NOT_MINTER());
    assert(!tokenized_bond.check_owner_and_operator(transfers), 'Invalid non-operator transfer');
}
