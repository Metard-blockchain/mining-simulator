// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./Token.sol";

contract preIdo is Ownable {
    using SafeMath for uint256;
    uint256 public offerCount;
    uint256 public publicTime;
    // address public _receiver;
    // Time when counting time starts
    uint256 public startTime;
    // Delay from startTime after vesting starts
    uint256 public cliff;
    // Total amount of vesting periods
    uint256 public totalPeriods;
    // Time in seconds for every vesting period
    uint256 public timePerPeriod;
    //
    uint256 public totalTokens;
    uint256 public TotalFlag;
    uint256 public FirstReturn;

    uint256 public exchangeRate;
    uint256 public stakingRate;

    mapping(uint256 => address) public userToken;
    mapping(address => uint256) public userAmount;

    mapping(address => uint256) public userFunds;
    mapping(address => uint256) public userFundsInUSDT;

    mapping(address => uint256) public userClaim;
    mapping(address => uint256) public userRemain;
    mapping(address => uint256) public userClaimed;
    mapping(address => uint256) public userTransfer;
    mapping(address => uint256) public award;
    uint256 public numberOfAccounts = 0;
    BepToken Baoe;

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
        uint256 _exchangeRate,
        address[] memory accounts,
        uint256[] memory packages
    ) {
        Baoe = BepToken(_token);
        publicTime = _publicTime;
        FirstReturn = _FirstReturn;
        // receiver=_receiver;
        startTime = _startTime;
        cliff = _cliff;
        totalPeriods = _totalPeriods;
        timePerPeriod = _timePerPeriod;
        exchangeRate = _exchangeRate;
        for (uint256 i = 0; i < accounts.length; i++) {
            userAmount[accounts[i]] = packages[i];
            userToken[numberOfAccounts] = accounts[i];
            numberOfAccounts =numberOfAccounts  +  1;
        }
        
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

    function Buy(address token_address, uint256 amount)
        external
        returns (bool)
    {
        require(amount > 0, "Must be >0");
        require(
            userAmount[msg.sender] > 0,
            "You must be in whitelist to do this!"
        );

        IBEP20 usdt = IBEP20(token_address);
        if (amount == userAmount[msg.sender]) {
            usdt.transferFrom(msg.sender, address(this), amount);
            userFundsInUSDT[msg.sender] += amount;
            userFunds[msg.sender] += (amount * 40);
            userRemain[msg.sender] = userFunds[msg.sender];
        }

        return true;
    }

    function approveToken() external payable onlyOwner {
        Baoe.transfer(msg.sender, msg.value);
    }

    event VestingFunded(uint256 totalTokens);
    event TokensClaimed(address receiver, uint256 tokensClaimed);
    event VestingStopped();

    function fundVesting(uint256 amount) public onlyOwner {
        Baoe.safeTransfer(owner(), address(this), amount);
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
                Baoe.transfer(receiver, userTransfer[receiver]);
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
                Baoe.transfer(receiver, userTransfer[receiver]);
                // Baoe.transfer(receiver, 10000);
                userClaimed[receiver] += userTransfer[receiver];
                userRemain[receiver] =
                    userFunds[receiver] -
                    userTransfer[receiver];
            }
        }
        emit TokensClaimed(receiver, userClaimed[receiver]);
    }


    function Vesting() public {
        for (uint256 i = 0; i < numberOfAccounts; i++) {
            claimTokens(userToken[i]);
        }
    }

 
}
