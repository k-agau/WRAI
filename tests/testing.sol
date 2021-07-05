pragma solidity 0.6.7;

import "https://github.com/dapphub/ds-test/blob/c0b770c04474db28d43ab4b2fdb891bd21887e9e/src/test.sol";
import "/src/WrappedToken.sol";

contract TokenUser {
    WrappedToken public token;
    
    constructor(WrappedToken _token) public {
        token = _token;
    }
    
    function doUpdateRedemptionPrice() public returns (bool) {
        token.updateRedemptionPrice();
        return true;
    }
    
    function doDeposit(address src, uint unwrappedAmt) public returns (bool) {
        return token.deposit(src, unwrappedAmt);
    }
    
    function doWithdraw(address src, uint wrappedAmt) public returns (bool) {
        return token.withdraw(src, wrappedAmt);
    }
    
    function doBalance(address src) public returns (uint) {
        return token.balance(src);
    }
    
    function doMint(address src, uint amt) public returns (bool) {
        uint curBalance = token.balanceOf(src);
        token.burn(src, curBalance);
        token.deposit(src, amt);
        return true;
    }
 }
 
 abstract contract Hevm {
    function warp(uint256) virtual public;
}
 
 contract WraiTest is DSTest {
    uint constant initialBalanceThis = 1000;
    uint constant initialBalanceCal = 100;
    
    TmpOracleRelayer oracleRelayer;

    Coin            underlyingToken;
    WrappedToken    wrappedToken;
    Hevm            hevm;

    address user1;
    address self;

    uint amount = 2;
    uint fee = 1;
    uint nonce = 0;
    uint deadline = 0;
    address cal = 0x29C76e6aD8f28BB1004902578Fb108c507Be341b;
    address del = 0xdd2d5D3f7f1b35b7A0601D6A00DbB7D44Af58479;
    uint8 v = 27;
    bytes32 r = 0xc7a9f6e53ade2dc3715e69345763b9e6e5734bfe6b40b8ec8e122eb379f07e5b;
    bytes32 s = 0x14cb2f908ca580a74089860a946f56f361d55bdb13b6ce48a998508b0fa5e776;
    bytes32 _r = 0x64e82c811ee5e912c0f97ac1165c73d593654a6fc434a470452d8bca6ec98424;
    bytes32 _s = 0x5a209fe6efcf6e06ec96620fd968d6331f5e02e5db757ea2a58229c9b3c033ed;
    uint8 _v = 28;

    function ray(uint wad) internal pure returns (uint) {
        return wad * 10 ** 9;
    }

    function rad(uint wad) internal pure returns (uint) {
        return wad * 10 ** 27;
    }
    
    function setUp() public {
        hevm = Hevm(0x7109709ECfa91a80626fF3989D68f67F5b1DD12D);
        hevm.warp(604411200);
        oracleRelayer = new TmpOracleRelayer(3);
        

        underlyingToken = createToken();
        
        user1 = address(new TokenUser(wrappedToken));

        underlyingToken.mint(address(this), initialBalanceThis);
        underlyingToken.mint(cal, initialBalanceCal);

        self = address(this);
    }
    
    function createToken() internal returns (Coin) {
        return new Coin("Rai", "RAI", 99);
    }
    
    function createWrappedToken() internal returns (WrappedToken) {
        return new WrappedToken(underlyingToken, oracleRelayer, "Wrapped Rai", "WRAI", 99);
    }
    
    function testSetup() public {
        assertEq(oracleRelayer.redemptionPrice(), 3);
        assertEq(underlyingToken.balanceOf(self), initialBalanceThis);
        assertEq(underlyingToken.balanceOf(cal), initialBalanceCal);
        assertEq(underlyingToken.chainId(), 99);
        assertEq(keccak256(abi.encodePacked(underlyingToken.version())), keccak256(abi.encodePacked("1")));
        underlyingToken.mint(self, 0);
    }
    
    function testSetupPrecondition() public {
        assertEq(underlyingToken.balanceOf(self), initialBalanceThis);
    }
    
    function testDeposit() public {
        uint sentAmount = 250;
        uint totalSupplyOfWrapped = wrappedToken.totalSupply();
        underlyingToken.transfer(user1, sentAmount);
        assertEq(underlyingToken.balanceOf(user1), sentAmount);
        assertEq(underlyingToken.balanceOf(self), initialBalanceThis - sentAmount);
        wrappedToken.deposit(user1, sentAmount);
        assertEq(wrappedToken.balanceOf(user1), sentAmount);
        assertEq(underlyingToken.balanceOf(user1), 0);
        assertEq(wrappedToken.totalSupply(), totalSupplyOfWrapped + sentAmount);
    }
    
    function testWithdraw() public {
        uint depositAmount = 250;
        wrappedToken.withdraw(user1, depositAmount);
        assertEq(wrappedToken.balanceOf(user1), 0);
    }
    
    function testBalance() public {
        uint depositAmount = 250;
        uint redemptionPrice = wrappedToken.conversionFactor();
        wrappedToken.deposit(user1, depositAmount);
        assertEq(wrappedToken.balance(user1), depositAmount * redemptionPrice / rad(1));
    }
    
 }