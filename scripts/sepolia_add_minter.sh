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


# Configurable environment variables
source $PROJECT_ROOT/.env
: "${RPC_URL:=https://starknet-sepolia.public.blastapi.io/rpc/v0_7}"
: "${ACCOUNT_PRIVATE_KEY:=ACCOUNT_PRIVATE_KEY is not set}"
: "${ACCOUNT_ADDRESS:?ACCOUNT_ADDRESS is not set}"
: "${MINTER_ADDRESS:?MINTER_ADDRESS is not set}"
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

ADD_MINTER_OUTPUT=$(starkli invoke $TOKENIZED_BOND_ADDRESS add_minter $MINTER_ADDRESS  --account $ACCOUNT_FILE --private-key $ACCOUNT_PRIVATE_KEY --network sepolia --rpc $RPC_URL)
echo $ADD_MINTER_OUTPUT