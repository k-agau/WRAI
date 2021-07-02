// SPDX-License-Identifier: GPL-3.0
    
pragma solidity >=0.4.22 <0.9.0;

// This import is automatically injected by Remix
import "remix_tests.sol"; 

// This import is required to use custom transaction context
// Although it may fail compilation in 'Solidity Compiler' plugin
// But it will work fine in 'Solidity Unit Testing' plugin
import "remix_accounts.sol";
import "../src/WRAI.sol";

// File name has to end with '_test.sol', this file can contain more than one testSuite contracts
contract testSuite {
    
    WRAI tmp;

    /// 'beforeAll' runs before all other tests
    /// More special functions are: 'beforeEach', 'beforeAll', 'afterEach' & 'afterAll'
    function beforeAll() public {
       tmp = new WRAI(msg.sender);
       address contractAddress = tmp.returnContractAddress();
        Assert.equal(contractAddress, msg.sender, "Constructor failure");
    }
    
    /*
    function checkOtherTokenDepositRai() public {
        tmp.swapRai(0x495f947276749Ce646f68AC8c248420045cb7b5e, msg.sender, 100);
    }
    */
    
    function checkDepositRai() public {
        bytes memory _data = abi.encodeWithSignature("tmp.swapRai(msg.sender, msg.sender, 10)");
        uint amtDeposited = tmp.returnDepositedAmt();
        Assert.equal(amtDeposited, 10, "Deposit Failure");
    }
    
    
    
}