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
    address constant ValidatorAddr = address(0x0832652cF69DFE916bCD6142759AC7E6813b406c);

    // tbsc
    // address constant ValidatorAddr = 0xd2bA7eBd42a39315Dac3f8bba68d30f622fe467f;

    // address constant ValidatorAddr = address(0xF973BbcfEA512aC7BB7187a7A5CC9663064323dE);

    // nile
    // address constant ValidatorAddr = address(0x0bbF3a187226e194CB1536875B0be85Cc8e8Af46); //TB3KWrE82z6hT5z5vaWPJuWGkf8muuSoev

    // ETH chain
    Types.ChainType constant ChainType = Types.ChainType.ETH;

    // TRX chain
    // Types.ChainType constant ChainType = Types.ChainType.TRX;
}
