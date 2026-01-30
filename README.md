# Audit Collaboration Template

**Collaborative Incident Response & Data Mining Environment**
Designed for high-performance teams analyzing DeFi hacks. Features a **"3-Layer Architecture"** to separate configuration, ground truth, and individual analysis.

## 🚀 Workflow Guide

### 1. 👑 Lead: Initialize Workspace
Create a new shared workspace for the incident.
```bash
# Usage: ./init_incident.sh <Protocol>
./init_incident.sh Seneca
```
*   Creates `test/Seneca/`
*   Generates `SenecaBase.sol` (Shared Config) & `Replay.t.sol` (Ground Truth)

### 2. 👑 Lead: Setup & Verify
1.  **Edit `SenecaBase.sol`**: Set `BLOCK_NUMBER`, `target`, `fundingToken`.
2.  **Edit `Replay.t.sol`**: Paste the hacker's input data to verify the environment.
3.  **Push Branch**: `git checkout -b incident/Seneca` -> `git push`

### 3. 👷 Member: Add PoC
Members checkout the incident branch and create their own PoC file.
```bash
git checkout incident/Seneca
git checkout -b feat/Seneca/Alice

# Usage: ./add_poc.sh <Protocol> <MemberName>
./add_poc.sh Seneca Alice
```
*   Creates `test/Seneca/PoC_Alice.t.sol`
*   Inherits `SenecaBase`, so you can focus solely on `testExploit()`.

### 4. 📊 Auto-Mining & Verification
All tests automatically generate execution metrics (Gas, Profit, Code Size) in `data/results/`.
- **Replay**: Used as the benchmark (Ground Truth).
- **PoC**: Verified against the benchmark.

## 🛠 Features
- **3-Layer Architecture**: `BaseTest` (Global) -> `IncidentBase` (Shared) -> `PoC` (Personal).
- **Hybrid Verification**: Support for both **Transaction Replay** (Fast Data) and **Logic Reproduction** (Deep Analysis).
- **Conflict-Free**: Individual files for each member (`PoC_Alice.sol`, `PoC_Bob.sol`).

## 📦 Requirements
- [Foundry](https://github.com/foundry-rs/foundry)
