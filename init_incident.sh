#!/bin/bash

# init_incident.sh
# Purpose: Initialize a new Incident Workspace with detailed metadata
# Usage: ./init_incident.sh -p <Protocol> -d <Date> -c <ChainID> -t <TxHash>

# Default values
PROTOCOL=""
DATE=""
CHAIN_ID="1"
TX_HASH=""

# Parse flags
while getopts "p:d:c:t:" opt; do
  case $opt in
    p) PROTOCOL="$OPTARG" ;;
    d) DATE="$OPTARG" ;;
    c) CHAIN_ID="$OPTARG" ;;
    t) TX_HASH="$OPTARG" ;;
    \?) echo "Invalid option -$OPTARG" >&2; exit 1 ;;
  esac
done

# Interactive mode if arguments are missing
if [ -z "$PROTOCOL" ]; then
    echo "--- Incident Setup Wizard ---"
    read -p "1. Protocol Name (e.g., Seneca): " PROTOCOL
fi

if [ -z "$DATE" ]; then
    DEFAULT_DATE=$(date +%Y-%m-%d)
    read -p "2. Incident Date (YYYY-MM-DD) [Default: $DEFAULT_DATE]: " INPUT_DATE
    DATE=${INPUT_DATE:-$DEFAULT_DATE}
fi

if [ -z "$TX_HASH" ]; then
    read -p "3. Transaction Hash (e.g., 0x123...): " TX_HASH
fi

if [ -z "$CHAIN_ID" ] || [ "$CHAIN_ID" == "1" ]; then
    read -p "4. Chain ID (e.g., 1 for Eth, 56 for BSC) [Default: 1]: " INPUT_CHAIN
    CHAIN_ID=${INPUT_CHAIN:-1}
fi

# Define Directory Name: YYYY-MM-DD_Protocol (Collision resistant)
DIR_NAME="${DATE}_${PROTOCOL}"
TARGET_DIR="test/$DIR_NAME"

if [ -d "$TARGET_DIR" ]; then
    echo "❌ Error: Directory $TARGET_DIR already exists."
    exit 1
fi

echo ""
echo "[*] Creating Workspace: $TARGET_DIR"
mkdir -p "$TARGET_DIR"

# 1. Create Common Base Contract
BASE_PATH="$TARGET_DIR/${PROTOCOL}Base.sol"
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
@Attacker: 
@Target: 
@TxHash: $TX_HASH
@ChainId: $CHAIN_ID
@Analysis-End
*/

abstract contract ${PROTOCOL}Base is BaseTest {
    // Shared Setup for all team members
    function setUp() public virtual {
        // 1. Fork Environment (Leader sets this)
        // ChainId: $CHAIN_ID
        // vm.createSelectFork("mainnet", BLOCK_NUMBER); 
        
        // 2. Mining Config
        // target = address(0x...);
        // fundingToken = address(USDC);
        
        // 3. Labels
        // vm.label(address(USDC), "USDC");
    }
}
EOF
echo "[+] Created Shared Base: $BASE_PATH"

# 2. Create Replay Test (Ground Truth)
REPLAY_PATH="$TARGET_DIR/Replay.t.sol"
cat <<EOF > "$REPLAY_PATH"
// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.10;

import "./${PROTOCOL}Base.sol";

contract ReplayTest is ${PROTOCOL}Base {
    function setUp() public override {
        super.setUp();
        // Additional setup if needed
    }

    function testReplay() public recordMetrics("REPLAY") {
        // beneficiary = attacker; // Update profit beneficiary
        // vm.startPrank(attacker);
        
        // 1. Replay Transaction
        // TxHash: $TX_HASH
        // (bool success, ) = attackContract.call(hex"...");
        // require(success, "Replay failed");
        
        // vm.stopPrank();
    }
}
EOF
echo "[+] Created Replay Template: $REPLAY_PATH"

# 3. Create README for Labeling
README_PATH="$TARGET_DIR/README.md"
cat <<EOF > "$README_PATH"
# $PROTOCOL Incident Analysis

## 1. Incident Summary
- **Date:** $DATE
- **Chain ID:** $CHAIN_ID
- **Tx Hash:** \`$TX_HASH\`
- **Attacker:** \`0x...\`
- **Victim:** \`0x...\`
- **Lost:** $...

## 2. Work Log
- [ ] Base Setup (Leader)
- [ ] Replay Verification (Leader)
- [ ] PoC Implementation (Members)
EOF
echo "[+] Created README: $README_PATH"

echo ""
echo "✅ Workspace Initialized: test/$DIR_NAME"
