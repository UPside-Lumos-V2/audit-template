// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "./TokenHelper.sol";
import "forge-std/Test.sol";

contract BaseTest is Test {
    address fundingToken = address(0);
    address target = address(0); // For metadata collection
    address beneficiary = address(0); // For calculating profit

    struct ChainInfo {
        string name;
        string symbol;
    }

    mapping(uint256 => ChainInfo) private chainIdToInfo;

    constructor() {
        chainIdToInfo[1] = ChainInfo("MAINNET", "ETH");
        chainIdToInfo[238] = ChainInfo("BLAST", "ETH");
        chainIdToInfo[10] = ChainInfo("OPTIMISM", "ETH");
        chainIdToInfo[250] = ChainInfo("FANTOM", "FTM");
        chainIdToInfo[42_161] = ChainInfo("ARBITRUM", "ETH");
        chainIdToInfo[56] = ChainInfo("BSC", "BNB");
        chainIdToInfo[1285] = ChainInfo("MOONRIVER", "MOVR");
        chainIdToInfo[100] = ChainInfo("GNOSIS", "XDAI");
        chainIdToInfo[43_114] = ChainInfo("AVALANCHE", "AVAX");
        chainIdToInfo[137] = ChainInfo("POLYGON", "MATIC");
        chainIdToInfo[42_220] = ChainInfo("CELO", "CELO");
        chainIdToInfo[8453] = ChainInfo("BASE", "ETH");
        chainIdToInfo[1329] = ChainInfo("SEI", "SEI");
    }

    function getChainSymbol(
        uint256 chainId
    ) internal view returns (string memory symbol) {
        symbol = chainIdToInfo[chainId].symbol;
        if (bytes(symbol).length == 0) symbol = "ETH";
    }

    function _getTokenData(
        address token,
        address account
    ) internal returns (string memory symbol, uint256 balance, uint8 decimals) {
        if (token == address(0)) {
            symbol = getChainSymbol(block.chainid);
            balance = account.balance;
            decimals = 18;
        } else {
            symbol = TokenHelper.getTokenSymbol(token);
            balance = TokenHelper.getTokenBalance(token, account);
            decimals = TokenHelper.getTokenDecimals(token);
        }
    }

    function _logTokenBalance(
        address token,
        address account,
        string memory label
    ) internal {
        (string memory symbol, uint256 balance, uint8 decimals) = _getTokenData(token, account);
        emit log_named_decimal_uint(string(abi.encodePacked(label, " ", symbol, " Balance")), balance, decimals);
    }

    function _writeExecutionResult(
        string memory tag,
        uint256 gasUsed,
        uint256 profit,
        string memory symbol,
        uint8 decimals
    ) internal {
        string memory jsonObj = "result";

        // 1. Context Features
        vm.serializeString(jsonObj, "mode", tag);
        vm.serializeUint(jsonObj, "chain_id", block.chainid);
        vm.serializeUint(jsonObj, "block_number", block.number);
        vm.serializeUint(jsonObj, "block_timestamp", block.timestamp);

        // 2. Cost & Complexity Features
        vm.serializeUint(jsonObj, "gas_used", gasUsed);

        // 3. Financial Impact Features
        vm.serializeUint(jsonObj, "realized_profit", profit);
        vm.serializeString(jsonObj, "token_symbol", symbol);
        vm.serializeUint(jsonObj, "token_decimals", decimals);
        vm.serializeAddress(jsonObj, "token_address", fundingToken);

        // 4. Static Analysis Features (Code Size)
        uint256 victimCodeSize = target == address(0) ? 0 : target.code.length;
        vm.serializeUint(jsonObj, "victim_code_size", victimCodeSize);

        // Success Flag
        string memory finalJson = vm.serializeBool(jsonObj, "success", true);

        // Generate Unique Filename
        // Format: result_<tag>_<block_timestamp>_<block_number>.json
        string memory fileName = string(
            abi.encodePacked(
                "data/results/result_", tag, "_", vm.toString(block.timestamp), "_", vm.toString(block.number), ".json"
            )
        );

        // Write to file (Requires fs_permissions in foundry.toml)
        vm.writeJson(finalJson, fileName);
    }

    // Default modifier for backward compatibility
    modifier balanceLog() {
        uint256 startGas = gasleft();
        address user = beneficiary == address(0) ? address(this) : beneficiary;
        (string memory symbol, uint256 startBalance, uint8 decimals) = _getTokenData(fundingToken, user);

        if (fundingToken == address(0)) vm.deal(user, 0);
        _logTokenBalance(fundingToken, user, "Attacker Before");

        _;

        uint256 endGas = gasleft();
        uint256 gasUsed = startGas - endGas;
        (,, uint256 endBalance) = _getTokenData(fundingToken, user);
        uint256 profit = endBalance > startBalance ? endBalance - startBalance : 0;

        _logTokenBalance(fundingToken, user, "Attacker After");
        _writeExecutionResult("DEFAULT", gasUsed, profit, symbol, decimals);
    }

    // New modifier for tagged execution (Replay vs Logic)
    modifier recordMetrics(
        string memory tag
    ) {
        uint256 startGas = gasleft();
        address user = beneficiary == address(0) ? address(this) : beneficiary;
        (string memory symbol, uint256 startBalance, uint8 decimals) = _getTokenData(fundingToken, user);

        if (fundingToken == address(0)) vm.deal(user, 0);
        _logTokenBalance(fundingToken, user, string(abi.encodePacked("[", tag, "] Attacker Before")));

        _;

        uint256 endGas = gasleft();
        uint256 gasUsed = startGas - endGas;
        (,, uint256 endBalance) = _getTokenData(fundingToken, user);
        uint256 profit = endBalance > startBalance ? endBalance - startBalance : 0;

        _logTokenBalance(fundingToken, user, string(abi.encodePacked("[", tag, "] Attacker After")));
        _writeExecutionResult(tag, gasUsed, profit, symbol, decimals);
    }

    function logTokenBalance(
        address token,
        address account,
        string memory label
    ) internal {
        _logTokenBalance(token, account, label);
    }

    function logMultipleTokenBalances(
        address[] memory tokens,
        address account,
        string memory label
    ) internal {
        emit log_string(string(abi.encodePacked("=== ", label, " ===")));
        for (uint256 i = 0; i < tokens.length; i++) {
            _logTokenBalance(tokens[i], account, "");
        }
    }
}
