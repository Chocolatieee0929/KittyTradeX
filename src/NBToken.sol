// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import '@openzeppelin/contracts/token/ERC20/ERC20.sol';
import '@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol';
import '@openzeppelin/contracts/access/Ownable.sol';
import '@openzeppelin/contracts/utils/ReentrancyGuard.sol';
import '@openzeppelin/contracts/utils/math/Math.sol';

import "./INBToken.sol";

/**
 * @title Dex, 质押ETH挖矿赚token
 */
contract NBToken is ERC20, ERC20Burnable, INBToken, Ownable, ReentrancyGuard {
  using Math for uint256;

  uint256 public mintRate;
  uint256 public totalStake;

  uint256 public lastEarnNumber;
  uint256 public profitPerShare;

  uint256 public constant DECIMALS = 18; // 18位小数
  uint256 public constant BASE = 10**DECIMALS;

  struct StakeInitial {
    uint256 stakeAmount;
    uint256 debt;
    uint256 initialProfitPerShare;
  }

  mapping(address => StakeInitial) internal stakeAccounts;

  constructor() ERC20('NftBazaarToken', 'NBT') Ownable(msg.sender) {
    lastEarnNumber = block.number;
    mintRate = 10;
    totalStake = 0;
  }

  fallback() external payable{
    stake();
  }

  receive() external payable{
    stake();
  }
  

  function _updateStake(address account, uint256 amount, bool add) internal {
    pendingEarn();
    uint256 stakeBefore = stakeAccounts[account].stakeAmount;
    uint256 stakeAfter = add ? stakeBefore + amount : stakeBefore - amount;
    totalStake = add ? totalStake + amount : totalStake - amount;

    if(stakeBefore == 0) stakeAccounts[account].debt = 0;

    uint256 profit = getProfit(stakeBefore, stakeAccounts[account].initialProfitPerShare);
  
    stakeAccounts[account].stakeAmount = stakeAfter;
    stakeAccounts[account].debt + profit;
    stakeAccounts[account].initialProfitPerShare = profitPerShare;
  }

  function stake() public payable nonReentrant {
    _updateStake(msg.sender, msg.value, true);
    emit NBTokenStake(msg.sender, msg.value, profitPerShare);
  }

  function unStake(uint256 amount) public nonReentrant {
    require(stakeAccounts[msg.sender].stakeAmount  <= amount, 'Insufficient balance');
    _updateStake(msg.sender, amount, false);
    payable(msg.sender).transfer(amount);

    emit NBTokenUnStake(msg.sender, amount, profitPerShare);
  }

  function claim(uint256 amount) public nonReentrant {
    require(stakeAccounts[msg.sender].debt > amount, 'No profit to withdraw');
    stakeAccounts[msg.sender].debt -= amount;
    _mint(msg.sender, amount);
    transfer(msg.sender, amount);
    emit NBTokenCollect(msg.sender, amount);
  }

  function pendingEarn() internal {
    if(block.number < lastEarnNumber) return;
    uint256 fee = (block.number - lastEarnNumber) * 10;
    profitPerShare = profitPerShare + mintRate *BASE / totalStake;
  }

  function getProfit(uint256 amount, uint256 initialProfitPerShare) internal view returns (uint256) {
    if(amount == 0 || initialProfitPerShare <= profitPerShare) return 0;
    uint256 current_profitPerShare = profitPerShare;
    uint256 profit = amount.mulDiv((current_profitPerShare - initialProfitPerShare), BASE);
    return profit;
  }
}
