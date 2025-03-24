// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.20;

import "../BaseComn.sol";

/**
 * @title all sol extends from this
 * @dev Extends BaseComn with additional address constants
 */
abstract contract Comn is BaseComn {
    // xone
    address constant WTOKEN_ADDRESS = 0x912A11C41d0D79c8466574d4C03cE68990dB713B;
    address constant PoolAddr = address(0x980A65A374911f7c35E3f471e5a06FAfEa713d67);
    address constant ExecutorAddr = address(0x237aeC76ED2bECC3e5df4f007F6E67CC2EAe68e9);
    address constant MessagerAddr = address(0x57F0aa8205Ac7692b5C8537e187a3063132046E1);

    // tbsc
    // address constant WTOKEN_ADDRESS = 0xae13d989daC2f0dEbFf460aC112a837C89BAa7cd;
    // address constant PoolAddr = 0xbbc9C2C381588Caba7D9799201e1D93e87b72A01;
    // address constant ExecutorAddr = 0x3BCD6c66f8A9B7460ce7A87C71FaBBA49F288B34;
    // address constant MessagerAddr = 0x69ab12C5F2BcCeb6f54DB683b1e50dd9A4d659ee;

    // sepolia
    // address constant WTOKEN_ADDRESS = 0xfFf9976782d46CC05630D1f6eBAb18b2324d6B14;
    // address constant PoolAddr = address(0x14F14e1FCBC4d9d83A7d18bcaCdE08e8B0133F35);
    // address constant ExecutorAddr = address(0xB2A222c5F92fDc233D9c886a775e7d0c962f5f43);
    // address constant MessagerAddr = address(0x9E03592d2db1B73fa83663894B7D0501a6b25979);

    // nile
    // address constant WTOKEN_ADDRESS = 0xfb3b3134F13CcD2C81F4012E53024e8135d58FeE; //TYsbWxNnyTgsZaTFaue9hqpxkU3Fkco94a
    // address constant PoolAddr = address(0x8C4547F033D6E2F87c30a21b40BA1433Ee5B7375); //TNktbeKB7Ji8LdzjGFMgzk7oSGFBZMPeqL
    // address constant ExecutorAddr = address(0x35184357cd32c6673409FfB78eF3BcD536F331b3); //TEowt427KJ1HWq22Q15HWAJP715xXbf3Um
    // address constant MessagerAddr = address(0xA83d811C387302e236BA81D8D06FD0543F636597); //TRJnCgZ2tu3YtJKYmN9owZ72PkjX7Z7Hav
}
