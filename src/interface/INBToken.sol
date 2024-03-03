// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface INBToken {
    event NBTokenStake(address indexed user, uint256 amount, uint256 profitPerShare);
    event NBTokenUnStake(address indexed user, uint256 amount, uint256 profitPerShare);
    event NBTokenCollect(address indexed user, uint256 amount);

    function stake() external payable;

    function unStake(uint256 amount) external;

    function claim(uint256 amount) external;

    function totalStake() external view returns (uint256);
}
