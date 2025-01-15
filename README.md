# Tokenized Bond Smart Contract

Ejara smart contract implementation for tokenized bonds using the ERC-1155 standard, built with Cairo 1.0.

## Overview

Ejara tokenized bonds aim to fractionalize bonds into the smallest units for enhanced accessibility. The smart contract provides a secure and efficient way to manage tokenized bonds on StarkNet.

## Features

### ERC-1155 Multi-Token Standard
- Multiple token types in a single contract
- Batch operations support
- `Span<felt252>` data argument for transfers
- `IERC1155Receiver` compliance requirements
- Interface ID validation

### ERC-1155 Compatibility in Cairo
Although Starknet is not EVM compatible, this implementation aims to be as close as possible to the ERC1155 standard but some differences can still be found, such as:
- The optional `data` argument in both `safe_transfer_from` and `safe_batch_transfer_from` is implemented as `Span<felt252>`.
- `IERC1155Receiver` compliant contracts must implement `SRC5` and register the `IERC1155Receiver` interface ID.
- `IERC1155Receiver::on_erc1155_received` must return that interface ID on success.

### Access Control & Security
- **Owner-based administration**
  - Minter management
  - Pause/unpause control
  - URI and upgrade management
- **Multi-minter system**
  - Dynamic minter addition/removal
  - Zero-address validation
- **Pausable operations**
  - Emergency pause mechanism
  - Owner-restricted controls
- **Upgradeable architecture**
  - Bug fixes and feature additions
  - Owner-controlled upgrades

### Token Operations
- **Minting**
  - Single and batch minting
  - Authorized minter restrictions
- **URI Management**
  - Configurable base URI
  - snake_case and camelCase support
- **Event System**
  - Minter management events
  - Token operation tracking
  - Administrative action logging

## Technical Stack

### Requirements
- Cairo 1.0
- Scarb package manager

### Components
Built with OpenZeppelin components:
- ERC1155 implementation
- Ownable access control
- Pausable functionality
- SRC5 introspection
- Upgradeable pattern

## Implementation

### Storage Architecture
- `is_contract_paused`: Global pause state
- `token_metadata`: Token ID to metadata mapping
- `minter_tokens_metadata`: Minter token tracking
- `minter_exist`: Minter registry

### Core Functions

1. **Contract Management**
- `pause()`: Halt operations
- `resume()`: Resume operations

2. **Token Operations**
- `mint(account, token_id, value, data)`: Token creation
- `burn(account, token_id, value)`: Token destruction

3. **Transfer Controls**
- `resume_inter_transfer(uint token_id)`: Enable transfers
- `pause_inter_transfer(uint token_id)`: Disable transfers

4. **Minter Administration**
- `add_minter(address minter)`: Register minter
- `remove_minter(address minter)`: Deregister minter
- `replace_minter(address old_minter, address new_minter)`: Update minter

## Development

### Setup

1. **Clone the repo**
    ```
    git clone https://github.com/keep-starknet-strange/tokenized-bond.git
    ```
2. **Install dependencies**
    ```
    cd tokenized-bond
    scarb build
    ```
3. **Run tests**
    ```
    scarb test
    ```
# Test Cases (need zack help)

[PASS] tokenized_bond_tests::test_mint_success (gas: ~1065) 
[PASS] tokenized_bond_tests::test_burn_with_invalid_minter (gas: ~1070)
[PASS] tokenized_bond_tests::test_remove_minter_not_owner (gas: ~427)
[PASS] tokenized_bond_tests::test_mint_when_interest_rate_is_zero (gas: ~501)
[PASS] tokenized_bond_tests::test_mint_with_expired_date (gas: ~502)
[PASS] tokenized_bond_tests::test_add_minter_zero_address (gas: ~427)
[PASS] tokenized_bond_tests::test_burn_token_that_does_not_exist (gas: ~499)
[PASS] tokenized_bond_tests::test_remove_minter (gas: ~436)
[PASS] tokenized_bond_tests::test_add_minter_not_owner (gas: ~427)
[PASS] tokenized_bond_tests::test_token_already_minted (gas: ~1066)
[PASS] tokenized_bond_tests::test_add_minter_already_exists (gas: ~496)
[PASS] tokenized_bond_tests::test_mint_when_caller_is_not_minter (gas: ~432)
[PASS] tokenized_bond_tests::test_add_minter (gas: ~496)
[PASS] tokenized_bond_tests::test_burn_token (gas: ~1017)


# Deployment on Starknet Sepolia (need zack help)