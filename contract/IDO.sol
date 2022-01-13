// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./Token.sol";

contract IDO is Ownable {
    uint256 public offerCount;
    uint256 public publicTime;
    uint256 public startTime;
    uint256 public cliff;
    uint256 public totalPeriods;
    uint256 public timePerPeriod;

    uint256 public totalTokens = 100000 * 1000000000000000000;
    uint256 public TotalFlag;
    uint256 public FirstReturn;
    uint256 public periodReturn;

    uint256 public exchangeRate;
    uint256 public stakingRate;
    uint256 public allow_flag = 1;

    mapping(uint256 => address) public userToken;
    mapping(address => uint256) public userAmount;

    mapping(address => uint256) public userFunds;
    mapping(address => uint256) public userFundsInUSDT;
    mapping(address => uint256) public buyState;
    mapping(address => uint256) public userClaim;
    mapping(address => uint256) public userRemain;
    mapping(address => uint256) public userClaimed;
    mapping(address => uint256) public userTransfer;
    mapping(address => uint256) public award;
    mapping(address => uint256) private adminlist;
    uint256 public numberOfAccounts = 0;
    BAoEToken BATK;

    // Define fixed adminlist

    event ClaimFunds(address user, uint256 amount);
    event DonateEvent(address user, uint256 amount);

    constructor(
        address _token,
        uint256 _publicTime,
        uint256 _startTime,
        uint256 _cliff,
        uint256 _totalPeriods,
        uint256 _timePerPeriod,
        uint256 _FirstReturn,
        uint256 _periodReturn,
        uint256 _exchangeRate,
        address[] memory accounts,
        uint256[] memory packages

    ) {
        BATK = BAoEToken(_token);
        publicTime = _publicTime;
        FirstReturn = _FirstReturn;
        periodReturn = _periodReturn;
        startTime = _startTime;
        cliff = _cliff;
        totalPeriods = _totalPeriods;
        timePerPeriod = _timePerPeriod;
        exchangeRate = _exchangeRate;
        adminlist[msg.sender] = 1;
        for (uint256 i = 0; i < accounts.length; i++) {
            userFundsInUSDT[accounts[i]] += packages[i]*(10**18);
            userFunds[accounts[i]] += (packages[i]*(10**18) * 40);
            userClaimed[accounts[i]] = 0;
            userRemain[accounts[i]] = userFunds[accounts[i]];
            userToken[numberOfAccounts] = accounts[i];
            numberOfAccounts =numberOfAccounts  +  1;
        }

    }  

    function changeAllowFlag(uint256 flag) public returns (uint256) {
        if (adminlist[msg.sender] == 1) {
            allow_flag = flag;
        }
        return flag;
    }


    function approveToken() external payable onlyOwner {
        BATK.transfer(msg.sender, msg.value);
    }

    event TokensClaimed(address receiver, uint256 tokensClaimed);
    event VestingStopped();
    event WithDraw(uint256 amount);


    function claimTokens(address receiver) internal {
        if (userRemain[receiver] > 0) {
            if (block.timestamp > startTime+cliff) {
                TotalFlag = (block.timestamp-(startTime+cliff))/timePerPeriod;
                if (TotalFlag == 0) {
                    userClaim[receiver] = userFunds[receiver]*FirstReturn/100;
                    userTransfer[receiver] =userClaim[receiver]-userClaimed[receiver];
                    BATK.transfer(receiver, userTransfer[receiver]);
                    userClaimed[receiver] += userTransfer[receiver];
                    userRemain[receiver] =userFunds[receiver]-userTransfer[receiver];
                } else {
                    if (TotalFlag > totalPeriods) {
                        TotalFlag = totalPeriods;
                    }
                    userClaim[receiver] = userFunds[receiver]*FirstReturn/100;
                    for (uint256 i = 1; i < TotalFlag + 1; i++) {
                        userClaim[receiver] += userFunds[receiver]*periodReturn/10000;
                    }
                    if (userClaim[receiver]>userFunds[receiver]){
                        userClaim[receiver]=userFunds[receiver];
                    }
                    userTransfer[receiver] =userClaim[receiver] -userClaimed[receiver];
                    BATK.transfer(receiver, userTransfer[receiver]);
                    userClaimed[receiver] += userTransfer[receiver];
                    userRemain[receiver] =userFunds[receiver] -userTransfer[receiver];
                }
            }

            emit TokensClaimed(receiver, userClaimed[receiver]);
        }
    }

    function addToAdminlist(address account)
        public
        onlyOwner
        returns (uint256)
    {
        adminlist[account] = 1;
        return adminlist[account];
    }

    function removeFromAdminlist(address account)
        public
        onlyOwner
        returns (uint256)
    {
        adminlist[account] = 0;
        return adminlist[account];
    }

    function Vesting() public {
        if (adminlist[msg.sender] == 1) {
            changeAllowFlag(0);
            for (uint256 i = 0; i < numberOfAccounts; i++) {
                claimTokens(userToken[i]);
            }
        }     
    }

    function removeFromVesting(address receiver) public {
        if (adminlist[msg.sender] == 1) {
            userRemain[receiver] = 0;
        }
    }

    function withdrawTokenForOwner(uint256 amount) public onlyOwner {
        BATK.transfer(owner(), amount);
        emit WithDraw(amount);
    }

    function withdrawBUSDForOwner(address token_address, uint256 amount)
        public
        onlyOwner
    {
        IERC20 busd = IERC20(token_address);
        busd.transfer(owner(), amount);
        emit WithDraw(amount);
    }

    function checkBalanceTokenContract() external view returns (uint256) {
        uint256 balance = BATK.balanceOf(address(this));
        return balance;
    }

    function checkBalanceBUSDContract(address token_address)
        external
        view
        returns (uint256)
    {
        IERC20 busd = IERC20(token_address);
        uint256 balance = busd.balanceOf(address(this));
        return balance;
    }
}
