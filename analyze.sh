#!/bin/bash

# analyze.sh
# Core analysis script for incident response
# Usage: ./analyze.sh -p <Protocol> -d <Date> -c <ChainID> -t <TxHash> -m <Member> [-b <Block>] [--auto]

# Default values
PROTOCOL=""
DATE=""
CHAIN_ID="1"
TX_HASH=""
MEMBER_NAME=""
BLOCK_NUMBER=""
AUTO_MODE=0

# Constants
RPC_ALIAS="mainnet"

die() { echo "Error: $1"; exit 1; }
info() { echo "Info: $1"; }
warn() { echo "Warning: $1"; }

# Parse flags
while getopts "p:d:c:t:m:b:a-:" opt; do
  case $opt in
    p) PROTOCOL="$OPTARG" ;;
    d) DATE="$OPTARG" ;;
    c) CHAIN_ID="$OPTARG" ;;
    t) TX_HASH="$OPTARG" ;;
    m) MEMBER_NAME="$OPTARG" ;;
    b) BLOCK_NUMBER="$OPTARG" ;;
    -) # Handle long options like --auto
        case "${OPTARG}" in
            auto) AUTO_MODE=1 ;;
            *) die "Unknown option --${OPTARG}" ;;
        esac ;;
    \?) die "Invalid option -$OPTARG" ;;
  esac
done

# ==========================================
# 1. Identity & Input
# ==========================================

# Resolve Member Name
if [ -z "$MEMBER_NAME" ]; then
    if [ "$AUTO_MODE" -eq "1" ]; then
        die "Member name required in Auto Mode (-m)"
    else
        GIT_USER=$(git config user.name)
        read -p "Enter your name [Default: $GIT_USER]: " INPUT_MEMBER
        MEMBER_NAME=${INPUT_MEMBER:-$GIT_USER}
    fi
fi

# Sanitize Member Name
MEMBER_NAME=${MEMBER_NAME// /_}

# Validation
[ -z "$PROTOCOL" ] && die "Protocol name is required."
[ -z "$TX_HASH" ] && die "Transaction hash is required."
[ -z "$CHAIN_ID" ] && die "Chain ID is required."

# Chain -> RPC Mapping
case $CHAIN_ID in
    1) RPC_ALIAS="mainnet"; RPC_URL="${MAINNET_RPC_URL:-https://eth.llamarpc.com}" ;;
    56) RPC_ALIAS="bsc"; RPC_URL="${BSC_RPC_URL:-https://bsc-dataseed.binance.org}" ;;
    137) RPC_ALIAS="polygon"; RPC_URL="${POLYGON_RPC_URL:-https://polygon-rpc.com}" ;;
    42161) RPC_ALIAS="arbitrum"; RPC_URL="${ARBITRUM_RPC_URL:-https://arb1.arbitrum.io/rpc}" ;;
    10) RPC_ALIAS="optimism"; RPC_URL="${OPTIMISM_RPC_URL:-https://mainnet.optimism.io}" ;;
    43114) RPC_ALIAS="avalanche"; RPC_URL="${AVALANCHE_RPC_URL:-https://api.avax.network/ext/bc/C/rpc}" ;;
    250) RPC_ALIAS="fantom"; RPC_URL="${FANTOM_RPC_URL:-https://rpc.ftm.tools}" ;;
    8453) RPC_ALIAS="base"; RPC_URL="${BASE_RPC_URL:-https://mainnet.base.org}" ;;
    *) warn "Unknown Chain ID $CHAIN_ID. Defaulting to Mainnet."; RPC_ALIAS="mainnet"; RPC_URL="${MAINNET_RPC_URL:-https://eth.llamarpc.com}" ;;
esac

# ==========================================
# 2. Automated RPC Extraction
# ==========================================

info "Fetching transaction data from $RPC_ALIAS..."

# Use cast to fetch transaction details
TX_JSON=$(cast tx "$TX_HASH" --rpc-url "$RPC_URL" --json 2>/dev/null)

if [ -z "$TX_JSON" ] || [ "$TX_JSON" == "null" ]; then
    if [ "$AUTO_MODE" -eq "1" ]; then
        if [ -n "$BLOCK_NUMBER" ]; then
             warn "Transaction not found via Cast, but Block Number provided. Proceeding with limited data."
             ATTACKER="0x0000000000000000000000000000000000000000"
             TARGET="0x0000000000000000000000000000000000000000"
             INPUT_DATA=""
             BLOCK_NUMBER_DEC="$BLOCK_NUMBER"
        else
             die "Transaction $TX_HASH not found on chain $CHAIN_ID and no Block Number provided."
        fi
    else
        warn "Could not fetch Tx. Using manual/default values."
        BLOCK_NUMBER_DEC="0"
        ATTACKER="0x0000000000000000000000000000000000000000"
        TARGET="0x0000000000000000000000000000000000000000"
        INPUT_DATA=""
    fi
else
    get_json_val() {
        echo "$TX_JSON" | grep -o "\"$1\": *\"[^\"]*\"" | cut -d'"' -f4
    }

    BLOCK_NUMBER_HEX=$(get_json_val "blockNumber")
    FROM_ADDR=$(get_json_val "from")
    TO_ADDR=$(get_json_val "to")
    INPUT_DATA=$(get_json_val "input")

    if [ -n "$BLOCK_NUMBER" ]; then
        BLOCK_NUMBER_DEC="$BLOCK_NUMBER"
        info "Block: $BLOCK_NUMBER_DEC (Using provided value)"
    else
        BLOCK_NUMBER_DEC=$(cast --to-dec "$BLOCK_NUMBER_HEX")
        info "Block: $BLOCK_NUMBER_DEC (Fetched from Tx)"
    fi
    
    FORK_BLOCK=$((BLOCK_NUMBER_DEC - 1))
    
    ATTACKER=$FROM_ADDR
    TARGET=$TO_ADDR
    
    info "Attacker: $ATTACKER"
    info "Target: $TARGET"
fi

if [ -z "$FORK_BLOCK" ]; then
    FORK_BLOCK=$((BLOCK_NUMBER_DEC - 1))
fi

# ==========================================
# 3. Workspace & Branch Management
# ==========================================

DIR_NAME="${DATE}_${PROTOCOL}"
TARGET_DIR="test/$DIR_NAME"
BRANCH_NAME="incident/$DIR_NAME"

if [ "$AUTO_MODE" -eq "1" ]; then
    echo "TARGET_BRANCH=$BRANCH_NAME" >> $GITHUB_ENV
fi

info "Workspace: $TARGET_DIR"
info "Branch:    $BRANCH_NAME"

if [ "$AUTO_MODE" -eq "0" ]; then
    git fetch origin > /dev/null 2>&1
    if git ls-remote --heads origin "$BRANCH_NAME" | grep -q "$BRANCH_NAME"; then
        info "Joining existing incident..."
        git checkout "$BRANCH_NAME" || git checkout -b "$BRANCH_NAME" "origin/$BRANCH_NAME"
        git pull origin "$BRANCH_NAME"
    else
        info "Initializing new incident..."
        if [ "$(git branch --show-current)" != "$BRANCH_NAME" ]; then
            git checkout -b "$BRANCH_NAME"
        fi
    fi
else
    git fetch origin
    if git ls-remote --heads origin "$BRANCH_NAME" | grep -q "$BRANCH_NAME"; then
        git checkout "$BRANCH_NAME"
        git pull origin "$BRANCH_NAME"
    else
        git checkout -b "$BRANCH_NAME"
    fi
fi

mkdir -p "$TARGET_DIR"

# ==========================================
# 4. Template Generation
# ==========================================

BASE_PATH="$TARGET_DIR/${PROTOCOL}Base.sol"
REPLAY_PATH="$TARGET_DIR/Replay.t.sol"
README_PATH="$TARGET_DIR/README.md"
POC_PATH="$TARGET_DIR/PoC_${MEMBER_NAME}.t.sol"

# A. Base Contract
if [ ! -f "$BASE_PATH" ]; then
    cat <<EOF > "$BASE_PATH"
// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.10;

import "src/shared/BaseTest.sol";
import "src/shared/interfaces.sol";

/*
@Analysis-Start
@Protocol: $PROTOCOL
@Date: $DATE
@Lost: 
@Attacker: $ATTACKER
@Target: $TARGET
@TxHash: $TX_HASH
@ChainId: $CHAIN_ID
@Analysis-End
*/

abstract contract ${PROTOCOL}Base is BaseTest {
    function setUp() public virtual {
        // Chain ID: $CHAIN_ID
        // Block: $BLOCK_NUMBER_DEC
        vm.createSelectFork("$RPC_ALIAS", $FORK_BLOCK); 
        
        // Auto-Config
        target = $TARGET;
        // fundingToken = address(USDC);
    }
}
EOF
    info "Created Base"
fi

# B. Replay Test
if [ ! -f "$REPLAY_PATH" ]; then
    cat <<EOF > "$REPLAY_PATH"
// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.10;

import "./${PROTOCOL}Base.sol";

contract ReplayTest is ${PROTOCOL}Base {
    function setUp() public override {
        super.setUp();
    }

    function testReplay() public recordMetrics("REPLAY") {
        // 1. Set Beneficiary to Attacker for correct profit calc
        beneficiary = $ATTACKER;
        
        // 2. Impersonate Attacker
        vm.startPrank($ATTACKER);
        
        // 3. Replay Transaction (Auto-filled)
        address attackContract = $TARGET;
        (bool success, ) = attackContract.call(hex"${INPUT_DATA#0x}");
        require(success, "Replay failed");
        
        vm.stopPrank();
    }
}
EOF
    info "Created Replay"
fi

# C. README
if [ ! -f "$README_PATH" ]; then
    cat <<EOF > "$README_PATH"
# $PROTOCOL Incident Analysis

## 1. Incident Summary
- **Date:** $DATE
- **Chain ID:** $CHAIN_ID
- **Tx Hash:** \`$TX_HASH\`
- **Attacker:** \`$ATTACKER\`
- **Target:** \`$TARGET\`

## 2. Status
- [x] Initialized by $MEMBER_NAME
EOF
    info "Created README"
fi

# D. Personal PoC
if [ ! -f "$POC_PATH" ]; then
    cat <<EOF > "$POC_PATH"
// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.10;

import "./${PROTOCOL}Base.sol";

contract PoC_${MEMBER_NAME} is ${PROTOCOL}Base {
    function setUp() public override {
        super.setUp();
    }

    // Deep Dive Analysis
    function testExploit() public recordMetrics("PoC_${MEMBER_NAME}") {
        // vm.startPrank(attacker);
        // Implement logic here...
        // vm.stopPrank();
    }
}
EOF
    info "Created PoC"
fi

# ==========================================
# 5. Finalize
# ==========================================

if [ "$AUTO_MODE" -eq "0" ]; then
    info "Done! Run 'git push' to share your workspace."
fi
