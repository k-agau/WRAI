pragma solidity 0.6.7;

import "contracts/WrappedToken.sol";
import "contracts/TmpOracleRelayer.sol";

contract WrappedTokenUser {
    WrappedToken   token;

    constructor(WrappedToken token_) public {
        token = token_;
    }
    
    // Wrapped Token do functions
    
    function doUpdateRedemptionPrice() public returns (uint256) {
        token.updateRedemptionPrice();
        return token.redemptionPrice();
    }
    
    function doDeposit(address src, uint underlyingAmount) public returns (bool) {
        return token.deposit(src, underlyingAmount);
    }
    
    function doWithdraw(address src, uint wrappedAmount) public returns (bool) {
        return token.withdraw(src, wrappedAmount);
    }
    
    function doBalanceOf(address src) public returns (uint256) {
        return token.balanceOf(src);
    }
    
    function doConvertToWrappedAmount(uint underlyingAmount) public returns (uint256) {
        return token.convertToWrappedAmount(underlyingAmount);
    }
    
    function doConvertToUnderlyingAmount(uint wrappedAmount) public returns (uint256) {
        return token.convertToUnderlyingAmount(wrappedAmount);
    }
    
    // Original Coin do functions with the exception of moving doBalanceOf(address who) up to the wrapped section
    function doTransferFrom(address from, address to, uint amount)
        public
        returns (bool)
    {
        return token.transferFrom(from, to, amount);
    }

    function doTransfer(address to, uint amount)
        public
        returns (bool)
    {
        return token.transfer(to, amount);
    }

    function doApprove(address recipient, uint amount)
        public
        returns (bool)
    {
        return token.approve(recipient, amount);
    }

    function doAllowance(address owner, address spender)
        public
        returns (uint)
    {
        return token.allowance(owner, spender);
    }

    function doApprove(address guy)
        public
        returns (bool)
    {
        return token.approve(guy, uint(-1));
    }
    function doMint(uint wad) public {
        token.mint(address(this), wad);
    }
    function doBurn(uint wad) public {
        token.burn(address(this), wad);
    }
    function doMint(address guy, uint wad) public {
        token.mint(guy, wad);
    }
    function doBurn(address guy, uint wad) public {
        token.burn(guy, wad);
    }

}
