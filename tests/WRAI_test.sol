// SPDX-License-Identifier: GPL-3.0
    
pragma solidity >=0.4.22 <0.9.0;

// This import is automatically injected by Remix
import "remix_tests.sol"; 
import "remix_accounts.sol";

import "contracts/WrappedToken.sol";
import "contracts/TmpOracleRelayer.sol";
import "contracts/test.sol";
import "contracts/WrappedTokenUser.sol";


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
    address remixAcct;
    
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
        remixAcct = TestsAccounts.getAccount(1);
        
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

    function checkSetup() public {
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
/*
    function testChargesAmountApproved() public logs_gas {
        uint amountApproved = 20*setRedemption;
        wrappedToken.approve(remixAcct, amountApproved);
        bool x = WrappedTokenUser(remixAcct).doTransferFrom(self, remixAcct, amountApproved);
        Assert.equal(x, true, "Test success of doTransferFrom");
        Assert.equal(wrappedToken.balanceOf(self), initialBalanceThis*setRedemption - amountApproved*setRedemption, "Check if successful");
    }
    
    function testFailTransferWithoutApproval() public logs_gas {
        wrappedToken.transfer(user1, 50);
        wrappedToken.transferFrom(user1, self, 1);
    }
*/
    function testFailTransferToContractItself() public logs_gas {
        wrappedToken.transfer(address(wrappedToken), 1);
    }
/*
    function testFailChargeMoreThanApproved() public logs_gas {
        wrappedToken.transfer(user1, 50);
        WrappedTokenUser(user1).doApprove(self, 20);
        wrappedToken.transferFrom(user1, self, 21);
    }
*/
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
        wrappedToken.mint(user1, mintAmount);
        assertEq(wrappedToken.balanceOf(user1), mintAmount*setRedemption);
    }
    /*
    function testFailMintGuyNoAuth() public {
        WrappedTokenUser(user1).doMint(user2, 10);
    }
    
    function testMintGuyAuth() public {
        wrappedToken.addAuthorization(user1);
        WrappedTokenUser(user1).doMint(user2, 10);
    }
    */
    
    
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
    /*
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
    */
    function testTypehash() public {
        Assert.equal(wrappedToken.PERMIT_TYPEHASH(), 0xea2aa0a1be11a07ed86d755c93467f4f82362b452371d1ba94d1715123511acb, "Permit typehash");
    }
    /*
    function testDomain_Separator() public {
        assertEq(wrappedToken.DOMAIN_SEPARATOR(), 0x9685c05f6a00c66a2989a50f30fcbe3c3de111d1b46eae24f24998f456088d0a);
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



// File name has to end with '_test.sol', this file can contain more than one testSuite contracts
contract testSuite {

    /// 'beforeAll' runs before all other tests
    /// More special functions are: 'beforeEach', 'beforeAll', 'afterEach' & 'afterAll'
    function beforeAll() public {
        // <instantiate contract>
        Assert.equal(uint(1), uint(1), "1 should be equal to 1");
    }

    function checkSuccess() public {
        // Use 'Assert' methods: https://remix-ide.readthedocs.io/en/latest/assert_library.html
        Assert.ok(2 == 2, 'should be true');
        Assert.greaterThan(uint(2), uint(1), "2 should be greater than to 1");
        Assert.lesserThan(uint(2), uint(3), "2 should be lesser than to 3");
    }

    function checkSuccess2() public pure returns (bool) {
        // Use the return value (true or false) to test the contract
        return true;
    }
    
    function checkFailure() public {
        Assert.notEqual(uint(1), uint(1), "1 should not be equal to 1");
    }

    /// Custom Transaction Context: https://remix-ide.readthedocs.io/en/latest/unittesting.html#customization
    /// #sender: account-1
    /// #value: 100
    function checkSenderAndValue() public payable {
        // account index varies 0-9, value is in wei
        Assert.equal(msg.sender, TestsAccounts.getAccount(1), "Invalid sender");
        Assert.equal(msg.value, 100, "Invalid value");
    }
    */

}
