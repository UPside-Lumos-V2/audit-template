// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

// Vulnerability classification for compile-time validation
enum VulnerabilityType {
    UNKNOWN,
    REENTRANCY,
    ORACLE_MANIPULATION,
    FLASH_LOAN,
    ACCESS_CONTROL,
    INTEGER_OVERFLOW,
    LOGIC_ERROR,
    GOVERNANCE,
    FRONT_RUNNING,
    SIGNATURE_REPLAY,
    PRICE_MANIPULATION,
    UNINITIALIZED_PROXY,
    STORAGE_COLLISION
}

// Attack vector classification
enum AttackVector {
    UNKNOWN,
    DIRECT_CALL,
    FLASH_LOAN,
    SANDWICH,
    GOVERNANCE_PROPOSAL,
    CROSS_CHAIN,
    MEV
}

// Analysis result filled by auditor
struct Analysis {
    VulnerabilityType vulnType;
    AttackVector attackVector;
    uint8 severityScore;    // 1-10
    string rootCause;       // One-line summary
}
