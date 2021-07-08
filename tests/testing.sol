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
    
    address wrappedTokenAddress;
    address underlyingTokenAddress;
    address oracleRelayerAddress;
    
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
    }
        
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
        assertEq(wrappedToken.balanceOf(self), initialBalanceThis*setRedemption - sentAmount*setRedemption);
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
        emit log_named_address("Token", address(wrappedToken));
        emit log_named_address("Me", self);
        emit log_named_address("User 2", user2);
        wrappedToken.approve(user2, 25);
        assertEq(wrappedToken.allowance(self, user2), 25);
    }
    function testChargesAmountApproved() public logs_gas {
        uint amountApproved = 20;
        wrappedToken.approve(user2, amountApproved);
        assertTrue(WrappedTokenUser(user2).doTransferFrom(self, user2, amountApproved));
        assertEq(wrappedToken.balanceOf(self), initialBalanceThis*setRedemption - amountApproved*setRedemption);
    }

    function testFailTransferWithoutApproval() public logs_gas {
        wrappedToken.transfer(user1, 50);
        wrappedToken.transferFrom(user1, self, 1);
    }

    function testFailTransferToContractItself() public logs_gas {
        wrappedToken.transfer(address(wrappedToken), 1);
    }

    function testFailChargeMoreThanApproved() public logs_gas {
        wrappedToken.transfer(user1, 50);
        WrappedTokenUser(user1).doApprove(self, 20);
        wrappedToken.transferFrom(user1, self, 21);
    }
    function testTransferFromSelf() public {
        wrappedToken.transferFrom(self, user1, 50);
        assertEq(wrappedToken.balanceOf(user1), 50*setRedemption);
    }
    function testFailTransferFromSelfNonArbitrarySize() public {
        // you shouldn't be able to evade balance checks by transferring
        // to yourself
        wrappedToken.transferFrom(self, self, wrappedToken.balanceOf(self)*setRedemption + 1*setRedemption);
    }
    function testMintself() public {
        uint mintAmount = 10;
        wrappedToken.mint(address(this), mintAmount);
        assertEq(wrappedToken.balanceOf(self), initialBalanceThis*setRedemption + mintAmount*setRedemption);
    }
    function testMintGuy() public {
        uint mintAmount = 10;
        wrappedToken.mint(user1, mintAmount);
        assertEq(wrappedToken.balanceOf(user1), mintAmount*setRedemption);
    }
    function testFailMintGuyNoAuth() public {
        WrappedTokenUser(user1).doMint(user2, 10);
    }
    function testMintGuyAuth() public {
        wrappedToken.addAuthorization(user1);
        WrappedTokenUser(user1).doMint(user2, 10);
    }
    function testBurn() public {
        uint burnAmount = 10;
        wrappedToken.burn(address(this), burnAmount);
        assertEq(wrappedToken.totalSupply(), initialBalanceThis + initialBalanceCal - burnAmount);
    }
    function testBurnself() public {
        uint burnAmount = 10;
        wrappedToken.burn(address(this), burnAmount);
        assertEq(wrappedToken.balanceOf(self), initialBalanceThis*setRedemption - burnAmount*setRedemption);
    }
    function testBurnGuyWithTrust() public {
        uint burnAmount = 10;
        wrappedToken.transfer(user1, burnAmount);
        assertEq(wrappedToken.balanceOf(user1), burnAmount*setRedemption);

        WrappedTokenUser(user1).doApprove(self);
        wrappedToken.burn(user1, burnAmount);
        assertEq(wrappedToken.balanceOf(user1), 0);
    }
    function testBurnAuth() public {
        wrappedToken.transfer(user1, 10);
        wrappedToken.addAuthorization(user1);
        WrappedTokenUser(user1).doBurn(10);
    }
    function testBurnGuyAuth() public {
        wrappedToken.transfer(user2, 10);
        wrappedToken.addAuthorization(user1);
        WrappedTokenUser(user2).doApprove(user1);
        WrappedTokenUser(user1).doBurn(user2, 10);
    }
    function testFailUntrustedTransferFrom() public {
        assertEq(wrappedToken.allowance(self, user2), 0);
        WrappedTokenUser(user1).doTransferFrom(self, user2, 200);
    }
    function testTrusting() public {
        assertEq(wrappedToken.allowance(self, user2), 0);
        wrappedToken.approve(user2, uint(-1));
        assertEq(wrappedToken.allowance(self, user2), uint(-1));
        wrappedToken.approve(user2, 0);
        assertEq(wrappedToken.allowance(self, user2), 0);
    }
    function testTrustedTransferFrom() public {
        wrappedToken.approve(user1, uint(-1));
        WrappedTokenUser(user1).doTransferFrom(self, user2, 200);
        assertEq(wrappedToken.balanceOf(user2), 200*setRedemption);
    }
    function testApproveWillModifyAllowance() public {
        assertEq(wrappedToken.allowance(self, user1), 0);
        assertEq(wrappedToken.balanceOf(user1), 0);
        wrappedToken.approve(user1, 1000);
        assertEq(wrappedToken.allowance(self, user1), 1000);
        WrappedTokenUser(user1).doTransferFrom(self, user1, 500);
        assertEq(wrappedToken.balanceOf(user1), 500*setRedemption);
        assertEq(wrappedToken.allowance(self, user1), 500);
    }
    function testApproveWillNotModifyAllowance() public {
        assertEq(wrappedToken.allowance(self, user1), 0);
        assertEq(wrappedToken.balanceOf(user1), 0);
        wrappedToken.approve(user1, uint(-1));
        assertEq(wrappedToken.allowance(self, user1), uint(-1));
        WrappedTokenUser(user1).doTransferFrom(self, user1, 1000);
        assertEq(wrappedToken.balanceOf(user1), 1000*setRedemption);
        assertEq(wrappedToken.allowance(self, user1), uint(-1));
    }
    function testCoinAddress() public {
        //The coin address generated by hevm
        //used for signature generation testing
        assertEq(address(wrappedToken), address(0xCaF5d8813B29465413587C30004231645FE1f680));
    }
    function testTypehash() public {
        assertEq(wrappedToken.PERMIT_TYPEHASH(), 0xea2aa0a1be11a07ed86d755c93467f4f82362b452371d1ba94d1715123511acb);
    }
    function testDomain_Separator() public {
        assertEq(wrappedToken.DOMAIN_SEPARATOR(), 0x9685c05f6a00c66a2989a50f30fcbe3c3de111d1b46eae24f24998f456088d0a);
    }

    function testFailPermitWithExpiry() public {
        hevm.warp(now + 2 hours);
        assertEq(now, 604411200 + 2 hours);
        wrappedToken.permit(cal, del, 0, 1, true, _v, _r, _s);
    }
    
    function testFailReplay() public {
        wrappedToken.permit(cal, del, 0, 0, true, v, r, s);
        wrappedToken.permit(cal, del, 0, 0, true, v, r, s);
    }
    
    
    // Wrapper specific tests:
    
    // Transfer all out in users? create new users?
    
    function testUpdateRedemptionPrice() public {
        wrappedToken.updateRedemptionPrice();
        assertEq(wrappedToken.redemptionPrice(), setRedemption);
    }
    
    function testDeposit() public {
        uint depositAmt = 1000;
        uint wrappedDepositAmt = wrappedToken.convertToWrappedAmount(depositAmt);
        assertEq(wrappedToken.balanceOf(user2), 0);
        assertEq(underlyingToken.balanceOf(user2), 0);
        underlyingToken.mint(user2, depositAmt);
        wrappedToken.deposit(user2, depositAmt);
        
        assertEq(wrappedToken.balanceOf(user2), wrappedDepositAmt);
        assertEq(underlyingToken.balanceOf(user2), 0);
    }
    
    function testDepositZero() public {
        uint depositAmt = 1000;
        uint wrappedDepositAmt = wrappedToken.convertToWrappedAmount(depositAmt);
        wrappedToken.deposit(user2, 0);
        assertEq(wrappedToken.balanceOf(user2), wrappedDepositAmt);
    }
    
    function testDepositMoreThanBalance() public {
        uint depositAmt = 1000;
        uint wrappedDepositAmt = wrappedToken.convertToWrappedAmount(depositAmt);
        underlyingToken.mint(user2, 50);
        wrappedToken.deposit(user2, depositAmt);
        assertEq(wrappedToken.balanceOf(user2), wrappedDepositAmt);
    }
    
    function testWithdraw() public {
        uint withdrawAmt = 500;
        uint wrappedWithdrawal = wrappedToken.convertToWrappedAmount(withdrawAmt);
        wrappedToken.withdraw(user2, wrappedWithdrawal);
        assertEq(underlyingToken.balanceOf(user2), 550);
        assertEq(wrappedToken.balanceOf(user2), wrappedToken.convertToWrappedAmount(500));
    }
    
    function testWithdrawZero() public {
        wrappedToken.withdraw(user2, 0);
        assertEq(underlyingToken.balanceOf(user2), 550);
        assertEq(wrappedToken.balanceOf(user2), wrappedToken.convertToWrappedAmount(500));
    } 
    
    function testWithdrawMoreThanBalance() public {
        wrappedToken.withdraw(user2, 10000);
        assertEq(underlyingToken.balanceOf(user2), 550);
        assertEq(wrappedToken.balanceOf(user2), wrappedToken.convertToWrappedAmount(500));
    }
    
    function testBalanceOf() public {
        uint expectedBalance = wrappedToken.convertToWrappedAmount(500);
        assertEq(wrappedToken.balanceOf(user2), expectedBalance);
    }
}