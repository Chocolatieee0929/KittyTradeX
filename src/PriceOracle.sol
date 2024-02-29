// SPDX-License-Identifier: BSD-3-Clause
pragma solidity ^0.8.20;

import "./NBToken.sol";
import {AggregatorV3Interface} from "@chainlink/contracts/v0.8/interfaces/AggregatorV3Interface.sol";
import '@openzeppelin/contracts/utils/math/Math.sol';

contract SimplePriceOracle {
    using Math for *;

    AggregatorV3Interface internal dataFeed;

    /**
     * Network: Sepolia
     * Aggregator: ETH/USD
     * Address: 0x694AA1769357215DE4FAC081bf1f309aDC325306
     */
    constructor() {
        dataFeed = AggregatorV3Interface(0x694AA1769357215DE4FAC081bf1f309aDC325306);
    }

    /**
     * Returns the latest price
     */
    function getChainlinkDataFeedLatestAnswer() internal view returns (int) {
        // prettier-ignore
        (
            /* uint80 roundID */,
            int ethPrice,
            /*uint startedAt*/,
            /*uint timeStamp*/,
            /*uint80 answeredInRound*/
        ) = dataFeed.latestRoundData();
        return ethPrice;
        
    }

    function getNBTtoUsdPrice(address NBTAddress) public view returns (uint) {
        int ethPrice = getChainlinkDataFeedLatestAnswer();
        return uint(ethPrice).mulDiv(INBToken(NBTAddress).totalStake(), NBTAddress.balance);
    }
}