pragma solidity ^0.8.0;

import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/token/ERC20/IERC20.sol";
import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/utils/math/SafeMath.sol";
import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/token/ERC20/ERC20.sol";
import "contracts/TmpOracleRelayer.sol";

contract WRAI is IERC20, ERC20 {
    using SafeMath for uint256;
    
    /// @dev The rate of 1 RAI to 1 Wrapped RAI
    uint conversionFactor;
    
    /// @dev A temporary Oracle meant to serve as a means for simple testing before official implementation
    //TmpOracleRelayer tmp;
    
    /// @dev The token address for Rai
    address underlyingToken;
    
    /// @dev The token form of the address for the underlyingToken
    IERC20 rai;
    
    /// @dev A temporary Oracle being used for testing convenience
    TmpOracleRelayer tmpOracle;
    
    mapping (address => uint) public depositedRai;
    
    /// @dev Events after tokens are deposited and withdrawn
    event Deposit(address src, uint amountInRai, uint amountInWrai);
    event Withdraw(address src, uint amountInRai, uint amountInWrai);
    
    constructor(address _underlyingToken, TmpOracleRelayer _tmpOracle) public ERC20("Wrapped Rai", "WRAI") {
        underlyingToken = _underlyingToken;
        rai = IERC20(underlyingToken);
        tmpOracle = _tmpOracle;
    }
    
    function _updateRedemptionPrice() private {
        conversionFactor = tmpOracle.redemptionPrice();
    }
    
    function depositRai(address src, uint amountInRai) public returns (bool) {
        uint amt = amountInRai;
        uint balance = rai.balanceOf(src);
        require(amt <= balance);
        
        rai.transferFrom(src, address(this), amt);
        
        _updateRedemptionPrice();
        uint wrappedAmt = conversionFactor * amt;
        
        depositedRai[src].add(amt);
        _mint(src, wrappedAmt);
        
        emit Deposit(src, amt, wrappedAmt);
        
        return true;
    }
    
    function withdrawRai(address src, uint amountInWrapped) public returns (bool) {
        require(src == msg.sender);
        _updateRedemptionPrice();
        uint balance = balanceOf(src);
        require(balance >= amountInWrapped);
        
        
        
        return true;
    }
    
    function updateBalance(address src) public {
        _updateRedemptionPrice();
        uint deposit = depositedRai[src];
        uint newAmt = deposit*conversionFactor;
        // FINISH
    }
}