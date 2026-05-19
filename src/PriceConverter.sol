// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {
    AggregatorV3Interface
} from "../lib/chainlink-brownie-contracts/contracts/src/v0.8/shared/interfaces/AggregatorV2V3Interface.sol";

library PriceConverter {
    function getPrice(AggregatorV3Interface priceFeed) internal view returns (uint256) {
        (, int256 answer,,,) = priceFeed.latestRoundData();
        // forge-lint: disable-next-line(unsafe-typecast)
        return uint256(answer * 10e8);
    }

    function getConversionRate(uint256 ethAmount, AggregatorV3Interface priceFeed) internal view returns (uint256) {
        uint256 ethPrice = getPrice(priceFeed);
        uint256 ethAmountInUsd = (ethPrice * ethAmount) / 10e18;
        return ethAmountInUsd;
    }
}
