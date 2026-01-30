# Audit Template Collaboration Guide

## 🎯 Goal
This repository is designed for high-pressure **Incident Response** collaboration.
We use a **"1 Incident = 1 Directory"** structure to minimize merge conflicts and archive all analyses effectively.

## 📂 Structure
```text
audit-template/
├── src/
│   └── shared/               # Shared Interfaces (IERC20, etc.)
├── test/
│   └── 2024/
│       └── 02/
│           └── Seneca/       # Independent Incident Package
│               ├── Exploit.t.sol
│               └── README.md
└── setup_incident.sh         # Automation Script
```

## 🚀 Workflow

### 1. New Incident
When a hack occurs, run the setup script to generate the environment.

```bash
# Usage: ./setup_incident.sh <ProtocolName> [Date]
./setup_incident.sh Seneca 2024-02-28
```
This creates `test/2024/02/Seneca` with a README and Test template.

### 2. Feature Branch
Create a branch for the incident.
```bash
git checkout -b incident/2024-02-28-seneca
```

### 3. Analyze & PoC
- Fill in `README.md` with attack details.
- Write reproduction code in `Exploit.t.sol`.
- Use `src/shared/interfaces.sol` for common tokens/interfaces.

### 4. PR & Merge
- Open a Pull Request (PR) with a screenshot of the PoC passing.
- CI will automatically run `forge test` to verify your code.
- Merge into `main` only when verified.

## 🛠 Setup

### Prerequisites
- [Foundry](https://github.com/foundry-rs/foundry) installed.

### Installation
```bash
forge install
```

### Running Tests
```bash
forge test
```
To run a specific incident:
```bash
forge test --match-path test/2024/02/Seneca/Exploit.t.sol -vvv
```
