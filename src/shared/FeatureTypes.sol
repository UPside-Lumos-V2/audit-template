// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

// Vulnerability classification - auditor selects one
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
