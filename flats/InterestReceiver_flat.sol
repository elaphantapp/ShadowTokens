
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

// File: openzeppelin-solidity/contracts/ownership/Ownable.sol

pragma solidity ^0.4.24;


/**
 * @title Ownable
 * @dev The Ownable contract has an owner address, and provides basic authorization control
 * functions, this simplifies the implementation of "user permissions".
 */
contract Ownable {
  address public owner;


  event OwnershipRenounced(address indexed previousOwner);
  event OwnershipTransferred(
    address indexed previousOwner,
    address indexed newOwner
  );


  /**
   * @dev The Ownable constructor sets the original `owner` of the contract to the sender
   * account.
   */
  constructor() public {
    owner = msg.sender;
  }

  /**
   * @dev Throws if called by any account other than the owner.
   */
  modifier onlyOwner() {
    require(msg.sender == owner);
    _;
  }

  /**
   * @dev Allows the current owner to relinquish control of the contract.
   * @notice Renouncing to ownership will leave the contract without an owner.
   * It will not be possible to call the functions with the `onlyOwner`
   * modifier anymore.
   */
  function renounceOwnership() public onlyOwner {
    emit OwnershipRenounced(owner);
    owner = address(0);
  }

  /**
   * @dev Allows the current owner to transfer control of the contract to a newOwner.
   * @param _newOwner The address to transfer ownership to.
   */
  function transferOwnership(address _newOwner) public onlyOwner {
    _transferOwnership(_newOwner);
  }

  /**
   * @dev Transfers control of the contract to a newOwner.
   * @param _newOwner The address to transfer ownership to.
   */
  function _transferOwnership(address _newOwner) internal {
    require(_newOwner != address(0));
    emit OwnershipTransferred(owner, _newOwner);
    owner = _newOwner;
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

// File: contracts/interfaces/IPot.sol

pragma solidity 0.4.24;

interface IPot {
    function chi() external view returns (uint256);
    function rho() external view returns (uint256);
    function drip() external returns (uint256);
}

// File: contracts/interfaces/IChai.sol

pragma solidity 0.4.24;



interface IChai {
    function pot() external view returns (IPot);
    function daiToken() external view returns (ERC20);
    function balanceOf(address) external view returns (uint256);
    function dai(address) external view returns (uint256);
    function join(address, uint256) external;
    function draw(address, uint256) external;
    function exit(address, uint256) external;
    function transfer(address, uint256) external;
}

// File: contracts/interfaces/ERC677Receiver.sol

pragma solidity 0.4.24;

contract ERC677Receiver {
    function onTokenTransfer(address _from, uint256 _value, bytes _data) external returns (bool);
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

// File: contracts/upgradeable_contracts/TokenSwapper.sol

pragma solidity 0.4.24;

contract TokenSwapper {
    // emitted when two tokens is swapped (e. g. Sai to Dai, Chai to Dai)
    event TokensSwapped(address indexed from, address indexed to, uint256 value);
}

// File: contracts/upgradeable_contracts/InterestReceiver.sol

pragma solidity 0.4.24;








/**
* @title InterestReceiver
* @dev Сontract for receiving Chai interest and immediatly converting it into Dai.
* Contract also will try to automaticaly relay tokens to configured xDai receiver
*/
contract InterestReceiver is ERC677Receiver, Ownable, Claimable, TokenSwapper {
    bytes4 internal constant RELAY_TOKENS = 0x01e4f53a; // relayTokens(address,uint256)

    address public bridgeContract;
    address public receiverInXDai;

    event RelayTokensFailed(address receiver, uint256 amount);

    /**
    * @dev Initializes interest receiver, sets an owner of a contract
    * @param _owner address of owner account, only owner can withdraw Dai tokens from contract
    * @param _bridgeContract address of the bridge contract in the foreign chain
    * @param _receiverInXDai address of the receiver account, in the xDai chain
    */
    constructor(address _owner, address _bridgeContract, address _receiverInXDai) public {
        require(AddressUtils.isContract(_bridgeContract));
        _transferOwnership(_owner);
        bridgeContract = _bridgeContract;
        receiverInXDai = _receiverInXDai;
    }

    /**
    * @dev Updates bridge contract from which interest is expected to come from,
    * the incoming tokens will be relayed through this bridge also
    * @param _bridgeContract address of new contract in the foreign chain
    */
    function setBridgeContract(address _bridgeContract) external onlyOwner {
        require(AddressUtils.isContract(_bridgeContract));
        bridgeContract = _bridgeContract;
    }

    /**
    * @dev Updates receiver address in the xDai chain
    * @param _receiverInXDai address of new receiver account in the xDai chain
    */
    function setReceiverInXDai(address _receiverInXDai) external onlyOwner {
        receiverInXDai = _receiverInXDai;
    }

    /**
    * @return Chai token contract address
    */
    function chaiToken() public view returns (IChai) {
        return IChai(0x06AF07097C9Eeb7fD685c692751D5C66dB49c215);
    }

    /**
    * @return Dai token contract address
    */
    function daiToken() public view returns (ERC20) {
        return ERC20(0x6B175474E89094C44Da98b954EedeAC495271d0F);
    }

    /**
    * @dev ERC677 transfer callback function, received interest is converted from Chai token into Dai
    * and then relayed via bridge to xDai receiver
    */
    function onTokenTransfer(address, uint256, bytes) external returns (bool) {
        uint256 chaiBalance = chaiToken().balanceOf(address(this));
        uint256 initialDaiBalance = daiToken().balanceOf(address(this));
        uint256 finalDaiBalance = initialDaiBalance;

        if (chaiBalance > 0) {
            chaiToken().exit(address(this), chaiBalance);

            finalDaiBalance = daiToken().balanceOf(address(this));
            // Dai balance cannot decrease here, so SafeMath is not needed
            uint256 redeemed = finalDaiBalance - initialDaiBalance;

            emit TokensSwapped(chaiToken(), daiToken(), redeemed);

            // chi is always >= 10**27, so chai/dai rate is always >= 1
            require(redeemed >= chaiBalance);
        }

        daiToken().approve(address(bridgeContract), finalDaiBalance);
        if (!bridgeContract.call(abi.encodeWithSelector(RELAY_TOKENS, receiverInXDai, finalDaiBalance))) {
            daiToken().approve(address(bridgeContract), 0);
            emit RelayTokensFailed(receiverInXDai, finalDaiBalance);
        }
    }

    /**
    * @dev Claims tokens from receiver account
    * @param _token address of claimed token, address(0) for native
    * @param _to address of tokens receiver
    */
    function claimTokens(address _token, address _to) external onlyOwner validAddress(_to) {
        require(_token != address(chaiToken()) && _token != address(daiToken()));
        claimValues(_token, _to);
    }
}
