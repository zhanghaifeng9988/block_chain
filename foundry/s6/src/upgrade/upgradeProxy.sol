// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin-upgradeable/contracts/proxy/utils/Initializable.sol";
import "@openzeppelin-upgradeable/contracts/token/ERC721/IERC721Upgradeable.sol";

contract UpgradeProxy is Initializable {
    address public implementation;
    address public admin;
    
    event Upgraded(address indexed implementation);
    event AdminChanged(address indexed previousAdmin, address indexed newAdmin);

    modifier onlyAdmin() {
        require(msg.sender == admin, "Only admin");
        _;
    }

    function initialize(address _implementation, bytes memory _initData) public initializer {
        implementation = _implementation;
        admin = msg.sender;
        if (_initData.length > 0) {
            (bool ok, ) = _implementation.delegatecall(_initData);
            require(ok, "Init failed");
        }
    }

    function upgrade(address _newImplementation) external onlyAdmin {
        require(_newImplementation != address(0), "Invalid implementation");
        implementation = _newImplementation;
        emit Upgraded(_newImplementation);
    }

    function changeAdmin(address _newAdmin) external onlyAdmin {
        require(_newAdmin != address(0), "Invalid admin");
        emit AdminChanged(admin, _newAdmin);
        admin = _newAdmin;
    }

    fallback() external payable {
        address _impl = implementation;
        assembly {
            calldatacopy(0, 0, calldatasize())
            let result := delegatecall(gas(), _impl, 0, calldatasize(), 0, 0)
            returndatacopy(0, 0, returndatasize())
            switch result
            case 0 { revert(0, returndatasize()) }
            default { return(0, returndatasize()) }
        }
    }

    receive() external payable {}
} 