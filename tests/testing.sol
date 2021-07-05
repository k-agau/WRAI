pragma solidity 0.6.7;

import "remix_tests.sol";
import "/src/WRAI.sol";

contract TokenUser {
    WRAI public token;
    uint public conversionFactorTest;
    
    constructor(WRAI _token, uint val) public {
        token = _token;
        conversionFactorTest = val;
    }
    
    function doUpdateRedemptionPrice() public returns (bool) {
        token.updateRedemptionPrice();
        Assert.equal(token.conversionFactor(), conversionFactorTest, "Differing conversion factors after update");
        return true;
    }
    
    function doDeposit(address src, uint unwrappedAmt) public returns (bool) {
        return token.deposit(src, unwrappedAmt);
    }
    
    function doWithdraw(address src, uint wrappedAmt) public returns (bool) {
        return token.withdraw(src, wrappedAmt);
    }
    
    function doBalance(address src) public returns (bool) {
        Assert.equal(token.balance(src), token.balanceOf(src) * conversionFactorTest, "Incorrect wrapped amount");
        return true;
    }
    
    function doMint(address src, uint amt) public returns (bool) {
        uint curBalance = token.balanceOf(src);
        token.burn(src, curBalance);
        token.deposit(src, amt);
        Assert.equal(token.balanceOf(src), amt, "Mint unsuccessful");
    }
 }
 
 contract WraiTest {
     uint constant initUnderlyingBalance = 100;
     uint constant initBalanceThis = 100;
     
     address underlyingTokenAddress;
     Coin underlyingToken;
     WRAI wrappedToken;
     TmpOracleRelayer tmp = new TmpOracleRelayer(1);
     address caller;
     address user1;
     address user2;
     address self;
     
     function setUp() public {
         wrappedToken = _createToken();
         user1 = address(new TokenUser(wrappedToken, 1));
         user2 = address(new TokenUser(wrappedToken, 1));
         self = address(this);
         underlyingToken = Coin(underlyingTokenAddress);
         wrappedToken.mint(self, initBalanceThis);
         wrappedToken.mint(caller, initUnderlyingBalance);
     }
     
     function _createToken() private returns (WRAI) {
         return new WRAI(underlyingTokenAddress, tmp, "Wrapped Rai", "WRAI", 99);
     }
 }
 
 
 
 
 
 
 
 
 
 
 
 

