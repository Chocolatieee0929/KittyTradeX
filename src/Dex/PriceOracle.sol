// SPDX-License-Identifier: BSD-3-Clause
pragma solidity ^0.8.20;

import {IOutswapV1Factory, IOutswapV1Pair, IOutswapV1Callee} from '../interface/IOutswap.sol';
import {AggregatorV3Interface} from "@chainlink/contracts/v0.8/interfaces/AggregatorV3Interface.sol";

import '@openzeppelin/contracts/utils/math/Math.sol';

/**
 * @title SimplePriceOracle
 * 实现 NBT 预言机功能，通过chainlink oracle 获得 ETH/USD 的价格，
 * 再通过 Outswap 的 NBT/NETH 价格，计算出 NBT/USD 的价格，
 * 最后将 NBT/USD 的价格返回
 */

contract SimplePriceOracle {
    using Math for *;

    address private immutable NETH;

    AggregatorV3Interface internal dataFeed;

    address private immutable OUTSWAP_V1_FACTORY;

    IOutswapV1Factory private immutable outswapFactory;

    /**
     * Network: Sepolia
     * Aggregator: ETH/USD
     * Address: 0x694AA1769357215DE4FAC081bf1f309aDC325306
     */
    constructor(address nethAddress, address factoryAddress) {
        // Chainlink 数据源
        dataFeed = AggregatorV3Interface(0x694AA1769357215DE4FAC081bf1f309aDC325306);

        NETH = nethAddress;

        OUTSWAP_V1_FACTORY = factoryAddress;
        outswapFactory = IOutswapV1Factory(OUTSWAP_V1_FACTORY);
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
        // 获取 ETH/USD 的价格
        int ethPrice = getChainlinkDataFeedLatestAnswer();
        
        IOutswapV1Pair pair
            = IOutswapV1Pair(outswapFactory.getPair(NETH, NBTAddress));

        require(address(pair) != address(0), "KittyTradeX PriceOracle: Pair not found");

        (uint112 NBTamount, uint112 NETHamount, ) = pair.getReserves();
        (NBTamount, NETHamount) = NBTAddress < NETH ? (NBTamount, NETHamount):(NETHamount, NBTamount);
        
        // 计算 NBT/USD 的价格, 这样计算价格操纵的风险较大，后续会完善
        return uint(ethPrice).mulDiv(uint256(NETHamount), uint256(NBTamount));
    }
}