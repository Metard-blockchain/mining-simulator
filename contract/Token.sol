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
    address public uniswapV2Pair;
    uint256 public sellFeeRate = 2;
    uint256 public buyFeeRate = 2;
    uint256 public antiBot = 1;

    uint256 percentAmountWhale = 1;

    constructor(address _BUSD, address _addressReceiver) ERC20( "BAoE", "BA")  {
        _name = "BAoE";
        _symbol = "BA";
        _decimals = 18;
        _totalSupply = 10**9 * 10**18;
        _mint(msg.sender, _totalSupply);
        adminlist[msg.sender] = 1;

        BUSD = _BUSD;
        addressReceiver = _addressReceiver;

        IUniswapV2Router02 _uniswapV2Router = IUniswapV2Router02(
            0x9Ac64Cc6e4415144C455BD8E4837Fea55603e5c3
        );

        uniswapV2Pair = IUniswapV2Factory(_uniswapV2Router.factory())
            .createPair(address(this), BUSD);

        emit Transfer(address(0), msg.sender, _totalSupply);
    }


    function transfer(address recipient, uint256 amount)
        public virtual override returns (bool)
    {
        uint256 transferFeeRate = _feeCalculation(_msgSender(), recipient, amount);
        if (transferFeeRate > 0) {
            uint256 _fee = amount*transferFeeRate/100;
            _transfer(_msgSender(), addressReceiver, _fee);
            amount = amount - _fee;
        }
        _transfer(_msgSender(), recipient, amount);
        emit Transfer(_msgSender(), recipient, amount);
        return true;
    }

    modifier onlyAdmin(){
        if (adminlist[msg.sender] == 0){
            revert();
        }
        _;
    }

    function isAdmin(address account)public returns (bool){
        if (adminlist[account]>0)
            return true;
        else{
            return false;
        }
    }
    function _feeCalculation(
        address sender,
        address recipient,
        uint256 amount
    ) internal returns(uint256){
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");

           uint256 transferFeeRate = 0;

        if (antiBot == 1) {
            if(isAdmin(sender) || isAdmin(recipient)) {
                transferFeeRate = 0;         
            }else{
                require(0>1, "Revert transaction");
            }
        }else{
            if(sender == uniswapV2Pair){
                if(isAdmin(recipient)) {
                    transferFeeRate = 0;
                } else{
                    require(amount <= (this.balanceOf(uniswapV2Pair)*percentAmountWhale)/100,"Revert whale transaction");
                    transferFeeRate = buyFeeRate;
                }
                
            } else {
                if(isAdmin(sender)) {
                    transferFeeRate = 0;
                } else {
                    transferFeeRate = sellFeeRate;
                }
            }
        }
    }
    
    event ChangeBuyFeeRate(uint256 rate);
    event ChangeSellFeeRate(uint256 rate);
    event ActivateAntiBot(uint256 status);
    event DeactivateAntiBot(uint256 status);
    event AddedAdmin(address account);
    event RemovedAdmin(address account);

    function changeBuyFeeRate(uint256 rate) public onlyAdmin {   
        buyFeeRate = rate;
        emit ChangeBuyFeeRate(buyFeeRate);
    }

    function changeSellFeeRate(uint256 rate) public onlyAdmin{
        sellFeeRate = rate;
        emit ChangeSellFeeRate(sellFeeRate);
    }

    function activateAntiBot() public onlyAdmin{  
        antiBot = 1;
        emit ActivateAntiBot(antiBot);
    }

    function deactivateAntiBot() public onlyAdmin{
        antiBot = 0;
        emit DeactivateAntiBot(antiBot);
    }

    function addToAdminlist(address account)
        public
        onlyOwner
    {
        adminlist[account] = 1;
        emit AddedAdmin(account);
    }

    function removeFromAdminlist(address account)
        public
        onlyOwner
    {
        adminlist[account] = 0;
        emit RemovedAdmin(account);
    }
}
