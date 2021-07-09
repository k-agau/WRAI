// SPDX-License-Identifier: GPL-3.0
    
pragma solidity >=0.4.22 <0.9.0;

// This import is automatically injected by Remix
import "remix_tests.sol"; 
import "remix_accounts.sol";
import "contracts/WrappedTokenUser.sol";

import "contracts/WrappedToken.sol";
import "contracts/TmpOracleRelayer.sol";
import "contracts/test.sol";

contract WrappedTokenTest is DSTest {
    
    uint constant initialBalanceThis = 1000;
    uint constant initialBalanceCal = 100;
    
    WrappedToken            public wrappedToken;
    Coin                    public underlyingToken;
    TmpOracleRelayer        public oracleRelayer;
    
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
    	oracleRelayer = createOracle();
	    underlyingToken = createUnderlyingToken();
	    wrappedToken = createWrappedToken();
        
        user1 = address(new WrappedTokenUser(wrappedToken));
        user2 = address(new WrappedTokenUser(wrappedToken));
        user3 = address(new WrappedTokenUser(wrappedToken));
        self = address(this);
        
        underlyingToken.addAuthorization(address(wrappedToken));
        wrappedToken.addAuthorization(address(underlyingToken));
        
        setRedemption = 3;
        
        underlyingToken.mint(self, initialBalanceThis);
        underlyingToken.mint(cal, initialBalanceCal);
        wrappedToken.mint(self, initialBalanceThis*setRedemption);
        wrappedToken.mint(cal, initialBalanceCal*setRedemption);
    }
    
    function createOracle() public returns (TmpOracleRelayer) {
        return new TmpOracleRelayer(3);
    }
    
    function createUnderlyingToken() public returns (Coin) {
        return new Coin("Rai", "RAI", 99);
    }
    
    function createWrappedToken() public returns (WrappedToken) {
        return new WrappedToken("Wrapped Rai", "WRAI", 99, underlyingToken, oracleRelayer);
    }
    
    function beforeAll() public {
        Assert.equal(uint(1), uint(1), "Run before all");
    }

    function testSetup() public {
        Assert.equal(oracleRelayer.redemptionPrice(), 3, "Redemption price");
        Assert.equal(underlyingToken.balanceOf(self), initialBalanceThis, "Self underlying init balance");
        Assert.equal(underlyingToken.balanceOf(cal), initialBalanceCal, "Cal underlying init balance");
        Assert.equal(underlyingToken.chainId(), 99, "ChainID");
        Assert.equal(keccak256(abi.encodePacked(underlyingToken.version())), keccak256(abi.encodePacked("1")), "Version");
        underlyingToken.mint(self, 0);
        
        Assert.equal(wrappedToken.balanceOf(self), initialBalanceThis*setRedemption, "Self wrapped init balance");
        Assert.equal(wrappedToken.balanceOf(cal), initialBalanceCal*setRedemption, "Cal wrapped init balance");
        Assert.equal(wrappedToken.chainId(), 99, "ChainID wrapped");
        Assert.equal(keccak256(abi.encodePacked(wrappedToken.version())), keccak256(abi.encodePacked("1")), "Version");
        underlyingToken.mint(self, 0);
    }

    function testSetupPrecondition() public {
        Assert.equal(underlyingToken.balanceOf(self), initialBalanceThis, "underlying balance");
        Assert.equal(wrappedToken.balanceOf(self), initialBalanceThis*setRedemption, "wrapped balance");
    }
    function testTransferCost() public logs_gas {
        wrappedToken.transfer(address(1), 10);
    }
    function testFailTransferToZero() public logs_gas {
        wrappedToken.transfer(address(0), 1);
    }
    function testAllowanceStartsAtZero() public logs_gas {
        Assert.equal(wrappedToken.allowance(user1, user2), 0, "Allowance starts at 0");
    }

    function testValidTransfers() public logs_gas {
        uint sentAmount = 250*setRedemption;
        uint balance = wrappedToken.balanceOf(self);
        emit log_named_address("token11111", address(wrappedToken));
        wrappedToken.transfer(user2, sentAmount);
        Assert.equal(wrappedToken.balanceOf(user2), sentAmount, "Test valid transfers");
        Assert.equal(wrappedToken.balanceOf(self), balance - sentAmount, "Test from contract sent from");
    }
    function testFailWrongAccountTransfers() public logs_gas {
        uint sentAmount = 250*setRedemption;
        wrappedToken.transferFrom(user2, self, sentAmount);
    }
    
    function testFailInsufficientFundsTransfers() public logs_gas {
        uint sentAmount = 250 * setRedemption;
        wrappedToken.transfer(user1, initialBalanceThis - sentAmount);
        wrappedToken.transfer(user2, sentAmount + 1);
    }

    function testApproveSetsAllowance() public logs_gas {
        emit log_named_address("Test", self);
        emit log_named_address("Token", address(wrappedToken));
        emit log_named_address("Me", self);
        emit log_named_address("User 2", user2);
        wrappedToken.approve(user2, 25*setRedemption);
        Assert.equal(wrappedToken.allowance(self, user2), 25*setRedemption, "Allowance Approval");
    }

    function testChargesAmountApproved() public logs_gas {
        uint amountApproved = 60;
        uint prevWrappedBalance = wrappedToken.balanceOf(self);
        wrappedToken.approve(user3, amountApproved);
        bool x = WrappedTokenUser(user3).doTransferFrom(self, user2, amountApproved);
        Assert.equal(x, true, "Test success of doTransferFrom");
        Assert.equal(wrappedToken.balanceOf(self), prevWrappedBalance - amountApproved, "Check if successful");
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
        uint prevBalance = wrappedToken.balanceOf(user1);
        wrappedToken.transferFrom(self, user1, 50*setRedemption);
        Assert.equal(wrappedToken.balanceOf(user1), 50*setRedemption + prevBalance, "Transfer to user1");
    }
    function testFailTransferFromSelfNonArbitrarySize() public {
        // you shouldn't be able to evade balance checks by transferring
        // to yourself
        wrappedToken.transferFrom(self, self, wrappedToken.balanceOf(self) + 1*setRedemption);
    }
    
    function testMintself() public {
        uint mintAmount = 10*setRedemption;
        uint prevBalance = wrappedToken.balanceOf(self);
        wrappedToken.mint(address(this), mintAmount);
        Assert.equal(wrappedToken.balanceOf(self), prevBalance + mintAmount, "mintself");
    }
    function testMintGuy() public {
        uint mintAmount = 10*setRedemption;
        uint prevWrappedBalance = wrappedToken.balanceOf(user1);
        wrappedToken.mint(user1, mintAmount);
        Assert.equal(wrappedToken.balanceOf(user1), prevWrappedBalance + mintAmount, "Mint for user1");
    }
    function testFailMintGuyNoAuth() public {
        WrappedTokenUser(user1).doMint(user2, 10);
    }
    
    function testMintGuyAuth() public {
        wrappedToken.addAuthorization(user1);
        uint prevUserBalance = wrappedToken.balanceOf(user2);
        WrappedTokenUser(user1).doMint(user2, 30);
        Assert.equal(wrappedToken.balanceOf(user2), prevUserBalance + 30, "Mint guy auth");
    }
   
    function testBurn() public {
        uint burnAmount = 10*setRedemption;
        uint tSupply = wrappedToken.totalSupply();
        wrappedToken.burn(address(this), burnAmount);
        Assert.equal(wrappedToken.totalSupply(), tSupply - burnAmount, "Post burn");
    }
    function testBurnself() public {
        uint burnAmount = 10*setRedemption;
        uint prevBalance = wrappedToken.balanceOf(self);
        wrappedToken.burn(address(this), burnAmount);
        Assert.equal(wrappedToken.balanceOf(self), prevBalance - burnAmount, "Burn self");
    }
    
    function testBurnGuyWithTrust() public {
        uint burnAmount = 30;
        uint prevUserBalance = wrappedToken.balanceOf(user1);
        wrappedToken.transfer(user1, burnAmount);
        Assert.equal(wrappedToken.balanceOf(user1), prevUserBalance + burnAmount, "Balance check");

        WrappedTokenUser(user1).doApprove(self);
        wrappedToken.burn(user1, burnAmount);
        Assert.equal(wrappedToken.balanceOf(user1), prevUserBalance, "Post burn");
    }

    function testBurnAuth() public {
        uint prevWrappedBalance = wrappedToken.balanceOf(user1);
        wrappedToken.transfer(user1, 30);
        wrappedToken.addAuthorization(user1);
        WrappedTokenUser(user1).doBurn(30);
        Assert.equal(wrappedToken.balanceOf(user1), prevWrappedBalance, "No change");
    }
    
    function testBurnGuyAuth() public {
        uint prevWrappedBalance = wrappedToken.balanceOf(user2);
        wrappedToken.transfer(user2, 30);
        wrappedToken.addAuthorization(user1);
        WrappedTokenUser(user2).doApprove(user1);
        WrappedTokenUser(user1).doBurn(user2, 30);
        Assert.equal(wrappedToken.balanceOf(user2), prevWrappedBalance, "No balance change");
    }
    function testFailUntrustedTransferFrom() public {
        Assert.equal(wrappedToken.allowance(self, user2), 0, "Check allownace");
        WrappedTokenUser(user1).doTransferFrom(self, user2, 200);
    }
    // Larger numbers experience minor rounding errors but 
    // always err on the side of not being able to withdraw more rai than put in
    // There is also a limit on how much one can allocate an allowance for,
    // Which is not a problem because their is a logical limit on how much one would ever use
    function testTrusting() public {
        wrappedToken.approve(user2, 0);
        Assert.equal(wrappedToken.allowance(self, user2), 0, "No allowance");
        wrappedToken.approve(user2, 1000000);
        Assert.equal(wrappedToken.allowance(self, user2), 999999, "Given allowance");
        wrappedToken.approve(user2, 0);
        Assert.equal(wrappedToken.allowance(self, user2), 0, "Final allownace");
    }
    
    function testTrustedTransferFrom() public {
        uint prevUserBalance = wrappedToken.balanceOf(user2);
        wrappedToken.approve(user1, 1000000);
        WrappedTokenUser(user1).doTransferFrom(self, user2, 600);
        Assert.equal(wrappedToken.balanceOf(user2), prevUserBalance + 600, "After operations");
    }
    function testApproveWillModifyAllowance() public {
        wrappedToken.approve(user1, 0);
        wrappedToken.burn(user1, 429);
        wrappedToken.mint(self, 5000);
        wrappedToken.burn(user1, 48);
        Assert.equal(wrappedToken.allowance(self, user1), 0, "Init allowance check");
        Assert.equal(wrappedToken.balanceOf(user1), 0, "Init balance check");
        wrappedToken.approve(user1, 3000);
        Assert.equal(wrappedToken.allowance(self, user1), 3000, "First allowance");
        WrappedTokenUser(user1).doTransferFrom(self, user1, 1500);
        Assert.equal(wrappedToken.balanceOf(user1), 1500, "Final balance check");
        Assert.equal(wrappedToken.allowance(self, user1), 1500, "Final allowance check");
    }
    function testApproveWillNotModifyAllowance() public {
        wrappedToken.approve(user1, 0);
        wrappedToken.burn(user1, 1500);
        Assert.equal(wrappedToken.allowance(self, user1), 0, "Init allowance check");
        Assert.equal(wrappedToken.balanceOf(user1), 0, "Init balance check");
        wrappedToken.approve(user1, 10000);
        Assert.equal(wrappedToken.allowance(self, user1), 9999, "Mid allowance check");
        WrappedTokenUser(user1).doTransferFrom(self, user1, 1000);
        Assert.equal(wrappedToken.balanceOf(user1), 999, "Final balance check");
        Assert.equal(wrappedToken.allowance(self, user1), 9000, "Final allowance");
    }
    
    function testTypehash() public {
        Assert.equal(wrappedToken.PERMIT_TYPEHASH(), 0xea2aa0a1be11a07ed86d755c93467f4f82362b452371d1ba94d1715123511acb, "Permit typehash");
    }
    
    function testDomain_Separator() public {
        Assert.equal(wrappedToken.DOMAIN_SEPARATOR(), 0x9685c05f6a00c66a2989a50f30fcbe3c3de111d1b46eae24f24998f456088d0a, "Domain separator");
    }
    
    
    function testFailReplay() public {
        wrappedToken.permit(cal, del, 0, 0, true, v, r, s);
        wrappedToken.permit(cal, del, 0, 0, true, v, r, s);
    }
    
    
    // Wrapper specific tests:
    
    function testUpdateRedemptionPrice() public {
        wrappedToken.updateRedemptionPrice();
        Assert.equal(wrappedToken.redemptionPrice(), setRedemption * 10**27, "Check redemption");
    }
    
    function testDeposit() public {
        uint depositAmt = 100;
        uint wrappedDepositAmt = wrappedToken.convertToWrappedAmount(depositAmt);
        underlyingToken.mint(user3, depositAmt);
        uint prevUnderlyingBalance = underlyingToken.balanceOf(user3);
        uint prevWrappedBalance = wrappedToken.balanceOf(user3);
        uint prevTotalSupply = wrappedToken.totalSupply();
        
        WrappedTokenUser(user3).doApproveUnderlying(address(wrappedToken), 10000000);
        
        WrappedTokenUser(user3).doDeposit(user3, depositAmt);
        
        Assert.equal(wrappedToken.balanceOf(user3), prevWrappedBalance + wrappedDepositAmt, "Wrapped balance following deposit");
        Assert.equal(underlyingToken.balanceOf(user3), prevUnderlyingBalance - depositAmt, "Underlying balance following deposit");
        // Plus 1 is due to a rounding error
        Assert.equal(wrappedToken.totalSupply(), prevTotalSupply + wrappedDepositAmt, "Newly minted amount");
    }
    
    function testDepositZero() public {
        uint prevBalance = wrappedToken.balanceOf(self);
        wrappedToken.deposit(self, 0);
        Assert.equal(wrappedToken.balanceOf(self), prevBalance, "Deposit 0");
    }
    
    function testDepositMoreThanBalance() public {
        uint depositAmt = 100000;
        underlyingToken.approve(self, depositAmt);
        // Should even reach below
        wrappedToken.deposit(self, depositAmt);
    }
    
    function testWithdraw() public {
        underlyingToken.mint(address(wrappedToken), 10000000);
        wrappedToken.mint(address(wrappedToken), 1000000);
        wrappedToken.mint(user3, 1000);
        underlyingToken.mint(user3, 1000);
        Assert.equal(wrappedToken.balanceOf(user3), 1299, "Init wrapped balance is 1000");
        Assert.equal(underlyingToken.balanceOf(user3), 1000, "Init underlying balance 0");
        uint prevTotalSupply = wrappedToken.totalSupply();
        
        uint wrappedDepositAmt = wrappedToken.convertToWrappedAmount(100);
        Assert.equal(wrappedDepositAmt, 300, "Wrapped amount");
        
        uint tmp = WrappedTokenUser(user3).doWithdraw(user3, wrappedDepositAmt);
        Assert.equal(tmp, 100, "Underlying amount returned after withdraw");
        Assert.equal(wrappedToken.balanceOf(user3), 999, "Post withdraw wrapped balance");
        Assert.equal(wrappedToken.totalSupply(), prevTotalSupply - 300, "New total supply");
        Assert.equal(underlyingToken.balanceOf(user3), 1000 + wrappedToken.convertToUnderlyingAmount(300), "New underlying balance");
    }
    
    function testWithdrawZero() public {
        uint prevWrappedBalance = wrappedToken.balanceOf(user3);
        uint prevUnderlyingBalance = underlyingToken.balanceOf(user3);
        WrappedTokenUser(user3).doWithdraw(user3, 0);
        Assert.equal(underlyingToken.balanceOf(user3), prevUnderlyingBalance, "Withdraw 0 underlying");
        Assert.equal(wrappedToken.balanceOf(user3), prevWrappedBalance, "Withdraw 0 wrapped");
    } 
    
    function testWithdrawMoreThanBalance() public {
        WrappedTokenUser(user3).doWithdraw(user3, 1000000);
    }
    
    function testNoTrustedCanWithdraw() public {
        WrappedTokenUser(user3).doApprove(self, 10000000);
        wrappedToken.withdraw(user3, 100);
    }
    
    function testBalanceOf() public {
        Assert.equal(wrappedToken.balanceOf(user2), 2190, "Expected balance");
    }
}