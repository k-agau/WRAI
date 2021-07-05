pragma solidity 0.6.7;

contract TmpOracleRelayer {
    
    uint public _redemptionPrice;
    
    constructor(uint tmpPrice) public {
        _redemptionPrice = tmpPrice;
    }
    
    function redemptionPrice() public view returns (uint256) {
        return _redemptionPrice;
    }
    
    
}