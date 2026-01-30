# Audit Collaboration Template

**Collaborative Incident Response & Data Mining Environment**
Designed for high-performance teams analyzing DeFi hacks. Features a **"3-Layer Architecture"** and **"Unified Entrypoint"** for seamless collaboration.

## 🚀 Workflow Guide

### 🎬 Start Analysis (One-Click)
Whether you are the first responder (Initiator) or joining later (Collaborator), use the **same command**. The system handles branching and setup automatically.

```bash
# Usage: ./analyze.sh
./analyze.sh
```
*   **Wizard Mode**: Follow the prompts to enter Protocol, Date, TxHash, etc.
*   **Auto-Magic**:
    *   If **New Incident**: Creates workspace, `Base.sol`, `Replay.t.sol`, and pushes to Git.
    *   If **Existing**: Pulls the branch and adds your personal `PoC_<Name>.t.sol`.

### ⚡️ Quick Flags (Advanced)
```bash
./analyze.sh -p Seneca -t 0x123... -c 1 -b 1920000
```

### 📊 Auto-Mining & Verification
All tests automatically generate execution metrics (Gas, Profit, Code Size) in `data/results/`.
*   **Replay**: Used as the benchmark (Ground Truth).
*   **PoC**: Verified against the benchmark.

## 🛠 Features
- **Conflict-Free**: Individual files for each member (`PoC_Alice.sol`, `PoC_Bob.sol`).
- **Race-Condition Safe**: Handles simultaneous initializations gracefully.
- **Strict Verification**: Validates Chain ID and Block Number before creation.

## 📦 Requirements
- [Foundry](https://github.com/foundry-rs/foundry)
