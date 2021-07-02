pragma solidity 0.6.7;

import "/src/Coin.sol";
import "/src/OracleRelayer.sol";


contract WRAI is Coin {
    
    address raiContractAddress;
    OracleRelayer oracle = new OracleRelayer(raiContractAddress);
    uint conversionFactor;
    
    mapping(address => uint) raiDeposited;
    mapping(address => uint) amountInReturn;
    
    constructor (address _contractAddress) public Coin("Wrapped Rai", "WRAI", 1) {
        raiContractAddress = _contractAddress;
    }
    
    function _rebase() private {
        conversionFactor = oracle.redemptionPrice();
    }
    
    function depositRai(address _token, uint _amount) public payable {
        require(_token == raiContractAddress);
        require(_amount == msg.value);
        
        uint depositAmount = _amount;
        _rebase();
        
        transferFrom(msg.sender, raiContractAddress, depositAmount);
        
        raiDeposited[msg.sender] += depositAmount;
        balanceOf[msg.sender] += depositAmount*conversionFactor;
    }
    
    function withdrawRai(uint _amount) public {
        uint amt = _amount;
        balanceOf[msg.sender] -= amt;
        _rebase();
        uint amtInRai = amt*conversionFactor;
        transferFrom(raiContractAddress, msg.sender, amtInRai);
    }
}