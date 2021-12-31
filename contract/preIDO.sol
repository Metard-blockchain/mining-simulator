// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./Token.sol";

contract preIdo is Ownable {
    using SafeMath for uint256;
    uint256 public offerCount;
    uint256 public publicTime;
    // address public _receiver;
    // Time when counting time starts
    // Thời điểm bắt đầu vestingss
    uint256 public startTime;
    // Delay from startTime after vesting starts
    // Khoảng thời gian cliff
    uint256 public cliff;
    // Total amount of vesting periods
    // Tổng lượng token trong giai đoạn vesting
    uint256 public totalPeriods;
    // Time in seconds for every vesting period
    // Thời gian của mỗi giai đoạn vesting (s)
    uint256 public timePerPeriod;
    //
    uint256 public totalTokens=50000*1000000000000000000;
    uint256 public TotalFlag;
    uint256 public FirstReturn;

    uint256 public exchangeRate;
    uint256 public stakingRate;
    uint256 public allow_flag =1;

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
    uint256 public numberOfAccounts = 0;
    MetaHunterToken MetaTK;


    // Define fixed whitelist

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
        uint256 _exchangeRate
    ) {
        MetaTK = MetaHunterToken(_token);
        publicTime = _publicTime;
        FirstReturn = _FirstReturn;
        // receiver=_receiver;
        startTime = _startTime;
        cliff = _cliff;
        totalPeriods = _totalPeriods;
        timePerPeriod = _timePerPeriod;
        exchangeRate = _exchangeRate;
        
    }

    function fromHexChar(uint8 c) public pure returns (uint8) {
        if (bytes1(c) >= bytes1("0") && bytes1(c) <= bytes1("9")) {
            return c - uint8(bytes1("0"));
        }
        if (bytes1(c) >= bytes1("a") && bytes1(c) <= bytes1("f")) {
            return 10 + c - uint8(bytes1("a"));
        }
        if (bytes1(c) >= bytes1("A") && bytes1(c) <= bytes1("F")) {
            return 10 + c - uint8(bytes1("A"));
        }
        return 0;
    }

    function hexStringToAddress(string memory s)
        public
        pure
        returns (bytes memory)
    {
        bytes memory ss = bytes(s);
        require(ss.length % 2 == 0); // length must be even
        bytes memory r = new bytes(ss.length / 2);
        for (uint256 i = 0; i < ss.length / 2; ++i) {
            r[i] = bytes1(
                fromHexChar(uint8(ss[2 * i])) *
                    16 +
                    fromHexChar(uint8(ss[2 * i + 1]))
            );
        }

        return r;
    }

    function toAddress(string calldata s) public pure returns (address) {
        bytes memory _bytes = hexStringToAddress(s);
        require(_bytes.length >= 1 + 20, "toAddress_outOfBounds");
        address tempAddress;

        assembly {
            tempAddress := div(
                mload(add(add(_bytes, 0x20), 1)),
                0x1000000000000000000000000
            )
        }

        return tempAddress;
    }

    function changeAllowFlag(uint256 flag) public onlyOwner returns (uint256) {
        allow_flag = flag;
        return flag;
    }

    function Buy(address token_address, uint256 amount) external returns (bool){
        require(amount >= 100*1000000000000000000, "Must be >= 100");
        require(amount <= 500*1000000000000000000, "Must be <= 500");
        require(totalTokens>0, "No money left!");
        
        require(allow_flag==1, "You don't have permission to buy this token!");
        require(buyState[msg.sender]==0, "You have bought this package!");
        string memory OwnAddress = "0xCCa37838F737e234e1f0305C3cd924fb68Bb48EE";

        IBEP20 usdt = IBEP20(token_address);
        usdt.transferFrom(msg.sender, this.toAddress(OwnAddress), amount);
        userFundsInUSDT[msg.sender] += amount;
        userFunds[msg.sender] += (amount * 40);
        userClaimed[msg.sender] = 0;
        userRemain[msg.sender] = userFunds[msg.sender];
        buyState[msg.sender] =1;
        totalTokens= totalTokens -amount;
        userToken[numberOfAccounts] = msg.sender;
        numberOfAccounts = numberOfAccounts + 1;
        return true;
    }

    function approveToken() external payable onlyOwner { 
        MetaTK.transfer(msg.sender, msg.value);
    }
    event TokensClaimed(address receiver, uint256 tokensClaimed);
    event VestingStopped();
    event WithDraw(uint256 amount);

    function fundVesting(uint256 amount) public onlyOwner {
        MetaTK.safeTransfer(owner(), address(this), amount);
    }

    function claimTokens(address receiver) public {
        // require(msg.sender==receiver, "Only receiver can claim tokens");
        // require(block.timestamp > startTime.add(cliff), "Vesting period hasn't started!");
        require(userRemain[receiver] > 0, "da hoan thanh vesting 0");

        if (block.timestamp > startTime.add(cliff)) {
            TotalFlag = (block.timestamp - startTime.add(cliff)).div(
                timePerPeriod
            );
            if (TotalFlag == 0) {
                userClaim[receiver] = userFunds[receiver].mul(FirstReturn).div(
                    100
                );
                userTransfer[receiver] =
                    userClaim[receiver] -
                    userClaimed[receiver];
                MetaTK.transfer(receiver, userTransfer[receiver]);
                userClaimed[receiver] += userTransfer[receiver];
                userRemain[receiver] =
                    userFunds[receiver] -
                    userTransfer[receiver];
            } else {
                if (TotalFlag > totalPeriods) {
                    TotalFlag = totalPeriods;
                }
                userClaim[receiver] = userFunds[receiver].mul(FirstReturn).div(
                    100
                );
                for (uint256 i = 1; i < TotalFlag + 1; i++) {
                    userClaim[receiver] += userFunds[receiver]
                        .mul(100 - FirstReturn)
                        .div(100)
                        .div(totalPeriods);
                }
                userTransfer[receiver] =
                    userClaim[receiver] -
                    userClaimed[receiver];
                MetaTK.transfer(receiver, userTransfer[receiver]);
                userClaimed[receiver] += userTransfer[receiver];
                userRemain[receiver] =
                    userFunds[receiver] -
                    userTransfer[receiver];
            }
        }
        emit TokensClaimed(receiver, userClaimed[receiver]);
    }

    function Vesting() public onlyOwner{
        changeAllowFlag(0);
        for (uint256 i = 0; i < numberOfAccounts; i++) {
            claimTokens(userToken[i]);
        }
    }

    function withdrawTokenForOwner(uint256 amount) public onlyOwner{
        MetaTK.transfer(owner(), amount);
        emit WithDraw(amount);
    }

    function withdrawBUSDForOwner(address token_address, uint256 amount)  public onlyOwner{
        IBEP20 busd = IBEP20(token_address);
        busd.transfer(owner(), amount);
        emit WithDraw(amount);
    }

    function checkBalanceTokenContract() external view returns(uint256){
         uint256 balance = MetaTK.balanceOf(address(this));
        return balance;
    }

    function checkBalanceBUSDContract(address token_address) external view returns(uint256){
        IBEP20 busd = IBEP20(token_address);
        uint256 balance = busd.balanceOf(address(this));
        return balance;
    }
}
