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

# Find target directory (Handling YYYY-MM-DD_Protocol format)
# We search for directories containing the Protocol name
MATCH_DIRS=($(ls -d test/*_${PROTOCOL}* 2>/dev/null))
COUNT=${#MATCH_DIRS[@]}

if [ $COUNT -eq 0 ]; then
    echo "❌ Error: No workspace found for protocol '$PROTOCOL'."
    echo "Run ./init_incident.sh first."
    exit 1
elif [ $COUNT -eq 1 ]; then
    TARGET_DIR=${MATCH_DIRS[0]}
else
    echo "⚠️  Multiple incidents found for '$PROTOCOL':"
    for i in "${!MATCH_DIRS[@]}"; do 
        echo "$((i+1)). ${MATCH_DIRS[$i]}"
    done
    read -p "Select directory (1-$COUNT): " SELECTION
    INDEX=$((SELECTION-1))
    TARGET_DIR=${MATCH_DIRS[$INDEX]}
fi

if [ ! -d "$TARGET_DIR" ]; then
    echo "❌ Error: Invalid directory selection."
    exit 1
fi

POC_PATH="$TARGET_DIR/PoC_${MEMBER}.t.sol"

if [ -f "$POC_PATH" ]; then
    echo "❌ Error: File $POC_PATH already exists."
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

echo "✅ Created PoC for $MEMBER in $TARGET_DIR"
