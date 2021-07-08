pragma solidity 0.6.7;

contract TmpOracleRelayer {
    
    // Public constant ray
    uint public constant RAY = 10 ** 27;
    // The initial redemption price
    uint public _redemptionPrice = RAY;
    // Any value passed to this oracle. Allows for mobility when testing with this mock oracle
    uint val;
    
    constructor(uint _val) public {
        val = _val;
    }
    
    function updateRedemptionPrice(uint val_) public {
        _redemptionPrice = val_;
    }
    
    function redemptionPrice() public returns (uint256) {
        updateRedemptionPrice(val);
        return _redemptionPrice;
    }
}