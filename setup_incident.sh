#!/bin/bash

# Setup Incident Environment
# Usage: ./setup_incident.sh <Protocol> [Date]

PROTOCOL=$1
DATE=$2

# Check arguments
if [ -z "$PROTOCOL" ]; then
    echo "Usage: $0 <ProtocolName> [Date: YYYY-MM-DD]"
    echo "Example: $0 Seneca 2024-02-28"
    exit 1
fi

# Set default date to today if not provided
if [ -z "$DATE" ]; then
    DATE=$(date +%Y-%m-%d)
fi

# Parse Year and Month
YEAR=$(echo $DATE | cut -d'-' -f1)
MONTH=$(echo $DATE | cut -d'-' -f2)

# Define Directory Structure: test/YYYY/MM/ProtocolName
TARGET_DIR="test/${YEAR}/${MONTH}/${PROTOCOL}"

# Create Directory
echo "[*] Creating directory: $TARGET_DIR"
mkdir -p "$TARGET_DIR"

# 1. Create README.md Template
README_PATH="$TARGET_DIR/README.md"
cat <<EOF > "$README_PATH"
# [$PROTOCOL] Hack Analysis

## 1. Incident Summary
- **Date:** $DATE
- **Loss:** \$X,XXX,XXX
- **Attacker:** \`0x...\`
- **Vulnerable Contract:** \`0x...\`
- **Tx Hash:** \`0x...\`
- **Analysis Link:** [URL]

## 2. Root Cause
- Describe the vulnerability here...
- (e.g. Reentrancy protection missing on callback...)

## 3. Attack Flow
1. Flashloan 10,000 ETH
2. Swap ETH to Token A to pump price
3. Call \`deposit()\`...

## 4. Mitigation
- How to fix the vulnerability...
EOF
echo "[+] Created README.md at $README_PATH"

# 2. Create Exploit.t.sol Template (Hybrid Mode: Replay + Logic)
SOL_PATH="$TARGET_DIR/Exploit.t.sol"
cat <<EOF > "$SOL_PATH"
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
@TxHash: 
@Analysis-End
*/

// @Analysis - https://...

contract ${PROTOCOL}Exploit is BaseTest {
    // 1. Constants & Variables
    // IERC20 constant USDC = IERC20(0xA0b8699...);

    function setUp() public {
        // 2. Fork Environment
        // vm.createSelectFork("mainnet", BLOCK_NUMBER); 
        
        // 3. Config Target (for feature mining)
        // target = address(0x...);

        // 4. Labels
        // vm.label(address(USDC), "USDC");
        
        // 5. Config Funding Token & Beneficiary
        // fundingToken = address(USDC);
        // beneficiary = address(this); // Set to 'attacker' if testing replay
    }

    // [Mode 1] Transaction Replay (Data Mining)
    // Run: forge test --match-test testReplay -vvv
    function testReplay() public recordMetrics("REPLAY") {
        // beneficiary = attacker; // Update beneficiary to attacker
        // vm.startPrank(attacker);
        
        // 1. Copy Input Data from Etherscan
        // (bool success, ) = attackContract.call(hex"...");
        // require(success, "Replay failed");
        
        // vm.stopPrank();
    }

    // [Mode 2] Logic Reproduction (Deep Dive)
    // Run: forge test --match-test testExploit -vvv
    function testExploit() public recordMetrics("LOGIC") {
        // vm.startPrank(attacker);
        
        // 1. Implement Logic
        // IVictim(target).deposit{value: 1 ether}();
        // IVictim(target).withdraw();
        
        // vm.stopPrank();
    }
}
EOF
echo "[+] Created Exploit.t.sol at $SOL_PATH"

echo ""
echo "Done! Initialized analysis for $PROTOCOL."
echo "Location: $TARGET_DIR"
