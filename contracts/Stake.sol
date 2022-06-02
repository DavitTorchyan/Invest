//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "hardhat/console.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "./StakeToken.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

contract Stake is Ownable {

    using SafeERC20 for StakeToken;
    StakeToken public stakeToken;
    uint256 private constant MIN_AMOUNT = 10 ether;
    uint256 private constant MAX_AMOUNT = 100 ether;
    uint256 private constant REWARD_PER_BLOCK = 0.01 ether;
    mapping(address => uint256) public totalStaked;
    mapping(address => StakeInfo[]) public stakeInfo;

    struct StakeInfo {
        uint256 stakeUntil;
        uint256 period;
        uint256 stakeAmount;
    }

    constructor(StakeToken _StakeToken) {
        require(address(_StakeToken) != address(0), "Token address can not be zero.");
        stakeToken = _StakeToken;
    }

    function stake(uint256 amount, uint256 period) external {
        require(period >= 1000 && period <= 5000, "Period not correct.");
        require(amount >= MIN_AMOUNT && amount <= MAX_AMOUNT, "Stake not in range.");
        stakeInfo[msg.sender].push(StakeInfo({stakeUntil: block.number + period, period: period, stakeAmount: amount}));
        totalStaked[msg.sender] += amount;
        stakeToken.safeTransferFrom(msg.sender, address(this), amount);
    }

    function unstake(uint256 amount, uint256 id) external {
        require(block.number >= stakeInfo[msg.sender][id].stakeUntil, "Period requirements not met.");
        require(amount <= stakeInfo[msg.sender][id].stakeAmount, "Not enough stakings, try lesser amount.");
        require(stakeInfo[msg.sender][id].stakeAmount - amount >= MIN_AMOUNT, "Remaining stake is less than min amount.");
        _claim(id, msg.sender);
        stakeToken.safeTransfer(msg.sender, amount);
        totalStaked[msg.sender] -= amount;
    }
    
    function claim(uint256 id) public {
        _claim(id, msg.sender);
    }

    function _claim(uint256 id, address account) private {
        require(stakeInfo[msg.sender][id].stakeAmount != 0, "No stakes done.");
        require(block.number >= stakeInfo[account][id].stakeUntil, "Can not claim reward before stakeUntil.");
        uint256 reward = REWARD_PER_BLOCK * (stakeInfo[account][id].period + block.number - stakeInfo[account][id].stakeUntil);
        stakeToken.safeTransfer(account, reward);
    }

    function getStake(address account) public view returns(StakeInfo[] memory) {
        return stakeInfo[account];
    }

}