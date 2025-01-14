# Introduction

Ejara tokenized bonds aim to fractionalize bonds into the smallest units for enhanced accessibility. 

### Key features (work on this):

- Scalability for managing high transaction volumes. // way to basic
- Secure contract management leveraging cairo. // way to basic

- 

# Codebase
The smart contract is implemented using Cairo 1.0 and relies on StarkNet's architecture.

Github repo: https://github.com/keep-starknet-strange/tokenized-bond


## Codebase Setup

1. Clone the repo
    ```
    git clone https://github.com/keep-starknet-strange/tokenized-bond.git
    ```
2. Install dependencies
    ```
    cd tokenized-bond
    scarb build
    ```
3. Run tests
    ```
    scarb test
    ```

## Structure

#### Storage Variables
- `is_contract_paused`: Global pause state.
- `token_metadata`: Maps token IDs to metadata (e.g., expiration, interest rate, etc.).
- `minter_tokens_metadata`: Tracks tokens minted by each minter.
- `minter_exist`: Tracks registered minters.

#### Key Functions

1. Pause/Resume Contract:

- `pause()`: Halts all contract operations.
- `resume()`: Resumes operations.

2. Minting and Burning:

- `mint(account, token_id, value, data)`: Creates new tokens with specified attributes.
- `burn(account, token_id, value)`: Destroys tokens.

3. Inter-Transfer Management:
- `resume_inter_transfer(uint token_id)`: Allows inter-token transfers.
- `pause_inter_transfer(uint token_id)`: Disables inter-token transfers.

4. Minter Management:
- `add_minter(address minter)`: Adds a new minter.
- `remove_minter(address minter)`: Removes an existing minter.
- `replace_minter(address old_minter, address new_minter)`: Replaces an old minter with a new one.

# Explanation (Why and now on cairo and starknet?) (work on this)

1. Scalability: StarkNet, as a Layer 2 solution, provides high throughput, essential for managing a large number of fractional bond tokens.
2. Security: Cairo 1.0's strong typing and formal verification capabilities enhance the security of smart contracts, crucial for financial instruments like bonds.
3. Interoperability: StarkNet's compatibility with Ethereum and other blockchain ecosystems allows for seamless integration with existing DeFi protocols and traditional financial systems.
4. Cost-efficiency: By leveraging StarkNet's Layer 2 technology, Ejara can offer lower transaction fees to users, making micro-investments in bonds more economically viable (https://l2fees.info/).
5. Programmability: Cairo 1.0's advanced features allow for the implementation of complex bond logic, including automated interest payments and maturity handling.
6. Future-proofing: As Cairo and StarkNet continue to evolve, Ejara's tokenized bonds can benefit from ongoing improvements in the ecosystem, ensuring long-term viability and adaptability

Note: Can we mention defi spring campaign to the eraja team as we can help them achieve better yeilds or partnerships 

# Test Cases (need zack help)

# Deployment on Starknet Sepolia (need zack help)

