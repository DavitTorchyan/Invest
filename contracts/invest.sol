//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "hardhat/console.sol";
import "./StakeToken.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

contract Invest {

    using SafeERC20 for StakeToken;
    StakeToken public stakeToken;
    mapping(address => uint256) public totalTokensInvested;
    mapping(address => uint256) public totalEtherInvested;
    mapping(address => InvestInfo[]) public investInfo;

    enum Asset{ Ether, Token }

    struct InvestInfo {
        Asset asset;
        uint256 investAmount;
        uint256 investBlockNumber;
    }

    constructor(StakeToken _StakeToken) {
        require(address(_StakeToken) != address(0), "Token address can not be zero.");
        stakeToken = _StakeToken;
    }

    function invest(uint256 amount) external payable {
        require(amount == 0 || msg.value == 0, "Can not invest both tokens and ether.");
        if(msg.value == 0) {
            investInfo[msg.sender].push(InvestInfo({asset: Asset.Token, investAmount: amount, investBlockNumber: block.number}));
            totalTokensInvested[msg.sender] += amount;
        }else {
            investInfo[msg.sender].push(InvestInfo({asset: Asset.Ether, investAmount: msg.value, investBlockNumber: block.number}));
            totalEtherInvested[msg.sender] += msg.value;
        }
    }

    function withdrawToken(uint256 amount, uint256 id) external {
        require(investInfo[msg.sender][id].asset == Asset.Token, "Can not withdraw anything other than Stake Token.");
        require(amount <= investInfo[msg.sender][id].investAmount, "Not enough investments, try lesser amount.");
        _claim(id, msg.sender);
        stakeToken.safeTransfer(msg.sender, amount);
        totalTokensInvested[msg.sender] -= amount;
    }

    function withdrawEther(uint256 amount, uint256 id) external {
        require(investInfo[msg.sender][id].asset == Asset.Ether, "Can not withdraw anything other than Ether.");
        require(amount <= investInfo[msg.sender][id].investAmount, "Not enough investments, try lesser amount.");
        _claim(id, msg.sender);
        payable(msg.sender).transfer(amount);
        totalEtherInvested[msg.sender] -= amount;
    }

    function claim(uint256 id) public {
        _claim(id, msg.sender);
    }

    function _claim(uint256 id, address account) private {
        require(investInfo[msg.sender][id].investAmount != 0, "No investments.");
        uint256 blocksPassed = ((block.number - investInfo[msg.sender][id].investBlockNumber) / 5) - ((block.number - investInfo[msg.sender][id].investBlockNumber) % 5);
        uint256 reward = investInfo[msg.sender][id].investAmount * (105 * blocksPassed / 100);
        stakeToken.safeTransfer(account, reward);
    }

}