# Tokenized Bond Smart Contract

Ejara smart contract implementation for tokenized bonds using the ERC-1155 standard, built with Cairo 1.0.

## Overview

Ejara tokenized bonds aim to fractionalize bonds into the smallest units for enhanced accessibility. This smart contract provides a secure and efficient way to manage tokenized bonds on StarkNet.

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

# Technical Limitations
**Storage Vector Clearing**
The contract uses a storage mapping of vectors (`Map<ContractAddress, Vec<u256>>`) to track minter tokens:

#### Important Note:
In Cairo, there is currently no way to completely clear or remove a Vec within a Map in storage. This affects the `replace_minter` function in the following ways:
  1. When a minter is replaced, their old token vector remains in storage
  2. This is not a security concern because:
      - The old minter's status is set to 0 (`self.minters.entry(old_minter).write(0)`)
      - All access to minter functions requires the minter status to be 1
      - The tokens themselves are properly transferred to the new minter

#### Storage Optimization
While the old vectors remain in storage, this doesn't affect the contract's functionality. However, it does mean that over time, "orphaned" vectors might be in storage. This is an accepted limitation of the current Cairo storage model.

# Development

### Setup

#### Setting up Scarb
 - [Install Scarb](https://docs.swmansion.com/scarb/download)

 - [Install Starknet Foundry](https://github.com/foundry-rs/starknet-foundry)

 - [Install starkli](https://github.com/xJonathanLEI/starkli)

 Using `asdf`, `scarb 2.9.2` and `starknet-foundry 0.33.0`  will be set for you

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

# Deployment on Starknet Sepolia

1. Set environment variables in .env.example file

2. Run the bash script to deploy the contract
```
scripts/sepolia_deploy.sh
```

# Call Functions on Deployed Contract

```
 scripts/sepolia_add_minter.sh  
```
```
# update token_id in the script, a value can only be used once
 scripts/sepolia_mint.sh
 ```
