// // SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.20;

import "@openzeppelin/contracts@5.0.0/proxy/Proxy.sol";
import "@openzeppelin/contracts@5.0.0/proxy/ERC1967/ERC1967Utils.sol";
import {StorageSlot} from "@openzeppelin/contracts@5.0.0/utils/StorageSlot.sol";
import {BaseComn} from "../BaseComn.sol";

/**
 * @title MyProxy
 * @dev This contract serves as a proxy contract, inheriting from BaseComn and Proxy.
 * It provides functionality for upgrading the implementation contract and retrieving the current implementation address.
 */
contract MyProxy is BaseComn, Proxy {
    /**
     * @dev Constructor function. Initializes the proxy contract by setting the implementation contract
     * and optionally calling a function on the new implementation with provided data.
     * @param impl The address of the initial implementation contract.
     * @param _admin set the admin & create2 address.
     * @param data The data to be passed to the new implementation contract during initialization.
     */
    constructor(address impl, address _admin, bytes memory data) {
        StorageSlot.getAddressSlot(_ADMIN_SLOT).value = _admin;
        // Call the upgradeToAndCall function from ERC1967Utils to set the implementation and execute the provided data.
        ERC1967Utils.upgradeToAndCall(impl, data);
    }

    /**
     * @dev Allows the master account to update the implementation contract of the proxy.
     * Only the master account can call this function due to the 'onlyMaster' modifier.
     * @param impl The address of the new implementation contract.
     */
    function proxyUpdateImplementation(address impl) public onlyMaster {
        // Call the upgradeToAndCall function from ERC1967Utils to set the new implementation.
        // Pass an empty bytes array as no additional data needs to be executed during the upgrade.
        ERC1967Utils.upgradeToAndCall(impl, "");
    }

    /**
     * @dev Retrieves the address of the current implementation contract used by the proxy.
     * @return The address of the current implementation contract.
     */
    function proxyGetImpl() public view returns (address) {
        // Call the getImplementation function from ERC1967Utils to get the current implementation address.
        return ERC1967Utils.getImplementation();
    }

    /**
     * @dev Internal virtual function that overrides the _implementation function from the Proxy contract.
     * It is used by the proxy to determine the address of the implementation contract to delegate calls to.
     * @return The address of the current implementation contract.
     */
    function _implementation()
        internal
        view
        virtual
        override
        returns (address)
    {
        // Call the getImplementation function from ERC1967Utils to get the current implementation address.
        return ERC1967Utils.getImplementation();
    }

    /**
     * @dev Fallback function that allows the contract to receive Ether.
     * This function is executed when the contract receives plain Ether transfers without any data.
     */
    receive() external payable {}
}
