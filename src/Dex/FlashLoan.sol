// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import '@openzeppelin/contracts/access/Ownable.sol';
import '@openzeppelin/contracts/utils/ReentrancyGuard.sol';

import {IOutswapV1Factory, IOutswapV1Pair, IOutswapV1Callee} from '../interface/IOutswap.sol';


contract FlashLoan is IOutswapV1Callee, Ownable, ReentrancyGuard {

    address private immutable NETH;

    IERC20 private immutable neth;

    address private immutable OUTSWAP_V1_FACTORY;

    IOutswapV1Factory private immutable outswapFactory;

    constructor(address nethAddress, address factoryAddress) Ownable(msg.sender) {
        NETH = nethAddress;
        neth = IERC20(NETH);
        OUTSWAP_V1_FACTORY = factoryAddress;
        outswapFactory = IOutswapV1Factory(OUTSWAP_V1_FACTORY);
    }

    /// @param token The address of the token  & NETH pair
    /// @param amount The amount of the NETH to be flash borrowed
    function flashLoan(
        address token,
        uint256 amount
    ) external {
        require(token != NETH, "KittyTradeX FlashSwap: IDENTICAL_ADDRESSES");
        require(token != address(0), "KittyTradeX FlashSwap: ZERO_ADDRESS");

        address[] memory path = new address[](2);
        (path[0], path[1]) = token < NETH ? (token, NETH) : (NETH, token);
        (uint256 amount0Out, uint256 amount1Out) = token < NETH ? (uint256(0), amount) : (amount, uint256(0));

        IOutswapV1Pair pair = IOutswapV1Pair(outswapFactory.getPair(path[0], path[1]));

        require(address(pair) != address(0), "KittyTradeX FlashSwap: PAIR_NOT_EXIST");

        pair.swap(amount0Out, amount1Out, address(this), abi.encode(msg.sender, token, NETH, amount));
    }

    // This function is called by the token/NETH pair contract
    function OutswapV1Call(
        address sender,
        uint amount0,
        uint amount1,
        bytes calldata data
    ) external {
        (address caller, address token, address tokenBorrow, uint256 wethAmount) = abi.decode(data, (address, address, address, uint256));
        address pair = outswapFactory.getPair(token, NETH);

        require(msg.sender == pair, "KittyTradeX FlashSwap: not pair");
        require(sender == address(this), "KittyTradeX FlashSwap: not sender");
        require(tokenBorrow == NETH, "KittyTradeX FlashSwap: token borrow != NETH");

        /* perform 逻辑 */        

        // about 0.3% fee, +1 to round up
        uint fee = (amount1 * 3) / 997 + 1;
        uint256 amountToRepay = amount1 + fee;

        // Transfer flash swap fee from caller
        neth.transferFrom(caller, address(this), fee);

        // Repay
        neth.transfer(pair, amountToRepay);
    }
}