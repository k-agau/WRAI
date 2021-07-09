pragma solidity 0.6.7;

// Copyright (C) 2017, 2018, 2019 dbrock, rain, mrchico

// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU Affero General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.
//
// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU Affero General Public License for more details.
//
// You should have received a copy of the GNU Affero General Public License
// along with this program.  If not, see <https://www.gnu.org/licenses/>.

import "contracts/Coin.sol";
import "contracts/TmpOracleRelayer.sol";

pragma solidity 0.6.7;

contract WrappedToken {
    // --- Auth ---
    mapping (address => uint256) public authorizedAccounts;
    /**
     * @notice Add auth to an account
     * @param account Account to add auth to
     */
    function addAuthorization(address account) external isAuthorized {
        authorizedAccounts[account] = 1;
        emit AddAuthorization(account);
    }
    /**
     * @notice Remove auth from an account
     * @param account Account to remove auth from
     */
    function removeAuthorization(address account) external isAuthorized {
        authorizedAccounts[account] = 0;
        emit RemoveAuthorization(account);
    }
    /**
    * @notice Checks whether msg.sender can call an authed function
    **/
    modifier isAuthorized {
        require(authorizedAccounts[msg.sender] == 1, "Coin/account-not-authorized");
        _;
    }

    // --- ERC20 Data ---
    // The name of this coin
    string  public name;
    // The symbol of this coin
    string  public symbol;
    // The version of this Coin contract
    string  public version = "1";
    // The number of decimals that this coin has
    uint8   public constant decimals = 18;
    
    // --- Wrapper-Specific Data ---
    // The underlying token
    Coin public underlyingToken;
    // The oracle to be sent to this address
    TmpOracleRelayer public oracleRelayer;
    // Conversion factor for the redemption price.
    uint public redemptionPrice;
    // Public constant for RAY
    uint public constant RAY = 10 ** 27;

    // The id of the chain where this coin was deployed
    uint256 public chainId;
    // The total supply of this coin
    uint256 private _totalSupply;

    // Mapping of coin balances
    mapping (address => uint256)                      private _balances;
    // Mapping of allowances
    mapping (address => mapping (address => uint256)) private _allowances;
    // Mapping of nonces used for permits
    mapping (address => uint256)                      public nonces;

    // --- Events ---
    event AddAuthorization(address account);
    event RemoveAuthorization(address account);
    event Approval(address indexed src, address indexed guy, uint256 wrappedAmount);
    event Transfer(address indexed src, address indexed dst, uint256 wrappedAmount);
    event Deposit(address src, uint amountInUnderlying);
    event Withdraw(address src, uint wrappedAmount);


    // --- Math ---
    function addition(uint256 x, uint256 y) internal pure returns (uint256 z) {
        require((z = x + y) >= x, "Coin/add-overflow");
    }
    function subtract(uint256 x, uint256 y) internal pure returns (uint256 z) {
        require((z = x - y) <= x, "Coin/sub-underflow");
    }
    function multiply(uint256 x, uint256 y) internal pure returns (uint256 z) {
        require(y == 0 || (z = x * y) / y == x, "SAFEEngine/multiply-uint-uint-overflow");
    }
    function divide(uint256 x, uint256 y) internal pure returns (uint256 z) {
            require(y > 0, "WrappedToken/div-uint-uint-overflow");
            z = x / y;
    }

    // --- EIP712 niceties ---
    bytes32 public DOMAIN_SEPARATOR;
    // bytes32 public constant PERMIT_TYPEHASH = keccak256("Permit(address holder,address spender,uint256 nonce,uint256 expiry,bool allowed)");
    bytes32 public constant PERMIT_TYPEHASH = 0xea2aa0a1be11a07ed86d755c93467f4f82362b452371d1ba94d1715123511acb;

    constructor(
        string memory name_,
        string memory symbol_,
        uint256 chainId_,
        Coin underlyingToken_,
        TmpOracleRelayer oracleRelayer_
      ) public {
        authorizedAccounts[msg.sender] = 1;
        name                = name_;
        symbol              = symbol_;
        chainId             = chainId_;
	    underlyingToken     = underlyingToken_;
	    oracleRelayer       = oracleRelayer_;
        authorizedAccounts[address(underlyingToken)] = 1;
        DOMAIN_SEPARATOR    = keccak256(abi.encode(
            keccak256("EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)"),
            keccak256(bytes(name)),
            keccak256(bytes(version)),
            chainId_,
            address(this)
        ));
        
        emit AddAuthorization(msg.sender);
        
    }
    
    // These are the functions specific to the wrapped Token
    
    /**
     * @dev allows the smart contract to mint
     * tokens to a user's account without any additional steps
     * 
     * @param  src The address to which the coins are minted
     * @param  underlyingAmount The amount of tokens to be minted to the given address
     * 
    **/
    function _mint(address src, uint underlyingAmount) private {
        _balances[src] = addition(_balances[src], underlyingAmount);
        _totalSupply = addition(_totalSupply, underlyingAmount);
    }
    
    /**
     * @dev allows the smart contract to burn
     * tokens to a user's account without any additional steps
     * 
     * @param  src The address in which the coins are burned
     * @param  underlyingAmount The amount of underlying tokens to be burned in the given address
     * 
    **/
    function _burn(address src, uint underlyingAmount) private {
        require(_balances[src] >= underlyingAmount);
        _balances[src] = subtract(_balances[src], underlyingAmount);
        _totalSupply = subtract(_totalSupply, underlyingAmount);
    }
    
    /**
     * @dev Retrives the redemption price from the
     * oracle and updates that price to the redemptionPrice variable
     * 
     * Retrieves the current price of Rai
     * 
    **/
    function updateRedemptionPrice() public {
        redemptionPrice = oracleRelayer.redemptionPrice();
    }

    /**
     * @dev Allows users to deposit the underlying token
     * in a 1:1 ratio for the wrapped token. The disparity
     * in price is accounted for in the balanceOf() 
     * and the allowance() functions. New tokens are minted
     * with each deposit.
     * 
     * Users deposit the underlying token for the wrapped token
     * 
     * @param src                   The address of the depositor
     * @param amountInUnderlying    The amount of the underlying token being deposited
     * 
    **/
    function deposit(address src, uint amountInUnderlying) public  returns (bool) {
        require(amountInUnderlying > 0 && underlyingToken.balanceOf(src) >= amountInUnderlying);
        underlyingToken.transferFrom(src, address(this), amountInUnderlying);
        _mint(src, amountInUnderlying);
        
        emit Deposit(src, amountInUnderlying);
        return true;
    }

    /**
     * @dev Allows users to withdraw the underlying token
     * in a 1:1 ratio for the wrapped token. The disparity
     * in price is accounted for in the balanceOf() function.
     * The wrapped tokens are burned with each withdrawal.
     * 
     * Users exchange wrapped token for the underlying token
     * 
     * @param src                   The address of the depositor
     * @param wrappedAmount         The amount of wrapped tokens to be exchanged for the underlying token
     * 
    **/
    function withdraw(address src, uint wrappedAmount) public returns (bool) {
        require(src == msg.sender);
        uint underlyingAmount = convertToUnderlyingAmount(wrappedAmount);
        _burn(src, underlyingAmount);
        underlyingToken.approve(address(underlyingToken), underlyingAmount);
        underlyingToken.transferFrom(address(this), msg.sender, underlyingAmount);
        
        emit Withdraw(src, underlyingAmount);
        
        return true;
    }
    
    /**
     * @notice Returns the true balanace in wrapped tokens based on the redemption price
     * @param src The address of the user whose balance will be returned
     * 
    **/ 
    function balanceOf(address src) public returns (uint256) {
        updateRedemptionPrice();
        return convertToWrappedAmount(_balances[src]);
    }
    
    /**
     * @notice Returns the true allowance in wrapped tokens based on the redemption price
     * @param owner The owner of the funds
     * @param spender The spender of the funds of address owner
     * 
    **/
    function allowance(address owner, address spender) public returns (uint256) {
        updateRedemptionPrice();
        return convertToWrappedAmount(_allowances[owner][spender]);
    }
    
    /**
     * @notice Convers the underlying amount to the wrapped amount
     * @param underlyingAmount The amount in the underlying token to be converted
     * 
    **/
    function convertToWrappedAmount(uint underlyingAmount) public returns (uint256) {
        updateRedemptionPrice();
        return divide(multiply(underlyingAmount, redemptionPrice), RAY);
    }
    
    /**
     * @notice Convers the wrapped amount to the underlying amount
     * @param wrappedAmount The amount in the underlying token to be converted
     * 
    **/
    function convertToUnderlyingAmount(uint wrappedAmount) public returns (uint256) {
        updateRedemptionPrice();
        return divide(multiply(wrappedAmount, RAY), redemptionPrice);
    }
    
    /**
     * @notice returns the total supply
     * 
    **/
    function totalSupply() public returns (uint256) {
        return convertToWrappedAmount(_totalSupply);
    }

    // --- Token ---
    /*
    * @notice Transfer coins to another address
    * @param dst The address to transfer coins to
    * @param amount The amount of coins to transfer
    */
    function transfer(address dst, uint256 wrappedAmount) external returns (bool) {
        return transferFrom(msg.sender, dst, wrappedAmount);
    }
    /*
    * @notice Transfer coins from a source address to a destination address (if allowed)
    * @param src The address from which to transfer coins
    * @param dst The address that will receive the coins
    * @param amount The amount of coins to transfer
    */
    function transferFrom(address src, address dst, uint256 wrappedAmount)
        public returns (bool)
    {
        uint amount = convertToUnderlyingAmount(wrappedAmount);
        require(dst != address(0), "Coin/null-dst");
        require(dst != address(this), "Coin/dst-cannot-be-this-contract");
        require(_balances[src] >= amount, "Coin/insufficient-balance");
        if (src != msg.sender && _allowances[src][msg.sender] != uint256(-1)) {
            require(_allowances[src][msg.sender] >= amount, "Coin/insufficient-allowance");
            _allowances[src][msg.sender] = subtract(_allowances[src][msg.sender], amount);
        }
        _balances[src] = subtract(_balances[src], amount);
        _balances[dst] = addition(_balances[dst], amount);
        emit Transfer(src, dst, amount);
        return true;
    }
    /*
    * @notice Mint new coins
    * @param usr The address for which to mint coins
    * @param amount The amount of coins to mint
    */
    function mint(address usr, uint256 wrappedAmount) external isAuthorized {
        uint amount = convertToUnderlyingAmount(wrappedAmount);
        _balances[usr] = addition(_balances[usr], amount);
        _totalSupply    = addition(_totalSupply, amount);
        emit Transfer(address(0), usr, wrappedAmount);
    }
    /*
    * @notice Burn coins from an address
    * @param usr The address that will have its coins burned
    * @param amount The amount of coins to burn
    */
    function burn(address usr, uint256 wrappedAmount) external {
        uint amount = convertToUnderlyingAmount(wrappedAmount);
        require(_balances[usr] >= amount, "Coin/insufficient-balance");
        if (usr != msg.sender && _allowances[usr][msg.sender] != uint256(-1)) {
            require(_allowances[usr][msg.sender] >= amount, "Coin/insufficient-allowance");
            _allowances[usr][msg.sender] = subtract(_allowances[usr][msg.sender], amount);
        }
        _balances[usr] = subtract(_balances[usr], amount);
        _totalSupply    = subtract(_totalSupply, amount);
        emit Transfer(usr, address(0), wrappedAmount);
    }
    /*
    * @notice Change the transfer/burn allowance that another address has on your behalf
    * @param usr The address whose allowance is changed
    * @param amount The new total allowance for the usr
    */
    function approve(address usr, uint256 wrappedAmount) external returns (bool) {
        uint amount = convertToUnderlyingAmount(wrappedAmount);
        _allowances[msg.sender][usr] = amount;
        emit Approval(msg.sender, usr, wrappedAmount);
        return true;
    }

    // --- Alias ---
    /*
    * @notice Send coins to another address
    * @param usr The address to send tokens to
    * @param amount The amount of coins to send
    */
    function push(address usr, uint256 wrappedAmount) external {
        transferFrom(msg.sender, usr, wrappedAmount);
    }
    /*
    * @notice Transfer coins from another address to your address
    * @param usr The address to take coins from
    * @param amount The amount of coins to take from the usr
    */
    function pull(address usr, uint256 wrappedAmount) external {
        transferFrom(usr, msg.sender, wrappedAmount);
    }
    /*
    * @notice Transfer coins from another address to a destination address (if allowed)
    * @param src The address to transfer coins from
    * @param dst The address to transfer coins to
    * @param amount The amount of coins to transfer
    */
    function move(address src, address dst, uint256 wrappedAmount) external {
        transferFrom(src, dst, wrappedAmount);
    }

    // --- Approve by signature ---
    /*
    * @notice Submit a signed message that modifies an allowance for a specific address
    */
    function permit(
        address holder,
        address spender,
        uint256 nonce,
        uint256 expiry,
        bool allowed,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external
    {
        bytes32 digest =
            keccak256(abi.encodePacked(
                "\x19\x01",
                DOMAIN_SEPARATOR,
                keccak256(abi.encode(PERMIT_TYPEHASH,
                                     holder,
                                     spender,
                                     nonce,
                                     expiry,
                                     allowed))
        ));

        require(holder != address(0), "Coin/invalid-address-0");
        require(holder == ecrecover(digest, v, r, s), "Coin/invalid-permit");
        require(expiry == 0 || now <= expiry, "Coin/permit-expired");
        require(nonce == nonces[holder]++, "Coin/invalid-nonce");
        uint256 wad = allowed ? uint256(-1) : 0;
        _allowances[holder][spender] = wad;
        emit Approval(holder, spender, wad);
    }
}