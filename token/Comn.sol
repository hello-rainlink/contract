// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.20;

import "../BaseComn.sol";

/**
 * @title all sol extends from this
 * @dev Extends BaseComn with additional address constants
 */
abstract contract Comn is BaseComn {
    // xone
    address constant WTOKEN_ADDRESS = address(0x912A11C41d0D79c8466574d4C03cE68990dB713B);
    address constant PoolAddr = address(0x52D4C1A6A69274afEe28C1A85e083357a9a1ffb2);
    address constant ExecutorAddr = address(0x0D193a0B5f6Dc2f7c579219067DcD00df67241a1);
    address constant MessagerAddr = address(0x46CE5d59b7aFfd84f97D4868814AF2cb7c9133d1);

    // tbsc
    // address constant WTOKEN_ADDRESS = address(0xae13d989daC2f0dEbFf460aC112a837C89BAa7cd);
    // address constant PoolAddr = address(0x38f9c465128F3139Ca70707eA7232568aC89C42B);
    // address constant ExecutorAddr = address(0xc8C4087c56B47e4658F54b925aF607118D461798);
    // address constant MessagerAddr = address(0xF2B99D50bdb83110aBf94cA7cD98057E95302D83);

    // sepolia
    // address constant WTOKEN_ADDRESS = address(0xfFf9976782d46CC05630D1f6eBAb18b2324d6B14);
    // address constant PoolAddr = address(0x5Dab805f174FA4e66aeE1947978e055C61e16AB2);
    // address constant ExecutorAddr = address(0x3B43c5B5c83b683ecE682e4ed8a75ec81BB55248);
    // address constant MessagerAddr = address(0xb2E08E9840Cd02dE0002189BBd2Bc24333a7c9D2);

    // nile
    // address constant WTOKEN_ADDRESS = address(0xfb3b3134F13CcD2C81F4012E53024e8135d58FeE); //TYsbWxNnyTgsZaTFaue9hqpxkU3Fkco94a
    // address constant PoolAddr = address(0x273Ea2807918A51D7e4D0E47779365391105eFa4); //TDYiPUqKWvFSu3qpgTP4ctNXPQqaxPnJXp
    // address constant ExecutorAddr = address(0x7b6229abeE4D531D7ae82b00f5b8F52D0a5764EB); //TMDbi88CTghZj88NbGKn4NPnzWptrH453B
    // address constant MessagerAddr = address(0x181Ff0aEd1d4a5829936322363D992D570c8f0c3); //TCAmUuRamPsA5m862JQUpDaJkDTGznpV6y
}
