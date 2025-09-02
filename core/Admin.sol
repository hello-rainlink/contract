// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.0;

import {IAdmin} from "../comn/IAdmin.sol";

/**
 * @dev administrator.
 * Does not require proxy, is deployed first.
 */
contract Admin is IAdmin {
    address public master; // master
    address public admin; // admin

    event AdminChanged(address oldAdmin, address newAdmin);
    event MasterChanged(address oldMaster, address newMaster);

    /**
     * @dev Throws if called by any account other than the master.
     */
    modifier onlyMaster() {
        require(isMaster(msg.sender), "Must master");
        _;
    }

    /**
     * @dev Throws if called by any account other than the auditor.
     */
    modifier onlyAdmin() {
        require(isAdmin(msg.sender), "Must admin");
        _;
    }


    /**
     * @dev constructor
     */
    constructor() {
        initMaster(msg.sender);
        setAdmin(msg.sender);
    }

    /**
     * @dev init the master address.
     * the proxy call
     */
    function initMaster(address addr) public {
        if (master == address(0)) {
            master = addr;
        }
    }
    
    /**
     * @dev change the admin address.
     */
    function setAdmin(address newAdmin) public onlyMaster {
        require(newAdmin != address(0), "Invalid admin");
        
        emit AdminChanged(admin, newAdmin);
        admin = newAdmin;
    }

    /**
     * @dev change the master address.
     */
    function setMaster(address newMaster) public onlyMaster {
        require(newMaster != address(0), "Invalid address");
        emit MasterChanged(master, newMaster);
        master = newMaster;
    }

    /**
     * @dev Throws if called by any account other than the master.
     */
    function mustMaster(address addr) public view override {
        require(isMaster(addr), "Must master");
    }

    /**
     * @dev Throws if called by any account other than the master.
     */
    function mustAdmin(address addr) public view override {
        require(isAdmin(addr), "Must admin");
    }

    /**
     * @dev Whether address is master.
     */
    function isMaster(address addr) public view override returns (bool) {
        return master == addr;
    }

    /**
     * @dev Whether address is this contract address.
     */
    function isAdmin(address addr) public view override returns (bool) {
        return admin == addr;
    }
}
