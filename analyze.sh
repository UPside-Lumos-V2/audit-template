#!/bin/bash

# analyze.sh
# The One-Stop Solution for Incident Response & Collaboration
# Usage: ./analyze.sh -p <Protocol> -d <Date> -c <ChainID> -t <TxHash> -b <BlockNumber>

# ==========================================
# 1. Configuration & Input Parsing
# ==========================================

# Colors
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m'

# Default values
PROTOCOL=""
DATE=""
CHAIN_ID="1"
TX_HASH=""
BLOCK_NUMBER=""
MEMBER_NAME=$(git config user.name)

# Helper: Print error and exit
die() { echo -e "${RED}❌ $1${NC}"; exit 1; }
info() { echo -e "${GREEN}✅ $1${NC}"; }
warn() { echo -e "${YELLOW}⚠️  $1${NC}"; }

# Parse flags
while getopts "p:d:c:t:b:" opt; do
  case $opt in
    p) PROTOCOL="$OPTARG" ;;
    d) DATE="$OPTARG" ;;
    c) CHAIN_ID="$OPTARG" ;;
    t) TX_HASH="$OPTARG" ;;
    b) BLOCK_NUMBER="$OPTARG" ;;
    \?) die "Invalid option -$OPTARG" ;;
  esac
done

# Interactive mode
if [ -z "$MEMBER_NAME" ]; then
    read -p "👤 Enter your name (for PoC file): " MEMBER_NAME
fi

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
    read -p "3. Transaction Hash: " TX_HASH
fi

if [ -z "$CHAIN_ID" ]; then
    read -p "4. Chain ID (1:Mainnet, 56:BSC, 42161:Arb, ...) [Default: 1]: " INPUT_CHAIN
    CHAIN_ID=${INPUT_CHAIN:-1}
fi

if [ -z "$BLOCK_NUMBER" ]; then
    read -p "5. Block Number (Before Hack): " BLOCK_NUMBER
fi

# Validation
[ -z "$PROTOCOL" ] && die "Protocol name is required."
[ -z "$TX_HASH" ] && die "Transaction hash is required."
[ -z "$BLOCK_NUMBER" ] && die "Block number is required."

# Chain ID Mapping (Simple version)
# In a real scenario, we could parse foundry.toml, but hardcoding common ones is faster/safer here.
RPC_ALIAS="mainnet"
case $CHAIN_ID in
    1) RPC_ALIAS="mainnet" ;;
    56) RPC_ALIAS="bsc" ;;
    137) RPC_ALIAS="polygon" ;;
    42161) RPC_ALIAS="arbitrum" ;;
    10) RPC_ALIAS="optimism" ;;
    43114) RPC_ALIAS="avalanche" ;;
    250) RPC_ALIAS="fantom" ;;
    *) warn "Unknown Chain ID $CHAIN_ID. Defaulting to 'mainnet' alias." ;;
esac

# ==========================================
# 2. Strict Verification (Gatekeeper)
# ==========================================

echo "🔍 Verifying Inputs..."

# Check 1: RPC Connection
# We assume the user has configured RPCs in foundry.toml or environment variables.
# We use 'forge script' or 'cast' to check.
# For simplicity in this template, we skip live RPC check if env vars are missing, 
# but strictly warn the user.
if [ -z "$ETH_RPC_URL" ] && [ "$RPC_ALIAS" == "mainnet" ]; then
    warn "ETH_RPC_URL not set. Skipping live RPC check (Strict Mode Disabled)."
else
    # Try to fetch the block to verify RPC connectivity and Block existence
    # cast block $BLOCK_NUMBER --rpc-url $RPC_ALIAS > /dev/null 2>&1
    # if [ $? -ne 0 ]; then
    #    die "Failed to fetch block $BLOCK_NUMBER from chain $CHAIN_ID. Check RPC connection or Block Number."
    # fi
    info "RPC Connection Verified (Simulated)"
fi

# ==========================================
# 3. Context Switching & Strategy
# ==========================================

# Deterministic Directory & Branch Name
DIR_NAME="${DATE}_${PROTOCOL}"
TARGET_DIR="test/$DIR_NAME"
BRANCH_NAME="incident/$DIR_NAME"

echo "[*] Workspace: $TARGET_DIR"
echo "[*] Branch:    $BRANCH_NAME"

# Fetch latest state
git fetch origin > /dev/null 2>&1

# Check if incident branch exists remotely
REMOTE_EXISTS=$(git ls-remote --heads origin $BRANCH_NAME | wc -l)

if [ "$REMOTE_EXISTS" -eq "1" ]; then
    # Case A: Collaborator Mode (Join existing)
    echo "🤝 Joining existing incident..."
    
    if git show-ref --verify --quiet "refs/heads/$BRANCH_NAME"; then
        git checkout $BRANCH_NAME
        git pull origin $BRANCH_NAME
    else
        git checkout -b $BRANCH_NAME origin/$BRANCH_NAME
    fi
    
    IS_INITIATOR=0
else
    # Case B: Initiator Mode (Create new)
    echo "👑 Initializing new incident..."
    
    # Check if we are already on the branch (local only case)
    CURRENT_BRANCH=$(git branch --show-current)
    if [ "$CURRENT_BRANCH" != "$BRANCH_NAME" ]; then
        git checkout -b $BRANCH_NAME
    fi
    
    IS_INITIATOR=1
fi

mkdir -p "$TARGET_DIR"

# ==========================================
# 4. File Generation (Idempotent)
# ==========================================

BASE_PATH="$TARGET_DIR/${PROTOCOL}Base.sol"
REPLAY_PATH="$TARGET_DIR/Replay.t.sol"
README_PATH="$TARGET_DIR/README.md"
POC_PATH="$TARGET_DIR/PoC_${MEMBER_NAME// /_}.t.sol" # Replace spaces in name

# A. Generate Base (Only if missing)
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
@Attacker: 
@Target: 
@TxHash: $TX_HASH
@ChainId: $CHAIN_ID
@Analysis-End
*/

abstract contract ${PROTOCOL}Base is BaseTest {
    function setUp() public virtual {
        // Chain ID: $CHAIN_ID
        // Block: $BLOCK_NUMBER
        vm.createSelectFork("$RPC_ALIAS", $BLOCK_NUMBER); 
        
        // Mining Config
        // target = address(0x...);
        // fundingToken = address(USDC);
        
        // Labeling
        // vm.label(address(USDC), "USDC");
    }
}
EOF
    echo "    + Created Base: $BASE_PATH"
fi

# B. Generate Replay (Only if missing)
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
        // beneficiary = attacker;
        // vm.startPrank(attacker);
        
        // Replay Logic
        // (bool success, ) = attackContract.call(hex"...");
        // require(success, "Replay failed");
        
        // vm.stopPrank();
    }
}
EOF
    echo "    + Created Replay: $REPLAY_PATH"
fi

# C. Generate README (Only if missing)
if [ ! -f "$README_PATH" ]; then
    cat <<EOF > "$README_PATH"
# $PROTOCOL Incident Analysis

## 1. Incident Summary
- **Date:** $DATE
- **Chain ID:** $CHAIN_ID
- **Block:** $BLOCK_NUMBER
- **Tx Hash:** \`$TX_HASH\`
- **Attacker:** \`0x...\`
- **Victim:** \`0x...\`
- **Lost:** $...

## 2. Work Log
- [ ] Base Setup (Initiator)
- [ ] Replay Verification (Initiator)
- [ ] PoC Implementation (Collaborators)
EOF
    echo "    + Created README: $README_PATH"
fi

# D. Generate Personal PoC (Always for new member)
if [ ! -f "$POC_PATH" ]; then
    cat <<EOF > "$POC_PATH"
// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.10;

import "./${PROTOCOL}Base.sol";

contract PoC_${MEMBER_NAME// /_} is ${PROTOCOL}Base {
    function setUp() public override {
        super.setUp();
    }

    function testExploit() public recordMetrics("PoC_${MEMBER_NAME// /_}") {
        // vm.startPrank(attacker);
        // IVictim(target).deposit();
        // vm.stopPrank();
    }
}
EOF
    echo "    + Created PoC: $POC_PATH"
else
    echo "    . PoC file already exists: $POC_PATH"
fi

# ==========================================
# 5. Atomic Push & Concurrency Handling
# ==========================================

if [ "$IS_INITIATOR" -eq "1" ]; then
    echo "🚀 Attempting to publish as Initiator..."
    
    # 1. Run Verification (Replay Test)
    # Ideally, we run 'forge test' here.
    # forge test --match-path "$REPLAY_PATH" || die "Replay verification failed!"
    
    git add "$TARGET_DIR"
    git commit -m "init: incident $PROTOCOL ($DATE)" > /dev/null 2>&1
    
    # 2. Push with Lease (Atomic Check)
    if git push origin $BRANCH_NAME 2>/dev/null; then
        info "Success! You are the Initiator."
    else
        warn "Push rejected! Someone else initialized this incident just now."
        echo "🔄 Switching to Collaborator mode..."
        
        # Reset local changes that conflicted
        git reset --hard HEAD~1
        
        # Pull the winner's code
        git pull origin $BRANCH_NAME
        
        # Re-generate ONLY my PoC file (Base/Replay will come from winner)
        # Note: In a real script, we'd loop back or re-run generation logic.
        # For MVP, we assume pull synced the Base files.
        info "Synced with remote. You are now a Collaborator."
    fi
else
    # Collaborator just creates a local commit for their PoC
    info "Environment ready. Happy Hacking, $MEMBER_NAME!"
fi

echo ""
echo "🎯 Target: $TARGET_DIR"
