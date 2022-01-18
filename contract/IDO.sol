pragma solidity ^0.8.0;

import "./Token.sol";

contract IDO is Ownable {
    uint256 public startTime;
    uint256 public cliff;
    uint256 public totalPeriods;
    uint256 public timePerPeriod;
    uint256 public totalTokens = 100000 * 10**18;
    uint256 public totalFlag;
    uint256 public firstReturn;
    uint256 public periodReturn;
    uint256 public numberOfAccounts = 0;

    mapping(uint256 => address) public userToken;
    mapping(address => uint256) public userFunds;
    mapping(address => uint256) public userFundsInUSDT;
    mapping(address => uint256) public userClaim;
    mapping(address => uint256) public userRemain;
    mapping(address => uint256) public userClaimed;
    mapping(address => uint256) public userTransfer;
    mapping(address => uint256) private adminlist;
   
    BAoEToken BATK;

    // Define fixed adminlist

    constructor(
        address _token,
        uint256 _startTime,
        uint256 _cliff,
        uint256 _totalPeriods,
        uint256 _timePerPeriod,
        uint256 _firstReturn,
        uint256 _periodReturn,
        address[] memory accounts,
        uint256[] memory packages

    ) {
        BATK = BAoEToken(_token);
        firstReturn = _firstReturn;
        periodReturn = _periodReturn;
        startTime = _startTime;
        cliff = _cliff;
        totalPeriods = _totalPeriods;
        timePerPeriod = _timePerPeriod;
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

    modifier onlyAdmin(){
        require(adminlist[_msgSender()]==1,"OnlyAdmin");
        _;
    }

    event ChangeAllowFlag(uint256 flag);
    event TokensClaimed(address receiver, uint256 tokensClaimed);
    event WithDraw(uint256 amount);
    event VestingStopped();
    event AddedAdmin (address account);
    event RemovedAdmin (address account);
    event CheckBalance(uint256 amount);
    

    function claimTokens(address receiver) internal onlyAdmin{
        if (userRemain[receiver] > 0) {
            if (block.timestamp > startTime+cliff) {
                totalFlag = (block.timestamp-(startTime+cliff))/timePerPeriod;
                if (totalFlag == 0) {
                    userClaim[receiver] = userFunds[receiver]*firstReturn/100;
                    userTransfer[receiver] =userClaim[receiver]-userClaimed[receiver];
                    BATK.transfer(receiver, userTransfer[receiver]);
                    userClaimed[receiver] += userTransfer[receiver];
                    userRemain[receiver] =userFunds[receiver]-userTransfer[receiver];
                } else {
                    if (totalFlag > totalPeriods) {
                        totalFlag = totalPeriods;
                    }
                    userClaim[receiver] = userFunds[receiver]*firstReturn/100;
                    for (uint256 i = 1; i < totalFlag + 1; i++) {
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
    
    function addToAdminlist(address account) public onlyOwner{
        adminlist[account] = 1;
        emit AddedAdmin(account);
    }

    function removeFromAdminlist(address account) public onlyOwner{
        adminlist[account] = 0;
        emit RemovedAdmin(account);
    }

    function Vesting() public onlyAdmin {
        for (uint256 i = 0; i < numberOfAccounts; i++) {
        claimTokens(userToken[i]);
        }
        emit VestingStopped();
    }

    function removeFromVesting(address receiver) public onlyAdmin{
        userRemain[receiver] = 0;
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


    function checkBalanceOfToken() external {
        uint256 balance = BATK.balanceOf(address(this));
        emit CheckBalance(balance);
    }

    function checkBalanceOfBUSD(address token_address) external{
        IERC20 busd = IERC20(token_address);
        uint256 balance = busd.balanceOf(address(this));
        emit CheckBalance(balance);
    }
}
