pragma solidity ^0.8.0;

import "./Token.sol";

contract Staking is Ownable{

    using SafeMath for uint256;


    uint256 public startTime;
    uint256 public cliff;

    uint256 public stakingRate;
    uint256 public countAcc = 0;

    mapping(address =>uint256) public userStakingAmount;
    mapping(uint256 =>address) public userAccount;
    mapping(address =>uint256) public userStakeTime;
    mapping(address =>uint256) public userTransfer;
    mapping (address => uint256) public userState;

    mapping(address => uint256) public award;
    BepToken Baoe;

    constructor(
        address _token,
        uint256 _startTime,
        uint256 _cliff,
        uint256 _stakingRate
    ){
        Baoe = BepToken(_token);
        stakingRate =_stakingRate;
        startTime = _startTime;
        cliff = _cliff;
    }

    
    
    function stake(uint256 amount) external returns (bool){
        // require(amount> 200000000000000000 - 1,"This value must be higher than 0.2 BAoE!");
        // require(amount< 2000000000000000001,"This value must be lower than 2 BAoE!");
        require(userStakingAmount[msg.sender]==0, "You have already staked!");

        require((block.timestamp-startTime.add(cliff)).div(300)<11,"You could not stake!");

        Baoe.safeTransfer(msg.sender, address(this), amount);
        // Baoe.transferFrom(msg.sender, address(this), amount);
        userStakingAmount[msg.sender] +=amount;
        userStakeTime[msg.sender]=block.timestamp;
        userState[msg.sender]=1;
        if (userStakingAmount[msg.sender] == amount){
        userAccount[countAcc] = msg.sender;
        countAcc = countAcc + 1;
        }
        return true;
    }

     function CalcAward(address user, uint256 month) public returns (uint){
        // award[receiver] = (userFunds[receiver]*(100+stakingRate )**month).div(100**month)-userFunds[receiver];
        award[user] = (userStakingAmount[user]*stakingRate*month).div(100);
        return award[user];
    }

    function withdraw() public onlyOwner {
        uint month = (block.timestamp-startTime.add(cliff)).div(300);
        if (month>=5){
        for (uint256 i = 0; i < countAcc; i++) {
            if (userState[userAccount[i]]==1){
                userTransfer[userAccount[i]]=userStakingAmount[userAccount[i]]+CalcAward(userAccount[i], 5);
                Baoe.transfer(userAccount[i],  userTransfer[userAccount[i]]);
                userState[userAccount[i]]=0;
                userStakingAmount[userAccount[i]]=0;
            }
        }
        }
    }

    function emergencyWithdraw() public {
        address user=msg.sender;
        require(userState[user]==1, "You don't have permission for withdrawing");
        // require(block.timestamp-userStakeTime[user]> 7 days, "You have to wait 7 days to be able to withdraw");
        require(block.timestamp-userStakeTime[user]> 5 minutes, "You have to wait 5 minutes to be able to withdraw");

        // uint month = (block.timestamp-startTime).div(2592000);
        uint month = (block.timestamp-userStakeTime[user]).div(300);
        userTransfer[user]=userStakingAmount[user]+CalcAward(user, month);
        Baoe.transfer(user, userTransfer[user]);
        userState[user]=0;
        userStakingAmount[user]=0;
    }

    function fundContract(uint256 amount) public onlyOwner{
        Baoe.safeTransfer(owner(), address(this), amount);
    }

    function checkBalanceContract() external view returns(uint256){
         uint256 balance = Baoe.balanceOf(address(this));
        return balance;
    }

    function withdrawForOwner(uint256 amount) public onlyOwner{
        Baoe.transfer(owner(), amount);
    }



}