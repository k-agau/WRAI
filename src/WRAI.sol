pragma solidity>=0.6.7 <0.8.0;

import "/src/Coin.sol";
import "/src/OracleRelayer.sol";


contract WRAI is Coin {
    address public raiContractAddress;
    OracleRelayer public oracle = new OracleRelayer(raiContractAddress);
    uint public conversionFactor;
    
    mapping(address => uint) private raiDeposited;
    mapping(address => uint) private amountInReturn;
    
    constructor (address _contractAddress) public Coin("Wrapped Rai", "WRAI", 1) {
        raiContractAddress = _contractAddress;
    }
    
    function returnContractAddress() public view returns(address) {
        return raiContractAddress;
    }
    
    function returnDepositedAmt() public view returns(uint) {
        uint amt = raiDeposited[msg.sender];
        return amt;
    }
    
    function _rebase() private {
        conversionFactor = oracle.redemptionPrice();
    }
    
    modifier inRai(address _token) {
        require(_token == raiContractAddress, "This contract only accepts RAI");
        _;
    }
    
    modifier isSender(address given) {
        require(given == msg.sender);
        _;
    }
    
    function swapRai(address token, address src, uint amount) public isSender(src) {
        uint balance = Coin(token).balanceOf(address(this));
        require(amount <= balance);
        uint raiDepositedAmount = amount;
        _rebase();
        transferFrom(src, raiContractAddress, raiDepositedAmount);
        uint wrappedRaiAmount = raiDepositedAmount * conversionFactor;
        
        balanceOf[src] += wrappedRaiAmount;
        amountInReturn[src] += wrappedRaiAmount;
        raiDeposited[src] += raiDepositedAmount;
        
    }
    
    function withdrawRai(uint _amount) public {
        uint amt = _amount;
        balanceOf[msg.sender] -= amt;
        _rebase();
        uint amtInRai = amt*conversionFactor;
        transferFrom(raiContractAddress, msg.sender, amtInRai);
    }
    
    function updateBalance() public {
        uint amtDeposited = raiDeposited[msg.sender];
        uint newAmt = amtDeposited * conversionFactor;
        balanceOf[msg.sender] = newAmt;
        
    }
}