pragma solidity ^0.8.0;
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Context.sol";
import "./libraries/Uniswap.sol";

contract BAoE is Context, ERC20, Ownable {

    mapping(address => uint256) private adminlist;

    address BUSD;
    address addressReceiver;
    address public uniswapV2Pair;
    uint256 public sellFeeRate = 2;
    uint256 public buyFeeRate = 2;
    uint256 public antiBot = 0;
    uint256 percentAmountWhale = 1;

    constructor(address _BUSD, address _addressReceiver) ERC20( "BAoE", "BAoE")  {
        _mint(msg.sender,10**9 * 10**18);
        adminlist[msg.sender] = 1;

        BUSD = _BUSD;
        addressReceiver = _addressReceiver;

        IUniswapV2Router02 _uniswapV2Router = IUniswapV2Router02(
            0x10ED43C718714eb63d5aA57B78B54704E256024E
        );
        uniswapV2Pair = IUniswapV2Factory(_uniswapV2Router.factory()).createPair(address(this), BUSD);
    }


    function _transfer(address sender, address recipient, uint256 amount) internal virtual override {
        uint256 transferFeeRate = _feeCalculation(sender, recipient, amount);
        if (transferFeeRate > 0) {
            uint256 _fee = amount*transferFeeRate/100;
            super._transfer(sender, addressReceiver, _fee);
            amount = amount - _fee;
        }
        super._transfer(sender, recipient, amount);
        emit TransferStatus(sender, recipient, amount);
    }


    modifier onlyAdmin(){
        require(adminlist[_msgSender()]==1,"OnlyAdmin");
        _;
    }

    function isAdmin(address account)public returns (bool){
        return adminlist[account]>0;
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
            require(isAdmin(sender)||isAdmin(recipient),"Anti Bot");
            transferFeeRate = 0;
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
        return transferFeeRate;
    }
    
    event ChangeBuyFeeRate(uint256 rate);
    event ChangeSellFeeRate(uint256 rate);
    event ChangePercentAmountWhale(uint256 rate);
    event ActivateAntiBot(uint256 status);
    event DeactivateAntiBot(uint256 status);
    event AddedAdmin(address account);
    event RemovedAdmin(address account);
    event TransferStatus(address sender, address recipient, uint256 amount);

    function changeBuyFeeRate(uint256 rate) public onlyAdmin {   
        buyFeeRate = rate;
        emit ChangeBuyFeeRate(buyFeeRate);
    }

    function changeSellFeeRate(uint256 rate) public onlyAdmin{
        sellFeeRate = rate;
        emit ChangeSellFeeRate(sellFeeRate);
    }

    function changePercentAmountWhale(uint256 rate) public onlyAdmin{
        percentAmountWhale = rate;
        emit ChangePercentAmountWhale(sellFeeRate);
    } 

    function activateAntiBot() public onlyAdmin{  
        antiBot = 1;
        emit ActivateAntiBot(antiBot);
    }

    function deactivateAntiBot() public onlyAdmin{
        antiBot = 0;
        emit DeactivateAntiBot(antiBot);
    }

    function addToAdminlist(address account) public onlyOwner{
        adminlist[account] = 1;
        emit AddedAdmin(account);
    }

    function removeFromAdminlist(address account) public onlyOwner{
        adminlist[account] = 0;
        emit RemovedAdmin(account);
    }
}
