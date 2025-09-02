// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.20;

import "./Types.sol";

interface IPool {
    function createPool(
        address token // already exist in chain.
    ) external;

    // stake into pool and record some information. no lp will be created.
    // use msg.sender as staker
    function stakeIntoPool(address stakeToken, uint amount) external payable;

    // we use msg.sender and get the amount
    function withdrawFromPool(address stakeToken, uint amount) external;

    // only withdraw the bonus.
    function withdrawBonusFromPool(address stakeToken, uint amount) external;

    function getPoolInfo(
        address stakeToken
    ) external view returns (Types.PoolInfo memory);

    function getAllPoolsInfo()
        external
        view
        returns (Types.PoolInfo[] memory rs);

    function getAllUserStakeInfo(
        address user
    ) external view returns (Types.UserAmountInfoForViewV2[] memory);

    function transferFromPool(
        address destToken,
        address toWho,
        uint allAmount
    ) external;

    function calBonusFromPool(
        address user,
        address stakeToken
    ) external view returns (uint bonus);

    function getLpFee(address token, uint amount) external view returns (uint);

    function sendEthFee(address token) external payable;

    function sendTokenFee(address token, uint amount) external;

    function withdrawFee(address token, uint amount) external;

    function transferFeeToRelay(
        address token,
        address relay,
        uint amount
    ) external;
}
