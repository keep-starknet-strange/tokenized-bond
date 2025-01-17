#!/bin/bash
# Abort the script on any error
set -euo pipefail

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"
echo $SCRIPT_DIR
PROJECT_ROOT=$SCRIPT_DIR/..

# Ensure tmp directory exists
mkdir -p $PROJECT_ROOT/target/tmp

# Check for required commands
command -v starkli >/dev/null 2>&1 || { echo >&2 "starkli not found. Aborting."; exit 1; }
command -v scarb >/dev/null 2>&1 || { echo >&2 "scarb not found. Aborting."; exit 1; }

# Configurable environment variables
source $PROJECT_ROOT/.env
: "${RPC_URL:=https://starknet-sepolia.public.blastapi.io/rpc/v0_7}"
: "${ACCOUNT_PRIVATE_KEY:=ACCOUNT_PRIVATE_KEY is not set}"
: "${ACCOUNT_ADDRESS:?ACCOUNT_ADDRESS is not set}"
: "${URI:?URI is not set}"
TOKENIZED_BOND_SIERRA_FILE=$PROJECT_ROOT/target/dev/tokenized_bond_TokenizedBond.contract_class.json
ACCOUNT_FILE=$PROJECT_ROOT/target/tmp/starknet_accounts.json

starkli account fetch $ACCOUNT_ADDRESS \
      --rpc $RPC_URL \
      --network sepolia --force \
      --output $ACCOUNT_FILE \

echo "starkli account fetch $ACCOUNT_ADDRESS \
      --rpc $RPC_URL \
      --network sepolia --force \
      --output $ACCOUNT_FILE \
"

# Build the contract
echo "Building the contract..."
cd $PROJECT_ROOT && scarb build

# Declaring the contract
echo "Declaring the contract..."
echo "$ACCOUNT_FILE"
# Fetch account data and save it to a file
TOKENIZED_BOND_DECLARE_OUTPUT=$(starkli declare --private-key $ACCOUNT_PRIVATE_KEY --watch $TOKENIZED_BOND_SIERRA_FILE --rpc $RPC_URL --account $ACCOUNT_FILE)
echo "starkli declare --private-key $ACCOUNT_PRIVATE_KEY --watch $TOKENIZED_BOND_SIERRA_FILE --rpc $RPC_URL --account $ACCOUNT_FILE"
TOKENIZED_BOND_CONTRACT_CLASSHASH=$(echo $TOKENIZED_BOND_DECLARE_OUTPUT)
echo "Contract class hash: $TOKENIZED_BOND_CONTRACT_CLASSHASH"

# Deploying the contract
echo "Deploying the contract..."

# Deploy the contract
CALLDATA=$(echo -n $OWNER_ADDRESS $URI)

# VVVVV maybe use this VVVV
# CALLDATA=$(echo -n $URI | xxd -r -p | base64)

echo "starkli deploy --rpc $RPC_URL --network sepolia --private-key $ACCOUNT_PRIVATE_KEY --fee-token STRK --account $ACCOUNT_FILE $TOKENIZED_BOND_CONTRACT_CLASSHASH $CALLDATA"

TOKENIZED_BOND_DEPLOY_OUTPUT=$(starkli deploy --rpc $RPC_URL --network sepolia --private-key $ACCOUNT_PRIVATE_KEY --fee-token STRK --account $ACCOUNT_FILE $TOKENIZED_BOND_CONTRACT_CLASSHASH $CALLDATA)
echo $TOKENIZED_BOND_DEPLOY_OUTPUT

# Extract the contract address using grep
TOKENIZED_BOND_CONTRACT_ADDRESS=$(echo "$TOKENIZED_BOND_DEPLOY_OUTPUT" | grep -oE '0x[0-9a-fA-F]{64}')

echo "Tokenized Bond contract address: $TOKENIZED_BOND_CONTRACT_ADDRESS"
if [ -z "$TOKENIZED_BOND_CONTRACT_ADDRESS" ]; then
  echo "Error: Failed to retrieve Tokenized Bond contract address."
  exit 1
fi
