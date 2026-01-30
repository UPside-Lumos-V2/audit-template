# Audit Collaboration Template

**Collaborative Incident Response Environment**
Designed for "1 Incident = 1 Directory" structure to minimize conflicts and enable automated data mining.

## 🚀 Quick Start

### 1. Initialize Incident
```bash
# Creates test/YYYY/MM/ProtocolName with templates
./setup_incident.sh <ProtocolName> [Date]

# Example
./setup_incident.sh Seneca 2024-02-28
```

### 2. Fill Metadata (Important)
Edit `test/.../Exploit.t.sol` header for automated labeling.
```solidity
/*
@Analysis-Start
@Protocol: Seneca
@Date: 2024-02-28
@Lost: 10M USD
@Attacker: 0x...
@Target: 0x...
@TxHash: 0x...
@Analysis-End
*/
```

### 3. Write & Run PoC
```bash
# Run tests
forge test

# Run specific incident
forge test --match-path test/2024/02/Seneca/Exploit.t.sol -vvv
```

## 🛠 Features

- **Conflict-Free:** Isolated directory per incident.
- **Auto-Mining:** `BaseTest` automatically records execution metrics (Gas, Profit, Code Size) to `data/results/`.
- **Pre-loaded Libs:** `IERC20`, `IUniswapV2`, etc. ready to use in `src/shared/interfaces.sol`.

## 📦 Requirements
- [Foundry](https://github.com/foundry-rs/foundry)
