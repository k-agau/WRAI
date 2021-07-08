pragma solidity 0.6.7;

import "https://github.com/dapphub/ds-test/blob/c0b770c04474db28d43ab4b2fdb891bd21887e9e/src/test.sol";
import "/contracts/WrappedToken.sol";
import "/contracts/TmpOracleRelayer.sol";

/// Coin.t.sol -- tests for Coin.sol

// Copyright (C) 2015-2020  DappHub, LLC

// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.

// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU General Public License for more details.

// You should have received a copy of the GNU General Public License
// along with this program.  If not, see <http://www.gnu.org/licenses/>.

pragma solidity 0.6.7;

//import "ds-test/test.sol";
//import "ds-token/delegate.sol";

/*
import {Coin} from "../Coin.sol";
import {SAFEEngine} from '../SAFEEngine.sol';
import {AccountingEngine} from '../AccountingEngine.sol';
import {BasicCollateralJoin} from '../BasicTokenAdapters.sol';
import {OracleRelayer} from '../OracleRelayer.sol';
*/
contract Feed {
    bytes32 public priceFeedValue;
    bool public hasValidValue;
    constructor(uint256 initPrice, bool initHas) public {
        priceFeedValue = bytes32(initPrice);
        hasValidValue = initHas;
    }
    
    function getResultWithValidity() external returns (bytes32, bool) {
        return (priceFeedValue, hasValidValue);
    }
}

contract WrappedTokenUser {
    WrappedToken   token;

    constructor(WrappedToken token_) public {
        token = token_;
    }
    
    // Wrapped Token do functions
    
    function doUpdateRedemptionPrice() public returns (uint256) {
        token.updateRedemptionPrice();
        return token.conversionFactor();
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
        view
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

abstract contract Hevm {
    function warp(uint256) virtual public;
}

contract CoinTest is DSTest {
    uint constant initialBalanceThis = 1000;
    uint constant initialBalanceCal = 100;

//    SAFEEngine safeEngine;

//    BasicCollateralJoin collateralA;
//    DSDelegateToken gold;
//    Feed    goldFeed;

    
    WrappedToken            wrappedToken;
    Coin                    underlyingToken;
    TmpOracleRelayer        oracleRelayer;
    
    Hevm    hevm;

    address user1;
    address user2;
    address user3;
    address self;
    
    uint setRedemption;

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
        
        //underlyingToken = Coin(underlyingTokenAddress);
        //oracleRelayer = TmpOracleRelayer(oracleAddress);
        //wrappedToken = WrappedToken(wrappedTokenAddress);
        
        user1 = address(new WrappedTokenUser(wrappedToken));
        user2 = address(new WrappedTokenUser(wrappedToken));
        user3 = address(new WrappedTokenUser(wrappedToken));
        self = address(this);
        
        setRedemption = 3;
        
        underlyingToken.mint(self, initialBalanceThis);
        underlyingToken.mint(cal, initialBalanceThis);
        wrappedToken.mint(self, initialBalanceThis);
        wrappedToken.mint(cal, initialBalanceThis);
        
/*
        safeEngine = new SAFEEngine();
        oracleRelayer = new TmpOracleRelayer(address(safeEngine));
        safeEngine.addAuthorization(address(oracleRelayer));

        gold = new DSDelegateToken("GEM", "GEM");
        gold.mint(1000 ether);
        safeEngine.initializeCollateralType("gold");
        goldFeed = new Feed(1 ether, true);
        oracleRelayer.modifyParameters("gold", "orcl", address(goldFeed));
        oracleRelayer.modifyParameters("gold", "safetyCRatio", 1000000000000000000000000000);
        oracleRelayer.modifyParameters("gold", "liquidationCRatio", 1000000000000000000000000000);
        oracleRelayer.updateCollateralPrice("gold");
        collateralA = new BasicCollateralJoin(address(safeEngine), "gold", address(gold));

        safeEngine.modifyParameters("gold", "debtCeiling", rad(1000 ether));
        safeEngine.modifyParameters("globalDebtCeiling", rad(1000 ether));

        gold.approve(address(collateralA));
        gold.approve(address(safeEngine));

        safeEngine.addAuthorization(address(collateralA));

        collateralA.join(address(this), 1000 ether);

        token = createToken();

        oracleRelayer.addAuthorization(address(token));
        safeEngine.addAuthorization(address(token));

        user1 = address(new TokenUser(token));
        user2 = address(new TokenUser(token));
        user3 = address(new TokenUser(token));

        token.mint(address(this), initialBalanceThis);
        token.mint(cal, initialBalanceCal);

        self = address(this);

        safeEngine.modifySAFECollateralization("gold", self, self, self, 10 ether, 5 ether);
*/
    }
/*
    function tokenCollateral(bytes32 collateralType, address safe) internal view returns (uint) {
        return safeEngine.tokenCollateral(collateralType, safe);
    }
    function lockedCollateral(bytes32 collateralType, address safe) internal view returns (uint) {
        (uint lockedCollateral_, uint generatedDebt_) = safeEngine.safes(collateralType, safe); generatedDebt_;
        return lockedCollateral_;
    }
    function art(bytes32 collateralType, address urn) internal view returns (uint) {
        (uint lockedCollateral_, uint generatedDebt_) = safeEngine.safes(collateralType, urn); lockedCollateral_;
        return generatedDebt_;
    }
    function createToken() internal returns (Coin) {
        return new Coin("Rai", "RAI", 99);
    }
*/
    function testSetup() public {
        assertEq(oracleRelayer.redemptionPrice(), 10 ** 27);
        assertEq(underlyingToken.balanceOf(self), initialBalanceThis);
        assertEq(underlyingToken.balanceOf(cal), initialBalanceCal);
        assertEq(underlyingToken.chainId(), 99);
        assertEq(keccak256(abi.encodePacked(underlyingToken.version())), keccak256(abi.encodePacked("1")));
        underlyingToken.mint(self, 0);
        
        assertEq(wrappedToken.balanceOf(self), initialBalanceThis*setRedemption);
        assertEq(wrappedToken.balanceOf(cal), initialBalanceCal*setRedemption);
        assertEq(wrappedToken.chainId(), 99);
        assertEq(keccak256(abi.encodePacked(underlyingToken.version())), keccak256(abi.encodePacked("1")));
        underlyingToken.mint(self, 0);
        
//        (,,uint safetyPrice,,,) = safeEngine.collateralTypes("gold");
//        assertEq(safetyPrice, ray(1 ether));

    }
    function testSetupPrecondition() public {
        assertEq(underlyingToken.balanceOf(self), initialBalanceThis);
        assertEq(wrappedToken.balanceOf(self), initialBalanceThis*setRedemption);
    }
    function testTransferCost() public logs_gas {
        wrappedToken.transfer(address(1), 10);
    }
    function testFailTransferToZero() public logs_gas {
        wrappedToken.transfer(address(0), 1);
    }
    function testAllowanceStartsAtZero() public logs_gas {
        assertEq(wrappedToken.allowance(user1, user2), 0);
    }
    function testValidTransfers() public logs_gas {
        uint sentAmount = 250;
        emit log_named_address("token11111", address(wrappedToken));
        wrappedToken.transfer(user2, sentAmount);
        assertEq(wrappedToken.balanceOf(user2), sentAmount*setRedemption);
        assertEq(wrappedToken.balanceOf(self), initialBalanceThis - sentAmount);
    }
    function testFailWrongAccountTransfers() public logs_gas {
        uint sentAmount = 250;
        wrappedToken.transferFrom(user2, self, sentAmount);
    }
    function testFailInsufficientFundsTransfers() public logs_gas {
        uint sentAmount = 250;
        wrappedToken.transfer(user1, initialBalanceThis - sentAmount);
        wrappedToken.transfer(user2, sentAmount + 1);
    }
    function testApproveSetsAllowance() public logs_gas {
        emit log_named_address("Test", self);
        emit log_named_address("Token", address(token));
        emit log_named_address("Me", self);
        emit log_named_address("User 2", user2);
        token.approve(user2, 25);
        assertEq(token.allowance(self, user2), 25);
    }
    function testChargesAmountApproved() public logs_gas {
        uint amountApproved = 20;
        token.approve(user2, amountApproved);
        assertTrue(WrappedTokenUser(user2).doTransferFrom(self, user2, amountApproved));
        assertEq(token.balanceOf(self), initialBalanceThis - amountApproved);
    }

    function testFailTransferWithoutApproval() public logs_gas {
        token.transfer(user1, 50);
        token.transferFrom(user1, self, 1);
    }

    function testFailTransferToContractItself() public logs_gas {
        token.transfer(address(token), 1);
    }

    function testFailChargeMoreThanApproved() public logs_gas {
        token.transfer(user1, 50);
        WrappedTokenUser(user1).doApprove(self, 20);
        token.transferFrom(user1, self, 21);
    }
    function testTransferFromSelf() public {
        token.transferFrom(self, user1, 50);
        assertEq(token.balanceOf(user1), 50);
    }
    function testFailTransferFromSelfNonArbitrarySize() public {
        // you shouldn't be able to evade balance checks by transferring
        // to yourself
        token.transferFrom(self, self, token.balanceOf(self) + 1);
    }
    function testMintself() public {
        uint mintAmount = 10;
        token.mint(address(this), mintAmount);
        assertEq(token.balanceOf(self), initialBalanceThis + mintAmount);
    }
    function testMintGuy() public {
        uint mintAmount = 10;
        token.mint(user1, mintAmount);
        assertEq(token.balanceOf(user1), mintAmount);
    }
    function testFailMintGuyNoAuth() public {
        WrappedTokenUser(user1).doMint(user2, 10);
    }
    function testMintGuyAuth() public {
        token.addAuthorization(user1);
        WrappedTokenUser(user1).doMint(user2, 10);
    }
    function testBurn() public {
        uint burnAmount = 10;
        token.burn(address(this), burnAmount);
        assertEq(token.totalSupply(), initialBalanceThis + initialBalanceCal - burnAmount);
    }
    function testBurnself() public {
        uint burnAmount = 10;
        token.burn(address(this), burnAmount);
        assertEq(token.balanceOf(self), initialBalanceThis - burnAmount);
    }
    function testBurnGuyWithTrust() public {
        uint burnAmount = 10;
        token.transfer(user1, burnAmount);
        assertEq(token.balanceOf(user1), burnAmount);

        WrappedTokenUser(user1).doApprove(self);
        token.burn(user1, burnAmount);
        assertEq(token.balanceOf(user1), 0);
    }
    function testBurnAuth() public {
        token.transfer(user1, 10);
        token.addAuthorization(user1);
        WrappedTokenUser(user1).doBurn(10);
    }
    function testBurnGuyAuth() public {
        token.transfer(user2, 10);
        token.addAuthorization(user1);
        WrappedTokenUser(user2).doApprove(user1);
        WrappedTokenUser(user1).doBurn(user2, 10);
    }
    function testFailUntrustedTransferFrom() public {
        assertEq(token.allowance(self, user2), 0);
        WrappedTokenUser(user1).doTransferFrom(self, user2, 200);
    }
    function testTrusting() public {
        assertEq(token.allowance(self, user2), 0);
        token.approve(user2, uint(-1));
        assertEq(token.allowance(self, user2), uint(-1));
        token.approve(user2, 0);
        assertEq(token.allowance(self, user2), 0);
    }
    function testTrustedTransferFrom() public {
        token.approve(user1, uint(-1));
        WrappedTokenUser(user1).doTransferFrom(self, user2, 200);
        assertEq(token.balanceOf(user2), 200);
    }
    function testApproveWillModifyAllowance() public {
        assertEq(token.allowance(self, user1), 0);
        assertEq(token.balanceOf(user1), 0);
        token.approve(user1, 1000);
        assertEq(token.allowance(self, user1), 1000);
        WrappedTokenUser(user1).doTransferFrom(self, user1, 500);
        assertEq(token.balanceOf(user1), 500);
        assertEq(token.allowance(self, user1), 500);
    }
    function testApproveWillNotModifyAllowance() public {
        assertEq(token.allowance(self, user1), 0);
        assertEq(token.balanceOf(user1), 0);
        token.approve(user1, uint(-1));
        assertEq(token.allowance(self, user1), uint(-1));
        WrappedTokenUser(user1).doTransferFrom(self, user1, 1000);
        assertEq(token.balanceOf(user1), 1000);
        assertEq(token.allowance(self, user1), uint(-1));
    }
    function testCoinAddress() public {
        //The coin address generated by hevm
        //used for signature generation testing
        assertEq(address(token), address(0xCaF5d8813B29465413587C30004231645FE1f680));
    }
    function testTypehash() public {
        assertEq(token.PERMIT_TYPEHASH(), 0xea2aa0a1be11a07ed86d755c93467f4f82362b452371d1ba94d1715123511acb);
    }
    function testDomain_Separator() public {
        assertEq(token.DOMAIN_SEPARATOR(), 0x9685c05f6a00c66a2989a50f30fcbe3c3de111d1b46eae24f24998f456088d0a);
    }

    //TODO: remake with v,r,s for coin now that we changed the DOMAIN SEPARATOR because of the dai->coin renaming

    // function testPermit() public {
    //     assertEq(token.nonces(cal), 0);
    //     assertEq(token.allowance(cal, del), 0);
    //     token.permit(cal, del, 0, 0, true, v, r, s);
    //     assertEq(token.allowance(cal, del),uint(-1));
    //     assertEq(token.nonces(cal),1);
    // }

    function testFailPermitAddress0() public {
        v = 0;
        token.permit(address(0), del, 0, 0, true, v, r, s);
    }

    //TODO: remake with _v,_r,_s for coin now that we changed the DOMAIN SEPARATOR because of the dai->coin renaming

    // function testPermitWithExpiry() public {
    //     assertEq(now, 604411200);
    //     token.permit(cal, del, 0, 604411200 + 1 hours, true, _v, _r, _s);
    //     assertEq(token.allowance(cal, del),uint(-1));
    //     assertEq(token.nonces(cal),1);
    // }

    function testFailPermitWithExpiry() public {
        hevm.warp(now + 2 hours);
        assertEq(now, 604411200 + 2 hours);
        token.permit(cal, del, 0, 1, true, _v, _r, _s);
    }
    function testFailReplay() public {
        token.permit(cal, del, 0, 0, true, v, r, s);
        token.permit(cal, del, 0, 0, true, v, r, s);
    }
}

/*
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
    
    address         underlyingTokenAddress;
    address         oracleAddress;
    address         wrappedTokenAddress;
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
        
        underlyingTokenAddress = 0x7Db050d57Fcb5D551e56D39a62aa090eB04c63D2;
        oracleAddress = 0xf11c0F2460A7Fc762C7e5a28436766d254C8DC75;
        wrappedTokenAddress = 0x1BF4F640C92DE92263A62ca38779c41da1e17bCE;
        underlyingToken = Coin(underlyingTokenAddress);
        oracleRelayer = TmpOracleRelayer(oracleAddress);
        wrappedToken = WrappedToken(wrappedTokenAddress);
        
        user1 = address(new TokenUser(wrappedToken));

        underlyingToken.mint(address(this), initialBalanceThis);
        underlyingToken.mint(cal, initialBalanceCal);

        self = address(this);
    }
    
/*    function createToken() internal returns (Coin) {
        return new Coin("Rai", "RAI", 99);
    }
    
    function createWrappedToken() internal returns (WrappedToken) {
        return new WrappedToken(underlyingTokenAddress, oracleAddress, "Wrapped Rai", "WRAI", 99);
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
 */