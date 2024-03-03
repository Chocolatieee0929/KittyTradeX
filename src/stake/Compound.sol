// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import '@openzeppelin/contracts/access/Ownable.sol';
import '@openzeppelin/contracts/utils/ReentrancyGuard.sol';
import '@openzeppelin/contracts/utils/math/Math.sol';

/**
 * @title Dex, user可以通过质押ETH获得奖励
 * 用户使用eth在feeAccount上进行交易，feeAccount可以收取一定的手续费
 * 手续费会按照质押比例将手续费奖励给质押者，这个质押池满足复利这一功能
 */
contract Compound is Ownable, ReentrancyGuard{
  using Math for uint256;

  event CompoundStake(address indexed user, uint256 amount, uint256 profitPerShare);
  event CompoundUnStake(address indexed user, uint256 amount, uint256 profitPerShare);
  event CompoundCollect(address indexed user, uint256 amount);

  uint256 public profitPerShare;

  uint256 internal totalStake;

  uint256 public constant DECIMALS = 18; // 18位小数
  uint256 public constant BASE = 10**DECIMALS;

  address internal feeAccount;

  struct StakeInfo {
    uint256 stakeAmount;
    uint256 debt; // 收益
    uint256 initialProfitPerShare;
  }

  mapping(address => StakeInfo) internal stakeAccounts;

  constructor(address _feeAccount) Ownable(msg.sender) {
    totalStake = 0;
  }

  fallback() external payable{
    if(_msgSender() == feeAccount){
        updateProfitPerShare(msg.value);
    }
    stake();
  }

  receive() external payable{
    if(_msgSender() == feeAccount){
        updateProfitPerShare(msg.value);
    }
    stake();
  }

  function getDebt() external view returns (uint256) {
    return stakeAccounts[_msgSender()].debt;
  }

  function getStakeAmount() external view returns (uint256) {
    return stakeAccounts[_msgSender()].stakeAmount;
  }

  function getInitialProfitPerShare() external view returns (uint256) {
    return stakeAccounts[_msgSender()].initialProfitPerShare;
  }

  function _updateStake(address account, uint256 amount, bool add) internal {
    uint256 stakeBefore = stakeAccounts[account].stakeAmount;
    uint256 stakeAfter = add ? stakeBefore + amount : stakeBefore - amount;

    if(stakeBefore == 0) stakeAccounts[account].debt = 0;

    uint256 profit = getProfit(stakeBefore, stakeAccounts[account].initialProfitPerShare);
  
    stakeAccounts[account].stakeAmount = stakeAfter;
    stakeAccounts[account].debt + profit;
    stakeAccounts[account].initialProfitPerShare = profitPerShare;
  }

  function stake() public payable nonReentrant {
    _updateStake(msg.sender, msg.value, true);
    totalStake += msg.value;
    emit CompoundStake(msg.sender, msg.value, profitPerShare);
  }

  function unStake(uint256 amount) public nonReentrant {
    require(stakeAccounts[msg.sender].stakeAmount  <= amount, 'Insufficient balance');
    _updateStake(msg.sender, amount, false);
    totalStake -= amount;
    payable(msg.sender).transfer(amount);

    emit CompoundUnStake(msg.sender, amount, profitPerShare);
  }

  function collect(uint256 amount) public {
    require(stakeAccounts[msg.sender].debt > amount, 'No profit to withdraw');
    stakeAccounts[msg.sender].debt -= amount;
    _updateStake(address(this), amount, false);
    payable(msg.sender).transfer(amount);
    emit CompoundCollect(msg.sender, amount);
  }

  function getProfit(uint256 amount, uint256 initialProfitPerShare) internal view returns (uint256) {
    if(amount == 0 || initialProfitPerShare <= profitPerShare) return 0;
    uint256 current_profitPerShare = profitPerShare;
    uint256 profit = amount.mulDiv(current_profitPerShare, initialProfitPerShare);
    return profit;
  }

  function updateProfitPerShare(uint256 fee) internal {
    require(msg.sender == feeAccount);
    profitPerShare = profitPerShare.mulDiv((fee + totalStake) * BASE, totalStake);
  }

}
