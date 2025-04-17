// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.20;

import "../BaseComn.sol";
import {Types} from "../comn/Types.sol";

/**
 * @title all sol extends from this
 * @dev Extends BaseComn with additional address constants
 */
abstract contract Comn is BaseComn {
    // xone
    address constant ValidatorAddr = address(0x697b6397599267Be5a34057901533f85462C1e2f);

    // tbsc
    // address constant ValidatorAddr = address(0x237aeC76ED2bECC3e5df4f007F6E67CC2EAe68e9);

    // sepolia
    // address constant ValidatorAddr = address(0x1F1C9CFF1c78cE6d530b218dF61f25D7849A1791);

    // nile
    // address constant ValidatorAddr = address(0xa85E0F60586EbB70d05cE01D09B5750C04f8e046); //TRKTChDwwjFTi9mmL6iePHV6X2C42YN3TN

    // ETH chain
    Types.ChainType constant ChainType = Types.ChainType.ETH;

    // TRX chain
    // Types.ChainType constant ChainType = Types.ChainType.TRX;
}