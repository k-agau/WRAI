pragma solidity ^0.8.0;

contract TmpOracleRelayer {
    
    uint _redemptionPrice;
    
    constructor(uint tmpPrice) public {
        _redemptionPrice = tmpPrice;
    }
    
    function redemptionPrice() public returns (uint256) {
        return _redemptionPrice;
    }
    
    
}