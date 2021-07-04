pragma solidity 0.6.7;

import "/src/Coin.sol";
import "/contracts/TmpOracleRelayer.sol";

contract WRAI is Coin {
    
    /// @dev The rate of 1 RAI to 1 Wrapped RAI
    uint public conversionFactor;
    
    /// @dev The token address for Rai
    address public underlyingToken;
    
    /// @dev The token form of the address for the underlyingToken
    Coin public immutable rai;
    
    /// @dev A temporary Oracle being used for testing convenience
    TmpOracleRelayer public immutable tmpOracle;
    
    /// @dev Events for after tokens are deposited and withdrawn
    event Deposit(address src, uint amountInRai);
    event Withdraw(address src, uint amountInRai);
    
    /// @dev A constructor that takes in the address of the underlying token and an Oracle
    /// that will also create a new Coin
    constructor(address _underlyingToken, TmpOracleRelayer _tmpOracle, string memory name, string memory symbol, uint _chainId) public Coin(name, symbol, _chainId) {
        underlyingToken = _underlyingToken;
        rai = Coin(underlyingToken);
        tmpOracle = _tmpOracle;
    }
    
    /// @dev Uses the Oracle to update the redemption price
    function updateRedemptionPrice() public {
        conversionFactor = tmpOracle.redemptionPrice();
    }
    
    /**
    * Allows users to deposit Rai in exchange for the wrapped Token, which will be
    * minted into their accounts upon confirmation of the deposit in a 1:1 ratio.
     **/
    function depositRai(address src, uint amountInRai) public returns (bool) {
        uint balance = rai.balanceOf(src);
        require(amountInRai <= balance);
        
        rai.transferFrom(src, address(this), amountInRai);
        _mint(src, amountInRai);
        emit Deposit(src, amountInRai);
        
        return true;
    }
    
    function withdrawRai(address src, uint wrappedAmount) public {
        uint balance = this.balanceOf(src);
        require(wrappedAmount <= balance);
        
        updateRedemptionPrice();
        
        uint unwrappedAmount = wrappedAmount / conversionFactor;
        
        this.burn(src, wrappedAmount);
        
        rai.transferFrom(address(this), msg.sender, unwrappedAmount);
        
        emit Withdraw(src, unwrappedAmount);
    }
    
    function balance(address src) public returns(uint256) {
        updateRedemptionPrice();
        uint updatedAmount = this.balanceOf(src) * conversionFactor;
        return updatedAmount;
    }
    
    function _mint(address src, uint amt) private {
        balanceOf[src] = addition(balanceOf[src], amt);
        totalSupply = addition(totalSupply, amt);
    }
}