#!/bin/bash

# init_incident.sh
# Purpose: Initialize a new Incident Workspace for team collaboration
# Usage: ./init_incident.sh <ProtocolName>

PROTOCOL=$1

if [ -z "$PROTOCOL" ]; then
    echo "Usage: $0 <ProtocolName>"
    echo "Example: $0 Seneca"
    exit 1
fi

TARGET_DIR="test/$PROTOCOL"

if [ -d "$TARGET_DIR" ]; then
    echo "Error: Directory $TARGET_DIR already exists."
    exit 1
fi

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
@Date: YYYY-MM-DD
@Lost: 
@Attacker: 
@Target: 
@TxHash: 
@Analysis-End
*/

abstract contract ${PROTOCOL}Base is BaseTest {
    // Shared Setup for all team members
    function setUp() public virtual {
        // 1. Fork Environment (Leader sets this)
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
        
        // 1. Copy Input Data from Etherscan
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
- **Attacker:** \`0x...\`
- **Victim:** \`0x...\`
- **Tx Hash:** \`0x...\`
- **Lost:** $...

## 2. Work Log
- [ ] Base Setup (Leader)
- [ ] Replay Verification (Leader)
- [ ] PoC Implementation (Members)
EOF
echo "[+] Created README: $README_PATH"

echo ""
echo "✅ Workspace Initialized!"
echo "Next Steps:"
echo "1. Edit $BASE_PATH (Setup)"
echo "2. Edit $REPLAY_PATH (Verify)"
echo "3. Team members run: ./add_poc.sh $PROTOCOL <Name>"
