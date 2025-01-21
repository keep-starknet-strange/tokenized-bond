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
EXPIRATION_DATE=$(date -v +1m +"%s") # core::integer::u64
INTEREST_RATE=5 # core::integer::u32 (example: 5.00% interest rate)
TOKEN_ID=${1: "0x2b 0x00"} # core::integer::u256
AMOUNT="0x57d27e23acbdcfe68000000000000000 0x026e4d30eccc3215dd8f31" # core::integer::u256
CUSTODIAL=0x1 # core::bool
NAME="0x0 0x6689648321346829542552480214628 0x13" # core::byte_array::ByteArray

MINT_CALL_DATA=$(echo -n $EXPIRATION_DATE $INTEREST_RATE $TOKEN_ID $AMOUNT $CUSTODIAL $NAME)

ADD_MINTER_OUTPUT=$(starkli invoke $TOKENIZED_BOND_ADDRESS mint $MINT_CALL_DATA  --account $ACCOUNT_FILE --private-key $ACCOUNT_PRIVATE_KEY --network sepolia --rpc $RPC_URL)
echo $ADD_MINTER_OUTPUT