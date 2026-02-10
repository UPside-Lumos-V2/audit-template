// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "forge-std/Test.sol";

contract BaseTest is Test {
    address fundingToken = address(0);
    address target = address(0);
    address beneficiary = address(0);

    struct ChainInfo {
        string name;
        string symbol;
    }

    mapping(uint256 => ChainInfo) private chainIdToInfo;

    constructor() {
        chainIdToInfo[1] = ChainInfo("MAINNET", "ETH");
        chainIdToInfo[8453] = ChainInfo("BASE", "ETH");
        chainIdToInfo[42_161] = ChainInfo("ARBITRUM", "ETH");
        chainIdToInfo[10] = ChainInfo("OPTIMISM", "ETH");
        chainIdToInfo[137] = ChainInfo("POLYGON", "MATIC");
        chainIdToInfo[56] = ChainInfo("BSC", "BNB");
        chainIdToInfo[43_114] = ChainInfo("AVALANCHE", "AVAX");
        chainIdToInfo[250] = ChainInfo("FANTOM", "FTM");
        chainIdToInfo[59_144] = ChainInfo("LINEA", "ETH");
        chainIdToInfo[81_457] = ChainInfo("BLAST", "ETH");
        chainIdToInfo[238] = ChainInfo("BLAST_OLD", "ETH");
        chainIdToInfo[42_220] = ChainInfo("CELO", "CELO");
        chainIdToInfo[324] = ChainInfo("ZKSYNC", "ETH");
        chainIdToInfo[5000] = ChainInfo("MANTLE", "MNT");
        chainIdToInfo[204] = ChainInfo("OPBNB", "BNB");
        chainIdToInfo[534_352] = ChainInfo("SCROLL", "ETH");
        chainIdToInfo[1329] = ChainInfo("SEI", "SEI");
        chainIdToInfo[11_297_108_109] = ChainInfo("PALM", "PALM");
    }

    function getChainSymbol(
        uint256 chainId
    ) internal view returns (string memory symbol) {
        symbol = chainIdToInfo[chainId].symbol;
        if (bytes(symbol).length == 0) symbol = "ETH";
    }

    modifier balanceLog() {
        address user = beneficiary == address(0) ? address(this) : beneficiary;
        uint256 startBalance;

        if (fundingToken == address(0)) {
            vm.deal(user, 0);
            startBalance = user.balance;
        } else {
            startBalance = IERC20(fundingToken).balanceOf(user);
        }

        emit log_named_uint("Before Balance", startBalance);
        _;

        uint256 endBalance = fundingToken == address(0) ? user.balance : IERC20(fundingToken).balanceOf(user);
        emit log_named_uint("After Balance", endBalance);
        emit log_named_uint("Profit", endBalance > startBalance ? endBalance - startBalance : 0);
    }
}

interface IERC20 {
    function balanceOf(
        address
    ) external view returns (uint256);
    function symbol() external view returns (string memory);
    function decimals() external view returns (uint8);
}
