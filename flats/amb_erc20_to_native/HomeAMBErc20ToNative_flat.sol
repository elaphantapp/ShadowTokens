
// File: contracts/upgradeability/EternalStorage.sol

pragma solidity 0.4.24;

/**
 * @title EternalStorage
 * @dev This contract holds all the necessary state variables to carry out the storage of any contract.
 */
contract EternalStorage {
    mapping(bytes32 => uint256) internal uintStorage;
    mapping(bytes32 => string) internal stringStorage;
    mapping(bytes32 => address) internal addressStorage;
    mapping(bytes32 => bytes) internal bytesStorage;
    mapping(bytes32 => bool) internal boolStorage;
    mapping(bytes32 => int256) internal intStorage;

}

// File: contracts/upgradeable_contracts/Initializable.sol

pragma solidity 0.4.24;


contract Initializable is EternalStorage {
    bytes32 internal constant INITIALIZED = 0x0a6f646cd611241d8073675e00d1a1ff700fbf1b53fcf473de56d1e6e4b714ba; // keccak256(abi.encodePacked("isInitialized"))

    function setInitialize() internal {
        boolStorage[INITIALIZED] = true;
    }

    function isInitialized() public view returns (bool) {
        return boolStorage[INITIALIZED];
    }
}

// File: contracts/interfaces/IUpgradeabilityOwnerStorage.sol

pragma solidity 0.4.24;

interface IUpgradeabilityOwnerStorage {
    function upgradeabilityOwner() external view returns (address);
}

// File: contracts/upgradeable_contracts/Upgradeable.sol

pragma solidity 0.4.24;


contract Upgradeable {
    // Avoid using onlyUpgradeabilityOwner name to prevent issues with implementation from proxy contract
    modifier onlyIfUpgradeabilityOwner() {
        require(msg.sender == IUpgradeabilityOwnerStorage(this).upgradeabilityOwner());
        /* solcov ignore next */
        _;
    }
}

// File: openzeppelin-solidity/contracts/token/ERC20/ERC20Basic.sol

pragma solidity ^0.4.24;


/**
 * @title ERC20Basic
 * @dev Simpler version of ERC20 interface
 * See https://github.com/ethereum/EIPs/issues/179
 */
contract ERC20Basic {
  function totalSupply() public view returns (uint256);
  function balanceOf(address _who) public view returns (uint256);
  function transfer(address _to, uint256 _value) public returns (bool);
  event Transfer(address indexed from, address indexed to, uint256 value);
}

// File: openzeppelin-solidity/contracts/token/ERC20/ERC20.sol

pragma solidity ^0.4.24;



/**
 * @title ERC20 interface
 * @dev see https://github.com/ethereum/EIPs/issues/20
 */
contract ERC20 is ERC20Basic {
  function allowance(address _owner, address _spender)
    public view returns (uint256);

  function transferFrom(address _from, address _to, uint256 _value)
    public returns (bool);

  function approve(address _spender, uint256 _value) public returns (bool);
  event Approval(
    address indexed owner,
    address indexed spender,
    uint256 value
  );
}

// File: contracts/upgradeable_contracts/Sacrifice.sol

pragma solidity 0.4.24;

contract Sacrifice {
    constructor(address _recipient) public payable {
        selfdestruct(_recipient);
    }
}

// File: contracts/libraries/Address.sol

pragma solidity 0.4.24;


/**
 * @title Address
 * @dev Helper methods for Address type.
 */
library Address {
    /**
    * @dev Try to send native tokens to the address. If it fails, it will force the transfer by creating a selfdestruct contract
    * @param _receiver address that will receive the native tokens
    * @param _value the amount of native tokens to send
    */
    function safeSendValue(address _receiver, uint256 _value) internal {
        if (!_receiver.send(_value)) {
            (new Sacrifice).value(_value)(_receiver);
        }
    }
}

// File: contracts/upgradeable_contracts/Claimable.sol

pragma solidity 0.4.24;



contract Claimable {
    bytes4 internal constant TRANSFER = 0xa9059cbb; // transfer(address,uint256)

    modifier validAddress(address _to) {
        require(_to != address(0));
        /* solcov ignore next */
        _;
    }

    function claimValues(address _token, address _to) internal {
        if (_token == address(0)) {
            claimNativeCoins(_to);
        } else {
            claimErc20Tokens(_token, _to);
        }
    }

    function claimNativeCoins(address _to) internal {
        uint256 value = address(this).balance;
        Address.safeSendValue(_to, value);
    }

    function claimErc20Tokens(address _token, address _to) internal {
        ERC20Basic token = ERC20Basic(_token);
        uint256 balance = token.balanceOf(this);
        safeTransfer(_token, _to, balance);
    }

    function safeTransfer(address _token, address _to, uint256 _value) internal {
        bytes memory returnData;
        bool returnDataResult;
        bytes memory callData = abi.encodeWithSelector(TRANSFER, _to, _value);
        assembly {
            let result := call(gas, _token, 0x0, add(callData, 0x20), mload(callData), 0, 32)
            returnData := mload(0)
            returnDataResult := mload(0)

            switch result
                case 0 {
                    revert(0, 0)
                }
        }

        // Return data is optional
        if (returnData.length > 0) {
            require(returnDataResult);
        }
    }
}

// File: contracts/upgradeable_contracts/VersionableBridge.sol

pragma solidity 0.4.24;

contract VersionableBridge {
    function getBridgeInterfacesVersion() external pure returns (uint64 major, uint64 minor, uint64 patch) {
        return (5, 1, 0);
    }

    /* solcov ignore next */
    function getBridgeMode() external pure returns (bytes4);
}

// File: contracts/upgradeable_contracts/Ownable.sol

pragma solidity 0.4.24;



/**
 * @title Ownable
 * @dev This contract has an owner address providing basic authorization control
 */
contract Ownable is EternalStorage {
    bytes4 internal constant UPGRADEABILITY_OWNER = 0x6fde8202; // upgradeabilityOwner()

    /**
    * @dev Event to show ownership has been transferred
    * @param previousOwner representing the address of the previous owner
    * @param newOwner representing the address of the new owner
    */
    event OwnershipTransferred(address previousOwner, address newOwner);

    /**
    * @dev Throws if called by any account other than the owner.
    */
    modifier onlyOwner() {
        require(msg.sender == owner());
        /* solcov ignore next */
        _;
    }

    /**
    * @dev Throws if called by any account other than contract itself or owner.
    */
    modifier onlyRelevantSender() {
        // proxy owner if used through proxy, address(0) otherwise
        require(
            !address(this).call(abi.encodeWithSelector(UPGRADEABILITY_OWNER)) || // covers usage without calling through storage proxy
                msg.sender == IUpgradeabilityOwnerStorage(this).upgradeabilityOwner() || // covers usage through regular proxy calls
                msg.sender == address(this) // covers calls through upgradeAndCall proxy method
        );
        /* solcov ignore next */
        _;
    }

    bytes32 internal constant OWNER = 0x02016836a56b71f0d02689e69e326f4f4c1b9057164ef592671cf0d37c8040c0; // keccak256(abi.encodePacked("owner"))

    /**
    * @dev Tells the address of the owner
    * @return the address of the owner
    */
    function owner() public view returns (address) {
        return addressStorage[OWNER];
    }

    /**
    * @dev Allows the current owner to transfer control of the contract to a newOwner.
    * @param newOwner the address to transfer ownership to.
    */
    function transferOwnership(address newOwner) external onlyOwner {
        require(newOwner != address(0));
        setOwner(newOwner);
    }

    /**
    * @dev Sets a new owner address
    */
    function setOwner(address newOwner) internal {
        emit OwnershipTransferred(owner(), newOwner);
        addressStorage[OWNER] = newOwner;
    }
}

// File: contracts/interfaces/IAMB.sol

pragma solidity 0.4.24;

interface IAMB {
    function messageSender() external view returns (address);
    function maxGasPerTx() external view returns (uint256);
    function transactionHash() external view returns (bytes32);
    function messageId() external view returns (bytes32);
    function messageSourceChainId() external view returns (bytes32);
    function messageCallStatus(bytes32 _messageId) external view returns (bool);
    function failedMessageDataHash(bytes32 _messageId) external view returns (bytes32);
    function failedMessageReceiver(bytes32 _messageId) external view returns (address);
    function failedMessageSender(bytes32 _messageId) external view returns (address);
    function requireToPassMessage(address _contract, bytes _data, uint256 _gas) external returns (bytes32);
    function sourceChainId() external view returns (uint256);
    function destinationChainId() external view returns (uint256);
}

// File: contracts/libraries/Bytes.sol

pragma solidity 0.4.24;

/**
 * @title Bytes
 * @dev Helper methods to transform bytes to other solidity types.
 */
library Bytes {
    /**
    * @dev Converts bytes array to bytes32.
    * Truncates bytes array if its size is more than 32 bytes.
    * NOTE: This function does not perform any checks on the received parameter.
    * Make sure that the _bytes argument has a correct length, not less than 32 bytes.
    * A case when _bytes has length less than 32 will lead to the undefined behaviour,
    * since assembly will read data from memory that is not related to the _bytes argument.
    * @param _bytes to be converted to bytes32 type
    * @return bytes32 type of the firsts 32 bytes array in parameter.
    */
    function bytesToBytes32(bytes _bytes) internal pure returns (bytes32 result) {
        assembly {
            result := mload(add(_bytes, 32))
        }
    }

    /**
    * @dev Truncate bytes array if its size is more than 20 bytes.
    * NOTE: Similar to the bytesToBytes32 function, make sure that _bytes is not shorter than 20 bytes.
    * @param _bytes to be converted to address type
    * @return address included in the firsts 20 bytes of the bytes array in parameter.
    */
    function bytesToAddress(bytes _bytes) internal pure returns (address addr) {
        assembly {
            addr := mload(add(_bytes, 20))
        }
    }
}

// File: openzeppelin-solidity/contracts/AddressUtils.sol

pragma solidity ^0.4.24;


/**
 * Utility library of inline functions on addresses
 */
library AddressUtils {

  /**
   * Returns whether the target address is a contract
   * @dev This function will return false if invoked during the constructor of a contract,
   * as the code is not actually created until after the constructor finishes.
   * @param _addr address to check
   * @return whether the target address is a contract
   */
  function isContract(address _addr) internal view returns (bool) {
    uint256 size;
    // XXX Currently there is no better way to check if there is a contract in an address
    // than to check the size of the code at that address.
    // See https://ethereum.stackexchange.com/a/14016/36603
    // for more details about how this works.
    // TODO Check this again before the Serenity release, because all addresses will be
    // contracts then.
    // solium-disable-next-line security/no-inline-assembly
    assembly { size := extcodesize(_addr) }
    return size > 0;
  }

}

// File: contracts/upgradeable_contracts/BasicAMBMediator.sol

pragma solidity 0.4.24;





/**
* @title BasicAMBMediator
* @dev Basic storage and methods needed by mediators to interact with AMB bridge.
*/
contract BasicAMBMediator is Ownable {
    bytes32 internal constant BRIDGE_CONTRACT = 0x811bbb11e8899da471f0e69a3ed55090fc90215227fc5fb1cb0d6e962ea7b74f; // keccak256(abi.encodePacked("bridgeContract"))
    bytes32 internal constant MEDIATOR_CONTRACT = 0x98aa806e31e94a687a31c65769cb99670064dd7f5a87526da075c5fb4eab9880; // keccak256(abi.encodePacked("mediatorContract"))
    bytes32 internal constant REQUEST_GAS_LIMIT = 0x2dfd6c9f781bb6bbb5369c114e949b69ebb440ef3d4dd6b2836225eb1dc3a2be; // keccak256(abi.encodePacked("requestGasLimit"))

    /**
    * @dev Throws if caller on the other side is not an associated mediator.
    */
    modifier onlyMediator {
        require(msg.sender == address(bridgeContract()));
        require(messageSender() == mediatorContractOnOtherSide());
        _;
    }

    /**
    * @dev Sets the AMB bridge contract address. Only the owner can call this method.
    * @param _bridgeContract the address of the bridge contract.
    */
    function setBridgeContract(address _bridgeContract) external onlyOwner {
        _setBridgeContract(_bridgeContract);
    }

    /**
    * @dev Sets the mediator contract address from the other network. Only the owner can call this method.
    * @param _mediatorContract the address of the mediator contract.
    */
    function setMediatorContractOnOtherSide(address _mediatorContract) external onlyOwner {
        _setMediatorContractOnOtherSide(_mediatorContract);
    }

    /**
    * @dev Sets the gas limit to be used in the message execution by the AMB bridge on the other network.
    * This value can't exceed the parameter maxGasPerTx defined on the AMB bridge.
    * Only the owner can call this method.
    * @param _requestGasLimit the gas limit for the message execution.
    */
    function setRequestGasLimit(uint256 _requestGasLimit) external onlyOwner {
        _setRequestGasLimit(_requestGasLimit);
    }

    /**
    * @dev Get the AMB interface for the bridge contract address
    * @return AMB interface for the bridge contract address
    */
    function bridgeContract() public view returns (IAMB) {
        return IAMB(addressStorage[BRIDGE_CONTRACT]);
    }

    /**
    * @dev Tells the mediator contract address from the other network.
    * @return the address of the mediator contract.
    */
    function mediatorContractOnOtherSide() public view returns (address) {
        return addressStorage[MEDIATOR_CONTRACT];
    }

    /**
    * @dev Tells the gas limit to be used in the message execution by the AMB bridge on the other network.
    * @return the gas limit for the message execution.
    */
    function requestGasLimit() public view returns (uint256) {
        return uintStorage[REQUEST_GAS_LIMIT];
    }

    /**
    * @dev Stores a valid AMB bridge contract address.
    * @param _bridgeContract the address of the bridge contract.
    */
    function _setBridgeContract(address _bridgeContract) internal {
        require(AddressUtils.isContract(_bridgeContract));
        addressStorage[BRIDGE_CONTRACT] = _bridgeContract;
    }

    /**
    * @dev Stores the mediator contract address from the other network.
    * @param _mediatorContract the address of the mediator contract.
    */
    function _setMediatorContractOnOtherSide(address _mediatorContract) internal {
        addressStorage[MEDIATOR_CONTRACT] = _mediatorContract;
    }

    /**
    * @dev Stores the gas limit to be used in the message execution by the AMB bridge on the other network.
    * @param _requestGasLimit the gas limit for the message execution.
    */
    function _setRequestGasLimit(uint256 _requestGasLimit) internal {
        require(_requestGasLimit <= maxGasPerTx());
        uintStorage[REQUEST_GAS_LIMIT] = _requestGasLimit;
    }

    /**
    * @dev Tells the address that generated the message on the other network that is currently being executed by
    * the AMB bridge.
    * @return the address of the message sender.
    */
    function messageSender() internal view returns (address) {
        return bridgeContract().messageSender();
    }

    /**
    * @dev Tells the id of the message originated on the other network.
    * @return the id of the message originated on the other network.
    */
    function messageId() internal view returns (bytes32) {
        return bridgeContract().messageId();
    }

    /**
    * @dev Tells the maximum gas limit that a message can use on its execution by the AMB bridge on the other network.
    * @return the maximum gas limit value.
    */
    function maxGasPerTx() internal view returns (uint256) {
        return bridgeContract().maxGasPerTx();
    }
}

// File: openzeppelin-solidity/contracts/math/SafeMath.sol

pragma solidity ^0.4.24;


/**
 * @title SafeMath
 * @dev Math operations with safety checks that throw on error
 */
library SafeMath {

  /**
  * @dev Multiplies two numbers, throws on overflow.
  */
  function mul(uint256 _a, uint256 _b) internal pure returns (uint256 c) {
    // Gas optimization: this is cheaper than asserting 'a' not being zero, but the
    // benefit is lost if 'b' is also tested.
    // See: https://github.com/OpenZeppelin/openzeppelin-solidity/pull/522
    if (_a == 0) {
      return 0;
    }

    c = _a * _b;
    assert(c / _a == _b);
    return c;
  }

  /**
  * @dev Integer division of two numbers, truncating the quotient.
  */
  function div(uint256 _a, uint256 _b) internal pure returns (uint256) {
    // assert(_b > 0); // Solidity automatically throws when dividing by 0
    // uint256 c = _a / _b;
    // assert(_a == _b * c + _a % _b); // There is no case in which this doesn't hold
    return _a / _b;
  }

  /**
  * @dev Subtracts two numbers, throws on overflow (i.e. if subtrahend is greater than minuend).
  */
  function sub(uint256 _a, uint256 _b) internal pure returns (uint256) {
    assert(_b <= _a);
    return _a - _b;
  }

  /**
  * @dev Adds two numbers, throws on overflow.
  */
  function add(uint256 _a, uint256 _b) internal pure returns (uint256 c) {
    c = _a + _b;
    assert(c >= _a);
    return c;
  }
}

// File: contracts/upgradeable_contracts/DecimalShiftBridge.sol

pragma solidity 0.4.24;



contract DecimalShiftBridge is EternalStorage {
    using SafeMath for uint256;

    bytes32 internal constant DECIMAL_SHIFT = 0x1e8ecaafaddea96ed9ac6d2642dcdfe1bebe58a930b1085842d8fc122b371ee5; // keccak256(abi.encodePacked("decimalShift"))

    /**
    * @dev Internal function for setting the decimal shift for bridge operations.
    * Decimal shift can be positive, negative, or equal to zero.
    * It has the following meaning: N tokens in the foreign chain are equivalent to N * pow(10, shift) tokens on the home side.
    * @param _shift new value of decimal shift.
    */
    function _setDecimalShift(int256 _shift) internal {
        // since 1 wei * 10**77 > 2**255, it does not make any sense to use higher values
        require(_shift > -77 && _shift < 77);
        uintStorage[DECIMAL_SHIFT] = uint256(_shift);
    }

    /**
    * @dev Returns the value of foreign-to-home decimal shift.
    * @return decimal shift.
    */
    function decimalShift() public view returns (int256) {
        return int256(uintStorage[DECIMAL_SHIFT]);
    }

    /**
    * @dev Converts the amount of home tokens into the equivalent amount of foreign tokens.
    * @param _value amount of home tokens.
    * @return equivalent amount of foreign tokens.
    */
    function _unshiftValue(uint256 _value) internal view returns (uint256) {
        return _shiftUint(_value, -decimalShift());
    }

    /**
    * @dev Converts the amount of foreign tokens into the equivalent amount of home tokens.
    * @param _value amount of foreign tokens.
    * @return equivalent amount of home tokens.
    */
    function _shiftValue(uint256 _value) internal view returns (uint256) {
        return _shiftUint(_value, decimalShift());
    }

    /**
    * @dev Calculates _value * pow(10, _shift).
    * @param _value amount of tokens.
    * @param _shift decimal shift to apply.
    * @return shifted value.
    */
    function _shiftUint(uint256 _value, int256 _shift) private pure returns (uint256) {
        if (_shift == 0) {
            return _value;
        }
        if (_shift > 0) {
            return _value.mul(10**uint256(_shift));
        }
        return _value.div(10**uint256(-_shift));
    }
}

// File: contracts/upgradeable_contracts/BasicTokenBridge.sol

pragma solidity 0.4.24;





contract BasicTokenBridge is EternalStorage, Ownable, DecimalShiftBridge {
    using SafeMath for uint256;

    event DailyLimitChanged(uint256 newLimit);
    event ExecutionDailyLimitChanged(uint256 newLimit);

    bytes32 internal constant MIN_PER_TX = 0xbbb088c505d18e049d114c7c91f11724e69c55ad6c5397e2b929e68b41fa05d1; // keccak256(abi.encodePacked("minPerTx"))
    bytes32 internal constant MAX_PER_TX = 0x0f8803acad17c63ee38bf2de71e1888bc7a079a6f73658e274b08018bea4e29c; // keccak256(abi.encodePacked("maxPerTx"))
    bytes32 internal constant DAILY_LIMIT = 0x4a6a899679f26b73530d8cf1001e83b6f7702e04b6fdb98f3c62dc7e47e041a5; // keccak256(abi.encodePacked("dailyLimit"))
    bytes32 internal constant EXECUTION_MAX_PER_TX = 0xc0ed44c192c86d1cc1ba51340b032c2766b4a2b0041031de13c46dd7104888d5; // keccak256(abi.encodePacked("executionMaxPerTx"))
    bytes32 internal constant EXECUTION_DAILY_LIMIT = 0x21dbcab260e413c20dc13c28b7db95e2b423d1135f42bb8b7d5214a92270d237; // keccak256(abi.encodePacked("executionDailyLimit"))

    function totalSpentPerDay(uint256 _day) public view returns (uint256) {
        return uintStorage[keccak256(abi.encodePacked("totalSpentPerDay", _day))];
    }

    function totalExecutedPerDay(uint256 _day) public view returns (uint256) {
        return uintStorage[keccak256(abi.encodePacked("totalExecutedPerDay", _day))];
    }

    function dailyLimit() public view returns (uint256) {
        return uintStorage[DAILY_LIMIT];
    }

    function executionDailyLimit() public view returns (uint256) {
        return uintStorage[EXECUTION_DAILY_LIMIT];
    }

    function maxPerTx() public view returns (uint256) {
        return uintStorage[MAX_PER_TX];
    }

    function executionMaxPerTx() public view returns (uint256) {
        return uintStorage[EXECUTION_MAX_PER_TX];
    }

    function minPerTx() public view returns (uint256) {
        return uintStorage[MIN_PER_TX];
    }

    function withinLimit(uint256 _amount) public view returns (bool) {
        uint256 nextLimit = totalSpentPerDay(getCurrentDay()).add(_amount);
        return dailyLimit() >= nextLimit && _amount <= maxPerTx() && _amount >= minPerTx();
    }

    function withinExecutionLimit(uint256 _amount) public view returns (bool) {
        uint256 nextLimit = totalExecutedPerDay(getCurrentDay()).add(_amount);
        return executionDailyLimit() >= nextLimit && _amount <= executionMaxPerTx();
    }

    function getCurrentDay() public view returns (uint256) {
        // solhint-disable-next-line not-rely-on-time
        return now / 1 days;
    }

    function addTotalSpentPerDay(uint256 _day, uint256 _value) internal {
        uintStorage[keccak256(abi.encodePacked("totalSpentPerDay", _day))] = totalSpentPerDay(_day).add(_value);
    }

    function addTotalExecutedPerDay(uint256 _day, uint256 _value) internal {
        uintStorage[keccak256(abi.encodePacked("totalExecutedPerDay", _day))] = totalExecutedPerDay(_day).add(_value);
    }

    function setDailyLimit(uint256 _dailyLimit) external onlyOwner {
        require(_dailyLimit > maxPerTx() || _dailyLimit == 0);
        uintStorage[DAILY_LIMIT] = _dailyLimit;
        emit DailyLimitChanged(_dailyLimit);
    }

    function setExecutionDailyLimit(uint256 _dailyLimit) external onlyOwner {
        require(_dailyLimit > executionMaxPerTx() || _dailyLimit == 0);
        uintStorage[EXECUTION_DAILY_LIMIT] = _dailyLimit;
        emit ExecutionDailyLimitChanged(_dailyLimit);
    }

    function setExecutionMaxPerTx(uint256 _maxPerTx) external onlyOwner {
        require(_maxPerTx < executionDailyLimit());
        uintStorage[EXECUTION_MAX_PER_TX] = _maxPerTx;
    }

    function setMaxPerTx(uint256 _maxPerTx) external onlyOwner {
        require(_maxPerTx == 0 || (_maxPerTx > minPerTx() && _maxPerTx < dailyLimit()));
        uintStorage[MAX_PER_TX] = _maxPerTx;
    }

    function setMinPerTx(uint256 _minPerTx) external onlyOwner {
        require(_minPerTx > 0 && _minPerTx < dailyLimit() && _minPerTx < maxPerTx());
        uintStorage[MIN_PER_TX] = _minPerTx;
    }

    /**
    * @dev Retrieves maximum available bridge amount per one transaction taking into account maxPerTx() and dailyLimit() parameters.
    * @return minimum of maxPerTx parameter and remaining daily quota.
    */
    function maxAvailablePerTx() public view returns (uint256) {
        uint256 _maxPerTx = maxPerTx();
        uint256 _dailyLimit = dailyLimit();
        uint256 _spent = totalSpentPerDay(getCurrentDay());
        uint256 _remainingOutOfDaily = _dailyLimit > _spent ? _dailyLimit - _spent : 0;
        return _maxPerTx < _remainingOutOfDaily ? _maxPerTx : _remainingOutOfDaily;
    }

    function _setLimits(uint256[3] _limits) internal {
        require(
            _limits[2] > 0 && // minPerTx > 0
                _limits[1] > _limits[2] && // maxPerTx > minPerTx
                _limits[0] > _limits[1] // dailyLimit > maxPerTx
        );

        uintStorage[DAILY_LIMIT] = _limits[0];
        uintStorage[MAX_PER_TX] = _limits[1];
        uintStorage[MIN_PER_TX] = _limits[2];

        emit DailyLimitChanged(_limits[0]);
    }

    function _setExecutionLimits(uint256[2] _limits) internal {
        require(_limits[1] < _limits[0]); // foreignMaxPerTx < foreignDailyLimit

        uintStorage[EXECUTION_DAILY_LIMIT] = _limits[0];
        uintStorage[EXECUTION_MAX_PER_TX] = _limits[1];

        emit ExecutionDailyLimitChanged(_limits[0]);
    }
}

// File: contracts/upgradeable_contracts/TransferInfoStorage.sol

pragma solidity 0.4.24;


contract TransferInfoStorage is EternalStorage {
    /**
    * @dev Stores the value of a message sent to the AMB bridge.
    * @param _messageId of the message sent to the bridge.
    * @param _value amount of tokens bridged.
    */
    function setMessageValue(bytes32 _messageId, uint256 _value) internal {
        uintStorage[keccak256(abi.encodePacked("messageValue", _messageId))] = _value;
    }

    /**
    * @dev Tells the amount of tokens of a message sent to the AMB bridge.
    * @return value representing amount of tokens.
    */
    function messageValue(bytes32 _messageId) internal view returns (uint256) {
        return uintStorage[keccak256(abi.encodePacked("messageValue", _messageId))];
    }

    /**
    * @dev Stores the receiver of a message sent to the AMB bridge.
    * @param _messageId of the message sent to the bridge.
    * @param _recipient receiver of the tokens bridged.
    */
    function setMessageRecipient(bytes32 _messageId, address _recipient) internal {
        addressStorage[keccak256(abi.encodePacked("messageRecipient", _messageId))] = _recipient;
    }

    /**
    * @dev Tells the receiver of a message sent to the AMB bridge.
    * @return address of the receiver.
    */
    function messageRecipient(bytes32 _messageId) internal view returns (address) {
        return addressStorage[keccak256(abi.encodePacked("messageRecipient", _messageId))];
    }

    /**
    * @dev Sets that the message sent to the AMB bridge has been fixed.
    * @param _messageId of the message sent to the bridge.
    */
    function setMessageFixed(bytes32 _messageId) internal {
        boolStorage[keccak256(abi.encodePacked("messageFixed", _messageId))] = true;
    }

    /**
    * @dev Tells if a message sent to the AMB bridge has been fixed.
    * @return bool indicating the status of the message.
    */
    function messageFixed(bytes32 _messageId) public view returns (bool) {
        return boolStorage[keccak256(abi.encodePacked("messageFixed", _messageId))];
    }
}

// File: contracts/upgradeable_contracts/TokenBridgeMediator.sol

pragma solidity 0.4.24;




/**
* @title TokenBridgeMediator
* @dev Common mediator functionality to handle operations related to token bridge messages sent to AMB bridge.
*/
contract TokenBridgeMediator is BasicAMBMediator, BasicTokenBridge, TransferInfoStorage {
    event FailedMessageFixed(bytes32 indexed messageId, address recipient, uint256 value);
    event TokensBridged(address indexed recipient, uint256 value, bytes32 indexed messageId);

    /**
    * @dev Call AMB bridge to require the invocation of handleBridgedTokens method of the mediator on the other network.
    * Store information related to the bridged tokens in case the message execution fails on the other network
    * and the action needs to be fixed/rolled back.
    * @param _from address of sender, if bridge operation fails, tokens will be returned to this address
    * @param _receiver address of receiver on the other side, will eventually receive bridged tokens
    * @param _value bridged amount of tokens
    */
    function passMessage(address _from, address _receiver, uint256 _value) internal {
        bytes4 methodSelector = this.handleBridgedTokens.selector;
        bytes memory data = abi.encodeWithSelector(methodSelector, _receiver, _value);

        bytes32 _messageId = bridgeContract().requireToPassMessage(
            mediatorContractOnOtherSide(),
            data,
            requestGasLimit()
        );

        setMessageValue(_messageId, _value);
        setMessageRecipient(_messageId, _from);
    }

    /**
    * @dev Handles the bridged tokens. Checks that the value is inside the execution limits and invokes the method
    * to execute the Mint or Unlock accordingly.
    * @param _recipient address that will receive the tokens
    * @param _value amount of tokens to be received
    */
    function handleBridgedTokens(address _recipient, uint256 _value) external onlyMediator {
        if (withinExecutionLimit(_value)) {
            addTotalExecutedPerDay(getCurrentDay(), _value);
            executeActionOnBridgedTokens(_recipient, _value);
        } else {
            executeActionOnBridgedTokensOutOfLimit(_recipient, _value);
        }
    }

    /**
    * @dev Method to be called when a bridged message execution failed. It will generate a new message requesting to
    * fix/roll back the transferred assets on the other network.
    * @param _messageId id of the message which execution failed.
    */
    function requestFailedMessageFix(bytes32 _messageId) external {
        require(!bridgeContract().messageCallStatus(_messageId));
        require(bridgeContract().failedMessageReceiver(_messageId) == address(this));
        require(bridgeContract().failedMessageSender(_messageId) == mediatorContractOnOtherSide());

        bytes4 methodSelector = this.fixFailedMessage.selector;
        bytes memory data = abi.encodeWithSelector(methodSelector, _messageId);
        bridgeContract().requireToPassMessage(mediatorContractOnOtherSide(), data, requestGasLimit());
    }

    /**
    * @dev Handles the request to fix transferred assets which bridged message execution failed on the other network.
    * It uses the information stored by passMessage method when the assets were initially transferred
    * @param _messageId id of the message which execution failed on the other network.
    */
    function fixFailedMessage(bytes32 _messageId) external onlyMediator {
        require(!messageFixed(_messageId));

        address recipient = messageRecipient(_messageId);
        uint256 value = messageValue(_messageId);
        setMessageFixed(_messageId);
        executeActionOnFixedTokens(recipient, value);
        emit FailedMessageFixed(_messageId, recipient, value);
    }

    /* solcov ignore next */
    function executeActionOnBridgedTokensOutOfLimit(address _recipient, uint256 _value) internal;

    /* solcov ignore next */
    function executeActionOnBridgedTokens(address _recipient, uint256 _value) internal;

    /* solcov ignore next */
    function executeActionOnFixedTokens(address _recipient, uint256 _value) internal;
}

// File: contracts/upgradeable_contracts/amb_erc20_to_native/BasicAMBErc20ToNative.sol

pragma solidity 0.4.24;






/**
* @title BasicAMBErc20ToNative
* @dev Common mediator functionality for erc20-to-native bridge intended to work on top of AMB bridge.
*/
contract BasicAMBErc20ToNative is Initializable, Upgradeable, Claimable, VersionableBridge, TokenBridgeMediator {
    /**
    * @dev Stores the initial parameters of the mediator.
    * @param _bridgeContract the address of the AMB bridge contract.
    * @param _mediatorContract the address of the mediator contract on the other network.
    * @param _dailyLimitMaxPerTxMinPerTxArray array with limit values for the assets to be bridged to the other network.
    *   [ 0 = dailyLimit, 1 = maxPerTx, 2 = minPerTx ]
    * @param _executionDailyLimitExecutionMaxPerTxArray array with limit values for the assets bridged from the other network.
    *   [ 0 = executionDailyLimit, 1 = executionMaxPerTx ]
    * @param _requestGasLimit the gas limit for the message execution.
    * @param _decimalShift number of decimals shift required to adjust the amount of tokens bridged.
    * @param _owner address of the owner of the mediator contract
    */
    function _initialize(
        address _bridgeContract,
        address _mediatorContract,
        uint256[3] _dailyLimitMaxPerTxMinPerTxArray, // [ 0 = dailyLimit, 1 = maxPerTx, 2 = minPerTx ]
        uint256[2] _executionDailyLimitExecutionMaxPerTxArray, // [ 0 = executionDailyLimit, 1 = executionMaxPerTx ]
        uint256 _requestGasLimit,
        int256 _decimalShift,
        address _owner
    ) internal {
        require(!isInitialized());
        require(_owner != address(0));

        _setBridgeContract(_bridgeContract);
        _setMediatorContractOnOtherSide(_mediatorContract);
        _setRequestGasLimit(_requestGasLimit);
        _setLimits(_dailyLimitMaxPerTxMinPerTxArray);
        _setExecutionLimits(_executionDailyLimitExecutionMaxPerTxArray);
        _setDecimalShift(_decimalShift);
        setOwner(_owner);
    }

    /**
    * @dev Tells the bridge interface version that this contract supports.
    * @return major value of the version
    * @return minor value of the version
    * @return patch value of the version
    */
    function getBridgeInterfacesVersion() external pure returns (uint64 major, uint64 minor, uint64 patch) {
        return (1, 1, 1);
    }

    /**
    * @dev Tells the bridge mode that this contract supports.
    * @return _data 4 bytes representing the bridge mode
    */
    function getBridgeMode() external pure returns (bytes4 _data) {
        return 0xe177c00f; // bytes4(keccak256(abi.encodePacked("erc-to-native-amb")))
    }

    /**
    * @dev Execute the action to be performed when the bridge tokens are out of execution limits.
    */
    function executeActionOnBridgedTokensOutOfLimit(
        address, /* _recipient */
        uint256 /* _value */
    ) internal {
        revert();
    }
}

// File: contracts/upgradeable_contracts/BaseRewardAddressList.sol

pragma solidity 0.4.24;



/**
* @title BaseRewardAddressList
* @dev Implements the logic to store, add and remove reward account addresses. Works as a linked list.
*/
contract BaseRewardAddressList is EternalStorage {
    using SafeMath for uint256;

    address public constant F_ADDR = 0xFFfFfFffFFfffFFfFFfFFFFFffFFFffffFfFFFfF;
    uint256 internal constant MAX_REWARD_ADDRESSES = 50;
    bytes32 internal constant REWARD_ADDRESS_COUNT = 0xabc77c82721ced73eef2645facebe8c30249e6ac372cce6eb9d1fed31bd6648f; // keccak256(abi.encodePacked("rewardAddressCount"))

    event RewardAddressAdded(address indexed addr);
    event RewardAddressRemoved(address indexed addr);

    /**
    * @dev Retrieves all registered reward accounts.
    * @return address list of the registered reward receivers.
    */
    function rewardAddressList() external view returns (address[]) {
        address[] memory list = new address[](rewardAddressCount());
        uint256 counter = 0;
        address nextAddr = getNextRewardAddress(F_ADDR);

        while (nextAddr != F_ADDR) {
            require(nextAddr != address(0));

            list[counter] = nextAddr;
            nextAddr = getNextRewardAddress(nextAddr);
            counter++;
        }

        return list;
    }

    /**
    * @dev Retrieves amount of registered reward accounts.
    * @return length of reward addresses list.
    */
    function rewardAddressCount() public view returns (uint256) {
        return uintStorage[REWARD_ADDRESS_COUNT];
    }

    /**
    * @dev Checks if specified address is included into the registered rewards receivers list.
    * @param _addr address to verify.
    * @return true, if specified address is associated with one of the registered reward accounts.
    */
    function isRewardAddress(address _addr) public view returns (bool) {
        return _addr != F_ADDR && getNextRewardAddress(_addr) != address(0);
    }

    /**
    * @dev Retrieves next reward address in the linked list, or F_ADDR if given address is the last one.
    * @param _address address of some reward account.
    * @return address of the next reward receiver.
    */
    function getNextRewardAddress(address _address) public view returns (address) {
        return addressStorage[keccak256(abi.encodePacked("rewardAddressList", _address))];
    }

    /**
    * @dev Internal function for adding a new reward address to the linked list.
    * @param _addr new reward account.
    */
    function _addRewardAddress(address _addr) internal {
        require(_addr != address(0) && _addr != F_ADDR);
        require(!isRewardAddress(_addr));

        address nextAddr = getNextRewardAddress(F_ADDR);

        require(nextAddr != address(0));

        _setNextRewardAddress(_addr, nextAddr);
        _setNextRewardAddress(F_ADDR, _addr);
        _setRewardAddressCount(rewardAddressCount().add(1));
    }

    /**
    * @dev Internal function for removing existing reward address from the linked list.
    * @param _addr old reward account which should be removed.
    */
    function _removeRewardAddress(address _addr) internal {
        require(isRewardAddress(_addr));
        address nextAddr = getNextRewardAddress(_addr);
        address index = F_ADDR;
        address next = getNextRewardAddress(index);

        while (next != _addr) {
            require(next != address(0));
            index = next;
            next = getNextRewardAddress(index);
            require(next != F_ADDR);
        }

        _setNextRewardAddress(index, nextAddr);
        delete addressStorage[keccak256(abi.encodePacked("rewardAddressList", _addr))];
        _setRewardAddressCount(rewardAddressCount().sub(1));
    }

    /**
    * @dev Internal function for initializing linked list with the array of the initial reward addresses.
    * @param _rewardAddresses initial reward addresses list, should be non-empty.
    */
    function _setRewardAddressList(address[] _rewardAddresses) internal {
        require(_rewardAddresses.length > 0);

        _setNextRewardAddress(F_ADDR, _rewardAddresses[0]);

        for (uint256 i = 0; i < _rewardAddresses.length; i++) {
            require(_rewardAddresses[i] != address(0) && _rewardAddresses[i] != F_ADDR);
            require(!isRewardAddress(_rewardAddresses[i]));

            if (i == _rewardAddresses.length - 1) {
                _setNextRewardAddress(_rewardAddresses[i], F_ADDR);
            } else {
                _setNextRewardAddress(_rewardAddresses[i], _rewardAddresses[i + 1]);
            }

            emit RewardAddressAdded(_rewardAddresses[i]);
        }

        _setRewardAddressCount(_rewardAddresses.length);
    }

    /**
    * @dev Internal function for updating the length of the reward accounts list.
    * @param _rewardAddressCount new linked list length.
    */
    function _setRewardAddressCount(uint256 _rewardAddressCount) internal {
        require(_rewardAddressCount <= MAX_REWARD_ADDRESSES);
        uintStorage[REWARD_ADDRESS_COUNT] = _rewardAddressCount;
    }

    /**
    * @dev Internal function for updating the pointer to the next reward receiver.
    * @param _prevAddr address of some reward receiver.
    * @param _addr address of the next receiver to which _prevAddr should point to.
    */
    function _setNextRewardAddress(address _prevAddr, address _addr) internal {
        addressStorage[keccak256(abi.encodePacked("rewardAddressList", _prevAddr))] = _addr;
    }
}

// File: contracts/upgradeable_contracts/amb_erc20_to_native/HomeFeeManagerAMBErc20ToNative.sol

pragma solidity 0.4.24;



/**
* @title HomeFeeManagerAMBErc20ToNative
* @dev Implements the logic to distribute fees from the erc20 to native mediator contract operations.
* The fees are distributed in the form of native tokens to the list of reward accounts.
*/
contract HomeFeeManagerAMBErc20ToNative is BaseRewardAddressList, Ownable {
    using SafeMath for uint256;

    event FeeUpdated(bytes32 feeType, uint256 fee);
    event FeeDistributed(uint256 fee, bytes32 indexed messageId);

    // This is not a real fee value but a relative value used to calculate the fee percentage
    uint256 internal constant MAX_FEE = 1 ether;
    bytes32 public constant HOME_TO_FOREIGN_FEE = 0x741ede137d0537e88e0ea0ff25b1f22d837903dbbee8980b4a06e8523247ee26; // keccak256(abi.encodePacked("homeToForeignFee"))
    bytes32 public constant FOREIGN_TO_HOME_FEE = 0x03be2b2875cb41e0e77355e802a16769bb8dfcf825061cde185c73bf94f12625; // keccak256(abi.encodePacked("foreignToHomeFee"))

    /**
    * @dev Throws if given fee percentage is >= 100%.
    */
    modifier validFee(uint256 _fee) {
        require(_fee < MAX_FEE);
        /* solcov ignore next */
        _;
    }

    /**
    * @dev Throws if given fee type is unknown.
    */
    modifier validFeeType(bytes32 _feeType) {
        require(_feeType == HOME_TO_FOREIGN_FEE || _feeType == FOREIGN_TO_HOME_FEE);
        /* solcov ignore next */
        _;
    }

    /**
    * @dev Adds a new reward address to the list, which will receive fees collected from the bridge operations.
    * Only the owner can call this method.
    * @param _addr new reward account.
    */
    function addRewardAddress(address _addr) external onlyOwner {
        _addRewardAddress(_addr);
    }

    /**
    * @dev Removes a reward address from the rewards list.
    * Only the owner can call this method.
    * @param _addr old reward account, that should be removed.
    */
    function removeRewardAddress(address _addr) external onlyOwner {
        _removeRewardAddress(_addr);
    }

    /**
    * @dev Updates the value for the particular fee type.
    * Only the owner can call this method.
    * @param _feeType type of the updated fee, can be one of [HOME_TO_FOREIGN_FEE, FOREIGN_TO_HOME_FEE].
    * @param _fee new fee value, in percentage (1 ether == 10**18 == 100%).
    */
    function setFee(bytes32 _feeType, uint256 _fee) external onlyOwner {
        _setFee(_feeType, _fee);
    }

    /**
    * @dev Retrieves the value for the particular fee type.
    * @param _feeType type of the updated fee, can be one of [HOME_TO_FOREIGN_FEE, FOREIGN_TO_HOME_FEE].
    * @return fee value associated with the requested fee type.
    */
    function getFee(bytes32 _feeType) public view validFeeType(_feeType) returns (uint256) {
        return uintStorage[_feeType];
    }

    /**
    * @dev Calculates the amount of fee to pay for the value of the particular fee type.
    * @param _feeType type of the updated fee, can be one of [HOME_TO_FOREIGN_FEE, FOREIGN_TO_HOME_FEE].
    * @param _value bridged value, for which fee should be evaluated.
    * @return amount of fee to be subtracted from the transferred value.
    */
    function calculateFee(bytes32 _feeType, uint256 _value) public view returns (uint256) {
        uint256 _fee = getFee(_feeType);
        return _value.mul(_fee).div(MAX_FEE);
    }

    /**
    * @dev Internal function for updating the fee value for the given fee type.
    * @param _feeType type of the updated fee, can be one of [HOME_TO_FOREIGN_FEE, FOREIGN_TO_HOME_FEE].
    * @param _fee new fee value, in percentage (1 ether == 10**18 == 100%).
    */
    function _setFee(bytes32 _feeType, uint256 _fee) internal validFeeType(_feeType) validFee(_fee) {
        uintStorage[_feeType] = _fee;
        emit FeeUpdated(_feeType, _fee);
    }

    /**
    * @dev Calculates a random number based on the block number.
    * @param _count the max value for the random number.
    * @return a number between 0 and _count.
    */
    function random(uint256 _count) internal view returns (uint256) {
        return uint256(blockhash(block.number.sub(1))) % _count;
    }

    /**
    * @dev Calculates and distributes the amount of fee proportionally between registered reward addresses.
    * @param _feeType type of the updated fee, can be one of [HOME_TO_FOREIGN_FEE, FOREIGN_TO_HOME_FEE].
    * @param _value bridged value, for which fee should be evaluated.
    * @return total amount of fee subtracted from the transferred value and distributed between the reward accounts.
    */
    function _distributeFee(bytes32 _feeType, uint256 _value) internal returns (uint256) {
        uint256 numOfAccounts = rewardAddressCount();
        uint256 _fee = calculateFee(_feeType, _value);
        if (numOfAccounts == 0 || _fee == 0) {
            return 0;
        }
        uint256 feePerAccount = _fee.div(numOfAccounts);
        uint256 randomAccountIndex;
        uint256 diff = _fee.sub(feePerAccount.mul(numOfAccounts));
        if (diff > 0) {
            randomAccountIndex = random(numOfAccounts);
        }

        address nextAddr = getNextRewardAddress(F_ADDR);
        require(nextAddr != F_ADDR && nextAddr != address(0));

        uint256 i = 0;
        while (nextAddr != F_ADDR) {
            uint256 feeToDistribute = feePerAccount;
            if (diff > 0 && randomAccountIndex == i) {
                feeToDistribute = feeToDistribute.add(diff);
            }

            onFeeDistribution(_feeType, nextAddr, feeToDistribute);

            nextAddr = getNextRewardAddress(nextAddr);
            require(nextAddr != address(0));
            i = i + 1;
        }
        return _fee;
    }

    /* solcov ignore next */
    function onFeeDistribution(bytes32 _feeType, address _receiver, uint256 _value) internal;
}

// File: contracts/interfaces/IBlockReward.sol

pragma solidity 0.4.24;

interface IBlockReward {
    function addExtraReceiver(uint256 _amount, address _receiver) external;
    function mintedTotally() external view returns (uint256);
    function mintedTotallyByBridge(address _bridge) external view returns (uint256);
    function bridgesAllowedLength() external view returns (uint256);
    function addBridgeTokenRewardReceivers(uint256 _amount) external;
    function addBridgeNativeRewardReceivers(uint256 _amount) external;
    function blockRewardContractId() external pure returns (bytes4);
}

// File: contracts/upgradeable_contracts/BlockRewardBridge.sol

pragma solidity 0.4.24;




contract BlockRewardBridge is EternalStorage {
    bytes32 internal constant BLOCK_REWARD_CONTRACT = 0x20ae0b8a761b32f3124efb075f427dd6ca669e88ae7747fec9fd1ad688699f32; // keccak256(abi.encodePacked("blockRewardContract"))
    bytes4 internal constant BLOCK_REWARD_CONTRACT_ID = 0x2ee57f8d; // blockRewardContractId()
    bytes4 internal constant BRIDGES_ALLOWED_LENGTH = 0x10f2ee7c; // bridgesAllowedLength()

    function _blockRewardContract() internal view returns (IBlockReward) {
        return IBlockReward(addressStorage[BLOCK_REWARD_CONTRACT]);
    }

    function _setBlockRewardContract(address _blockReward) internal {
        require(AddressUtils.isContract(_blockReward));

        // Before store the contract we need to make sure that it is the block reward contract in actual fact,
        // call a specific method from the contract that should return a specific value
        bool isBlockRewardContract = false;
        if (_blockReward.call(BLOCK_REWARD_CONTRACT_ID)) {
            isBlockRewardContract =
                IBlockReward(_blockReward).blockRewardContractId() == bytes4(keccak256("blockReward"));
        } else if (_blockReward.call(BRIDGES_ALLOWED_LENGTH)) {
            isBlockRewardContract = IBlockReward(_blockReward).bridgesAllowedLength() != 0;
        }
        require(isBlockRewardContract);
        addressStorage[BLOCK_REWARD_CONTRACT] = _blockReward;
    }
}

// File: contracts/upgradeable_contracts/amb_erc20_to_native/HomeAMBErc20ToNative.sol

pragma solidity 0.4.24;




/**
* @title HomeAMBErc20ToNative
* @dev Home mediator implementation for erc20-to-native bridge intended to work on top of AMB bridge.
* It is design to be used as implementation contract of EternalStorageProxy contract.
*/
contract HomeAMBErc20ToNative is BasicAMBErc20ToNative, BlockRewardBridge, HomeFeeManagerAMBErc20ToNative {
    bytes32 internal constant TOTAL_BURNT_COINS = 0x17f187b2e5d1f8770602b32c1159b85c9600859277fae1eaa9982e9bcf63384c; // keccak256(abi.encodePacked("totalBurntCoins"))

    /**
    * @dev Stores the initial parameters of the mediator.
    * @param _bridgeContract the address of the AMB bridge contract.
    * @param _mediatorContract the address of the mediator contract on the other network.
    * @param _dailyLimitMaxPerTxMinPerTxArray array with limit values for the assets to be bridged to the other network.
    *   [ 0 = dailyLimit, 1 = maxPerTx, 2 = minPerTx ]
    * @param _executionDailyLimitExecutionMaxPerTxArray array with limit values for the assets bridged from the other network.
    *   [ 0 = executionDailyLimit, 1 = executionMaxPerTx ]
    * @param _requestGasLimit the gas limit for the message execution.
    * @param _decimalShift number of decimals shift required to adjust the amount of tokens bridged.
    * @param _owner address of the owner of the mediator contract
    * @param _blockReward address of the block reward contract
    */
    function initialize(
        address _bridgeContract,
        address _mediatorContract,
        uint256[3] _dailyLimitMaxPerTxMinPerTxArray, // [ 0 = dailyLimit, 1 = maxPerTx, 2 = minPerTx ]
        uint256[2] _executionDailyLimitExecutionMaxPerTxArray, // [ 0 = executionDailyLimit, 1 = executionMaxPerTx ]
        uint256 _requestGasLimit,
        int256 _decimalShift,
        address _owner,
        address _blockReward
    ) public onlyRelevantSender returns (bool) {
        _initialize(
            _bridgeContract,
            _mediatorContract,
            _dailyLimitMaxPerTxMinPerTxArray,
            _executionDailyLimitExecutionMaxPerTxArray,
            _requestGasLimit,
            _decimalShift,
            _owner
        );
        _setBlockRewardContract(_blockReward);
        setInitialize();
        return isInitialized();
    }

    /**
    * @dev Stores the initial parameters of the mediator, sets the rewardable mediator as well.
    * @param _bridgeContract the address of the AMB bridge contract.
    * @param _mediatorContract the address of the mediator contract on the other network.
    * @param _dailyLimitMaxPerTxMinPerTxArray array with limit values for the assets to be bridged to the other network.
    *   [ 0 = dailyLimit, 1 = maxPerTx, 2 = minPerTx ]
    * @param _executionDailyLimitExecutionMaxPerTxArray array with limit values for the assets bridged from the other network.
    *   [ 0 = executionDailyLimit, 1 = executionMaxPerTx ]
    * @param _requestGasLimit the gas limit for the message execution.
    * @param _decimalShift number of decimals shift required to adjust the amount of tokens bridged.
    * @param _owner address of the owner of the mediator contract
    * @param _blockReward address of the block reward contract
    * @param _rewardAddreses list of reward addresses, between whom fees will be distributed
    * @param _fees array with initial fees for both bridge firections
    *   [ 0 = homeToForeignFee, 1 = foreignToHomeFee ]
    */
    function rewardableInitialize(
        address _bridgeContract,
        address _mediatorContract,
        uint256[3] _dailyLimitMaxPerTxMinPerTxArray, // [ 0 = dailyLimit, 1 = maxPerTx, 2 = minPerTx ]
        uint256[2] _executionDailyLimitExecutionMaxPerTxArray, // [ 0 = executionDailyLimit, 1 = executionMaxPerTx ]
        uint256 _requestGasLimit,
        int256 _decimalShift,
        address _owner,
        address _blockReward,
        address[] _rewardAddreses,
        uint256[2] _fees // [ 0 = homeToForeignFee, 1 = foreignToHomeFee ]
    ) external returns (bool) {
        _setRewardAddressList(_rewardAddreses);
        _setFee(HOME_TO_FOREIGN_FEE, _fees[0]);
        _setFee(FOREIGN_TO_HOME_FEE, _fees[1]);
        return
            initialize(
                _bridgeContract,
                _mediatorContract,
                _dailyLimitMaxPerTxMinPerTxArray,
                _executionDailyLimitExecutionMaxPerTxArray,
                _requestGasLimit,
                _decimalShift,
                _owner,
                _blockReward
            );
    }

    /**
    * @dev Fallback method to be called to initiate the bridge operation of the native tokens to an erc20 representation
    * that the user will receive in the same address on the other network.
    */
    function() public payable {
        require(msg.data.length == 0);
        nativeTransfer(msg.sender);
    }

    /**
    * @dev Method to be called to initiate the bridge operation of the native tokens to an erc20 representation
    * that the user will receive in the address specified by parameter on the other network.
    * @param _receiver address that will receive the erc20 tokens on the other network.
    */
    function relayTokens(address _receiver) external payable {
        nativeTransfer(_receiver);
    }

    /**
    * @dev Updates an address of the block reward contract that is used for minting native coins.
    * @param _blockReward address of new block reward contract.
    */
    function setBlockRewardContract(address _blockReward) external onlyOwner {
        _setBlockRewardContract(_blockReward);
    }

    /**
    * @dev Retrieves address of the currently used block reward contract.
    * @return address of block reward contract.
    */
    function blockRewardContract() public view returns (IBlockReward) {
        return _blockRewardContract();
    }

    /**
    * @dev Retrieves total burnt coins by this bridge.
    * @return amount of burnt coins.
    */
    function totalBurntCoins() public view returns (uint256) {
        return uintStorage[TOTAL_BURNT_COINS];
    }

    /**
    * @dev Validates the received native tokens and makes the request to unlock the erc20 tokens on the other network.
    * @param _receiver address that will receive the erc20 tokens on the other network.
    */
    function nativeTransfer(address _receiver) internal {
        // this check also validates that msg.value is positive, since minPerTx() > 0
        require(withinLimit(msg.value));

        IBlockReward blockReward = blockRewardContract();
        uint256 totalMinted = blockReward.mintedTotallyByBridge(address(this));
        uint256 totalBurnt = totalBurntCoins();
        require(msg.value <= totalMinted.sub(totalBurnt));

        addTotalSpentPerDay(getCurrentDay(), msg.value);

        uint256 valueToTransfer = msg.value;
        bytes32 _messageId = messageId();

        uint256 fee = _distributeFee(HOME_TO_FOREIGN_FEE, valueToTransfer);
        if (fee > 0) {
            emit FeeDistributed(fee, _messageId);
            valueToTransfer = valueToTransfer.sub(fee);
        }

        passMessage(msg.sender, _receiver, valueToTransfer);
        _burnCoins(valueToTransfer);
    }

    /**
    * @dev Internal function for updating amount of burnt coins by this bridge.
    * @param _amount new amount of burned coins.
    */
    function _setTotalBurntCoins(uint256 _amount) internal {
        uintStorage[TOTAL_BURNT_COINS] = _amount;
    }

    /**
    * @dev Mints the amount of native tokens that were bridged from the other network.
    * @param _receiver address that will receive the native tokens
    * @param _value amount of native tokens to be received
    */
    function executeActionOnBridgedTokens(address _receiver, uint256 _value) internal {
        uint256 valueToMint = _shiftValue(_value);
        bytes32 _messageId = messageId();

        uint256 fee = _distributeFee(FOREIGN_TO_HOME_FEE, valueToMint);
        if (fee > 0) {
            emit FeeDistributed(fee, _messageId);
            valueToMint = valueToMint.sub(fee);
        }

        IBlockReward blockReward = blockRewardContract();
        blockReward.addExtraReceiver(valueToMint, _receiver);
        emit TokensBridged(_receiver, valueToMint, _messageId);
    }

    /**
    * @dev Mints back the amount of native tokens that were bridged to the other network but failed.
    * @param _receiver address that will receive the native tokens
    * @param _value amount of native tokens to be received
    */
    function executeActionOnFixedTokens(address _receiver, uint256 _value) internal {
        IBlockReward blockReward = blockRewardContract();
        blockReward.addExtraReceiver(_value, _receiver);
    }

    /**
    * @dev Allows to transfer any locked token on this contract that is not part of the bridge operations.
    * Native tokens are not allowed to be claimed.
    * @param _token address of the token.
    * @param _to address that will receive the locked tokens on this contract.
    */
    function claimTokens(address _token, address _to) external onlyIfUpgradeabilityOwner validAddress(_to) {
        require(_token != address(0));
        claimValues(_token, _to);
    }

    /**
    * @dev Allows to send to the other network the amount of locked native tokens that can be forced into the contract
    * without the invocation of the required methods.
    * @param _receiver the address that will receive the tokens on the other network
    */
    function fixMediatorBalance(address _receiver) external onlyIfUpgradeabilityOwner {
        uint256 balance = address(this).balance;
        uint256 available = maxAvailablePerTx();
        if (balance > available) {
            balance = available;
        }
        require(balance > 0);
        addTotalSpentPerDay(getCurrentDay(), balance);
        passMessage(_receiver, _receiver, balance);
        _burnCoins(balance);
    }

    /**
    * @dev Internal function for "burning" native coins. Coins are burnt by sending them to address(0x00..00).
    * @param _amount amount of native coins to burn.
    */
    function _burnCoins(uint256 _amount) internal {
        _setTotalBurntCoins(totalBurntCoins().add(_amount));
        address(0).transfer(_amount);
    }

    /**
    * @dev Internal function distributing a piece of collected fee to the particular reward address.
    * @param _feeType used fee type, can be one of [HOME_TO_FOREIGN_FEE, FOREIGN_TO_HOME_FEE].
    * @param _receiver particular reward address, where the fee should be sent/minted.
    * @param _fee amount of fee to send/mint to given address.
    */
    function onFeeDistribution(bytes32 _feeType, address _receiver, uint256 _fee) internal {
        if (_feeType == HOME_TO_FOREIGN_FEE) {
            Address.safeSendValue(_receiver, _fee);
        } else {
            IBlockReward blockReward = blockRewardContract();
            blockReward.addExtraReceiver(_fee, _receiver);
        }
    }
}
