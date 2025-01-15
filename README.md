# Tokenized Bond Smart Contract

Ejara smart contract implementation for tokenized bonds using the ERC-1155 standard, built with Cairo 1.0.

## Overview

Ejara tokenized bonds aim to fractionalize bonds into the smallest units for enhanced accessibility. The smart contract provides a secure and efficient way to manage tokenized bonds on StarkNet.

## Features

### ERC-1155 Multi-Token Standard
- Multiple token types in a single contract
- Batch operations support
- `Span<felt252>` data argument for transfers
- Interface ID validation

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

#### Setting up Scarb

1. **Install asdf**
    ```
    brew install asdf
    ```
    Link: https://asdf-vm.com/guide/getting-started.html


2. **Verify that asdf is installed**
    ```
    asdf --version
    ```

3. **Install the asdf Scarb plugin**
    ```
    asdf plugin add scarb
    ```

4. **Install the latest version of Scarb**
    ```
    asdf install scarb 2.9.2
    ```

5. **Set a global version for Scarb (need for using scarb init)**
    ```
    asdf global scarb 2.9.2
    ```

6. **Restart the terminal and verify that Scarb is installed correctly**
    ```
    scarb --version
    ```

## Clone this repo
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


# Deployment on Starknet Sepolia (need zack help)

1. Set environment variables in .env file

2. Use Starkli to deploy the contract

3. In scripts folder, run the bash script to deploy the contract