#!/bin/bash

# add_poc.sh
# Purpose: Create an individual PoC file for a team member
# Usage: ./add_poc.sh <Protocol> <MemberName>

PROTOCOL=$1
MEMBER=$2

if [ -z "$PROTOCOL" ] || [ -z "$MEMBER" ]; then
    echo "Usage: $0 <Protocol> <MemberName>"
    echo "Example: $0 Seneca Alice"
    exit 1
fi

TARGET_DIR="test/$PROTOCOL"
POC_PATH="$TARGET_DIR/PoC_${MEMBER}.t.sol"

if [ ! -d "$TARGET_DIR" ]; then
    echo "Error: Workspace '$PROTOCOL' does not exist. Run ./init_incident.sh first."
    exit 1
fi

if [ -f "$POC_PATH" ]; then
    echo "Error: File $POC_PATH already exists."
    exit 1
fi

cat <<EOF > "$POC_PATH"
// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.10;

import "./${PROTOCOL}Base.sol";

contract PoC_${MEMBER} is ${PROTOCOL}Base {
    function setUp() public override {
        super.setUp();
        // Add personal setup if needed
    }

    // Logic Reproduction (Deep Dive)
    function testExploit() public recordMetrics("PoC_${MEMBER}") {
        // vm.startPrank(attacker);
        
        // Implement your logic here...
        // IVictim(target).deposit();
        
        // vm.stopPrank();
    }
}
EOF

echo "✅ Created PoC for $MEMBER: $POC_PATH"
