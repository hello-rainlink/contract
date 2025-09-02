// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.20;

import "@openzeppelin/contracts@5.0.0/utils/structs/EnumerableSet.sol";
import "@openzeppelin/contracts@5.0.0/utils/Address.sol";
import "@openzeppelin/contracts@5.0.0/utils/math/Math.sol";
import {Types} from "../comn/Types.sol";
import {IToken} from "../comn/IToken.sol";
import {ComFunUtil} from "../comn/ComFunUtil.sol";
import {SafeERC20} from "../comn/SafeERC20.sol";
import {Comn} from "./Comn.sol";

/**
 * @title Pool
 * @dev This contract manages a pool of tokens. It allows users to stake tokens, withdraw tokens,
 * earn bonuses, and provides functions for pool management and fee handling.
 */
contract Pool is Comn {
    // Constant representing the pool fee rate. The value is divided by 1000000 to get the actual rate.
    uint constant POOL_FEE = 3000;

    using EnumerableSet for EnumerableSet.AddressSet;
    // Mapping from user address to the prepaid amount of native tokens (ticket).
    // It won't record how many tokens the user has; other places will handle that.
    mapping(address => uint) private _userPayTicket; // native token prepay amount ticket

    // Mapping from token address to the total remaining amount of the token in the pool.
    // The remaining token is the locked amount, and users can withdraw it.
    mapping(address => uint) private _tokenTotalRemainAmount;

    // Mapping from user address to a set of token addresses that the user has staked.
    mapping(address => EnumerableSet.AddressSet) private userStakeTokenSet;

    // Total prepaid amount of native tokens (all tickets).
    uint private allPayTicket;

    // Mapping from token address to the pool information of that token.
    mapping(address => Types.PoolInfo) public poolMap;

    // Array of token addresses representing all the pools.
    address[] public poolArr;

    // Mapping from user address to another mapping from token address to the user's staked amount information.
    mapping(address => mapping(address => Types.UserAmountInfo))
        public userStakeAmountMap;

    // Mapping from user address to another mapping from token address to the user's locked amount information.
    mapping(address => mapping(address => Types.UserAmountInfo))
        public userLockAmountMap;

    // Mapping from token address to the platform fee amount for that token.
    mapping(address => uint) public feeAmountMap;

    // Mapping from token address to the pool fee rate. The value is divided by 1000000 to get the actual rate.
    mapping(address => uint) public poolFeeMap;

    /**
     * @dev Modifier that restricts a function to be called only by the executor.
     * Throws an error if the caller is not the executor.
     */
    modifier onlyExecutor() {
        require(ExecutorAddr == msg.sender, "Must executor");
        _;
    }

    /**
     * @dev Creates a new pool for a given token.
     * Only the administrator can call this function.
     * @param token The address of the token for which the pool is to be created.
     */
    function createPool(address token) public onlyAdmin {
        // Create an instance of the IToken interface for the given token.
        IToken tokenOp = IToken(token);
        // Try to get the decimals of the token to check if it is a valid token.
        tokenOp.decimals();

        // Check if the pool for the given token already exists.
        if (poolMap[token].token != address(0)) {
            revert("already created");
        }

        // Create a new PoolInfo struct for the token.
        Types.PoolInfo memory p;
        p.token = token;
        // Add the pool information to the poolMap.
        poolMap[token] = p;

        // Add the token address to the poolArr.
        poolArr.push(token);
    }

    /**
     * @dev Removes a pool for a given token.
     * Only the administrator can call this function.
     * @param token The address of the token for which the pool is to be removed.
     */
    function removePool(address token) public onlyAdmin {
        // Check if the pool for the given token exists.
        if (poolMap[token].token == address(0)) {
            revert("Pool does not exist");
        }

        // Check if the pool has any staked tokens or locked tokens.
        if (poolMap[token].inAmount != 0 || poolMap[token].acc != 0) {
            revert("Cannot remove pool: inAmount or acc is not zero");
        }

        // Remove the token from the poolArr.
        for (uint256 i = 0; i < poolArr.length; i++) {
            if (poolArr[i] == token) {
                // Copy the last element to the current index.
                poolArr[i] = poolArr[poolArr.length - 1];
                // Remove the last element from the array.
                poolArr.pop();
                break;
            }
        }

        // Delete the pool information from the poolMap.
        delete poolMap[token];
    }

    /**
     * @dev Sets the pool fee for a given token.
     * Only the administrator can call this function.
     * @param token The address of the token for which the pool fee is to be set.
     * @param feeRate The pool fee rate. this value is divided by 1000000 to get the actual rate.
     */
    function setPoolFeeRate(address token, uint feeRate) public onlyAdmin {
        require(feeRate <= 1000000, "fee rate too high");
        poolFeeMap[token] = feeRate;
    }

    /**
     * @dev Allows a user to stake tokens into a pool.
     * @param stakeToken The address of the token to be staked.
     * @param amount The amount of tokens to be staked.
     */
    function stakeIntoPool(address stakeToken, uint amount) public payable {
        // Check if the pool for the given token exists.
        if (poolMap[stakeToken].token == address(0)) {
            revert("pool not found");
        }

        // Ensure the staked amount is greater than zero.
        require(amount > 0, "amount is zero");

        // If the token is a wrapped token (WTOKEN_ADDRESS), check if the user sent enough Ether.
        if (isWToken(stakeToken)) {
            require(
                msg.value >= amount,
                "please send enough gas, or adjust amount"
            );
        } else {
            // Transfer the tokens from the user to the contract.
            SafeERC20.safeTransferFrom(
                IToken(stakeToken),
                msg.sender,
                address(this),
                amount
            );
        }

        // Add the token to the user's staked token set.
        userStakeTokenSet[msg.sender].add(stakeToken);
        // Add the staked amount to the pool.
        _addStakeAmount(stakeToken, amount);
    }

    /**
     * @dev Allows a user to withdraw tokens from a pool.
     * @param stakeToken The address of the token to be withdrawn.
     * @param amount The amount of tokens to be withdrawn.
     */
    function withdrawFromPool(address stakeToken, uint amount) public payable {
        // Check if the pool for the given token exists.
        if (poolMap[stakeToken].token == address(0)) {
            revert("pool not found");
        }

        // Ensure the withdrawn amount is greater than zero.
        require(amount > 0, "amount is zero");

        // Remove the staked amount from the pool.
        _removeStakeAmount(stakeToken, amount);

        // If the token is a wrapped token (WTOKEN_ADDRESS), send Ether to the user.
        if (isWToken(stakeToken)) {
            Address.sendValue(payable(msg.sender), amount);
        } else {
            // Transfer the tokens from the contract to the user.
            SafeERC20.safeTransfer(IToken(stakeToken), msg.sender, amount);
        }
    }

    /**
     * @dev Allows a user to withdraw the bonus from a pool.
     * @param stakeToken The address of the token from which the bonus is to be withdrawn.
     * @param amount The amount of bonus to be withdrawn.
     */
    function withdrawBonusFromPool(address stakeToken, uint amount) public {
        // Check if the pool for the given token exists.
        if (poolMap[stakeToken].token == address(0)) {
            revert("pool not found");
        }

        require(amount > 0, "amount is zero");
        address user = msg.sender;
        
        // Calculate the bonus amount.
        uint bonus = calBonusFromPool(user, stakeToken);
        require(bonus > 0, "bonus is zero");

        // If there is a bonus, proceed with the withdrawal.
        emit Types.Log("wd bonus", bonus);
        // Reset the bonus information.
        _resetBonus(stakeToken, amount);

        // Decrease the total amount in the pool.
        poolMap[stakeToken].inAmount -= amount;

        // If the token is a wrapped token (WTOKEN_ADDRESS), send Ether to the user.
        if (isWToken(stakeToken)) {
            Address.sendValue(payable(user), amount);
        } else {
            // Transfer the tokens from the contract to the user.
            SafeERC20.safeTransfer(IToken(stakeToken), user, amount);
        }
    }

    /**
     * @dev Allows the executor to transfer tokens from the pool to a destination address.
     * @param destToken The address of the token to be transferred.
     * @param toWho The address of the recipient.
     * @param allAmount The total amount of tokens to be transferred.
     */
    function transferFromPool(
        address destToken,
        address toWho,
        uint allAmount
    ) public payable onlyExecutor {
        // Calculate the LP fee.
        uint lp_fee = getLpFee(destToken, allAmount);
        // Calculate the actual amount to be transferred after deducting the fee.
        uint amount = allAmount - lp_fee;
        if (isWToken(destToken)) {
            Address.sendValue(payable(toWho), amount);
        } else {
            SafeERC20.safeTransfer(IToken(destToken), toWho, amount);
        }

        // Calculate the pool fee.
        uint pool_fee = Math.mulDiv(
            lp_fee,
            poolMap[destToken].amount,
            poolMap[destToken].inAmount
        );

        // Calculate the decrease in the staked amount.
        uint stakedDecrease = (allAmount * poolMap[destToken].amount) /
            poolMap[destToken].inAmount;
        require(
            stakedDecrease <= poolMap[destToken].amount,
            "pool amount insufficient for transfer"
        );

        // Decrease the staked amount in the pool.
        poolMap[destToken].amount -= stakedDecrease;
        // Decrease the total amount in the pool.
        poolMap[destToken].inAmount -= allAmount;
        // Return the remaining pool fee
        poolMap[destToken].inAmount += (lp_fee - pool_fee);

        // Get a reference to the pool information.
        Types.PoolInfo storage poolInfo = poolMap[destToken];
        // If there is a staked amount in the pool, update the reward amount and APY.
        if (poolInfo.stakeAmount > 0) {
            poolInfo.rewardAmount += pool_fee;
            if (pool_fee > 0 && poolInfo.stakeAmount > 0) {
                uint acc_percentage = (pool_fee * (1 << 64)) /
                    poolInfo.stakeAmount;
                emit Types.Log("acc_percentage", acc_percentage);
                poolInfo.acc += acc_percentage;
                // cal the apy
                if (poolInfo.last_receive_rewards_time == 0) {
                    poolInfo.last_apy = acc_percentage;
                    poolInfo.last_receive_rewards_time = ComFunUtil
                        .currentTimestamp();
                } else {
                    uint now_secs = ComFunUtil.currentTimestamp();
                    uint delta = now_secs - poolInfo.last_receive_rewards_time;
                    if (delta > 0) {
                        poolInfo.last_apy =
                            (acc_percentage * 365 * 24 * 60 * 60) /
                            delta;
                        poolInfo.last_receive_rewards_time = now_secs;
                    }
                }
            }
        }
    }

    /**
     * @dev Calculates the bonus amount for a user in a given pool.
     * @param user The address of the user.
     * @param stakeToken The address of the token in the pool.
     * @return The calculated bonus amount.
     */
    function calBonusFromPool(
        address user,
        address stakeToken
    ) public view returns (uint) {
        // Get the user's staked amount information.
        Types.UserAmountInfo memory uInfo = userStakeAmountMap[user][
            stakeToken
        ];
        // Calculate the new reward.
        uint newReward = (uInfo.amount * poolMap[stakeToken].acc) >> 64;
        // Calculate the total bonus.
        return newReward + uInfo.remainReward - uInfo.debt;
    }

    /**
     * @dev Calculates the LP fee for a given token and amount.
     * @param token The address of the token.
     * @param amount The amount of tokens.
     * @return The calculated LP fee.
     */
    function getLpFee(address token, uint amount) public view returns (uint) {
        uint feeRate = poolFeeMap[token];
        uint pool_fee_all = Math.mulDiv(amount, feeRate, 1000000);
        return pool_fee_all;
    }

    /**
     * @dev Retrieves the pool information for a given token.
     * @param stakeToken The address of the token.
     * @return The pool information struct.
     */
    function getPoolInfo(
        address stakeToken
    ) public view returns (Types.PoolInfo memory) {
        return poolMap[stakeToken];
    }

    /**
     * @dev Retrieves the information of all pools.
     * @return rs An array of pool information structs.
     */
    function getAllPoolsInfo()
        public
        view
        returns (Types.PoolInfo[] memory rs)
    {
        rs = new Types.PoolInfo[](poolArr.length);
        for (uint i = 0; i < poolArr.length; i++) {
            rs[i] = poolMap[poolArr[i]];
        }
    }

    /**
     * @dev Retrieves the staked information of all tokens for a given user.
     * @param user The address of the user.
     * @return An array of user staked amount information structs for view.
     */
    function getAllUserStakeInfo(
        address user
    ) public view returns (Types.UserAmountInfoForViewV2[] memory) {
        // Get the user's staked token set.
        EnumerableSet.AddressSet storage stakeSet = userStakeTokenSet[user];
        // Get the number of staked tokens.
        uint len = stakeSet.length();
        // Create an array to store the user staked amount information for view.
        Types.UserAmountInfoForViewV2[]
            memory uai = new Types.UserAmountInfoForViewV2[](len);
        // Get the array of staked token addresses.
        address[] memory values = stakeSet.values();
        for (uint i = 0; i < len; i++) {
            // Get the address of the staked token.
            address stakeToken = values[i];
            // Calculate the bonus amount.
            uint bonus = calBonusFromPool(user, stakeToken);
            // Get the user's staked amount information.
            Types.UserAmountInfo memory userStakeInfo = userStakeAmountMap[
                user
            ][stakeToken];
            // Populate the array with the user staked amount information for view.
            uai[i] = Types.UserAmountInfoForViewV2({
                token: userStakeInfo.token,
                amountType: userStakeInfo.amountType,
                amount: userStakeInfo.amount,
                debt: userStakeInfo.debt,
                remainReward: userStakeInfo.remainReward,
                acc: poolMap[stakeToken].acc,
                bonus: bonus,
                earns: bonus
            });
        }

        return uai;
    }

    /**
     * @dev Checks if a given token is a wrapped token (WTOKEN_ADDRESS).
     * @param token The address of the token.
     * @return A boolean indicating whether the token is a wrapped token.
     */
    function isWToken(address token) public pure returns (bool) {
        return token == WTOKEN_ADDRESS;
    }

    /**
     * @dev Allows a user to send Ether as a fee for a given token.
     * @param stakeToken The address of the token.
     */
    function sendEthFee(address stakeToken) public payable {
        // Get the amount of Ether sent.
        uint amount = msg.value;
        // Add the locked amount to the pool.
        _addLockAmount(stakeToken, amount);
    }

    /**
     * @dev Allows a user to send tokens as a fee.
     * @param token The address of the token.
     * @param amount The amount of tokens to be sent.
     */
    function sendTokenFee(address token, uint amount) public {
        // Check if the pool for the given token exists.
        require(poolMap[token].token != address(0), "pool not found");

        // Transfer the tokens from the user to the contract.
        SafeERC20.safeTransferFrom(
            IToken(token),
            msg.sender,
            address(this),
            amount
        );
        // Add the locked amount to the pool.
        _addLockAmount(token, amount);
    }

    /**
     * @dev Allows the executor to transfer the fee to a relay address.
     * @param token The address of the token.
     * @param relay The address of the relay.
     * @param amount The amount of tokens to be transferred.
     */
    function transferFeeToRelay(
        address token,
        address relay,
        uint amount
    ) public onlyExecutor {
        // Decrease the total amount in the pool.
        poolMap[token].inAmount -= amount;
        // Decrease the locked amount in the pool.
        poolMap[token].lockAmount -= amount;
        // Transfer the tokens from the contract to the relay.
        SafeERC20.safeTransfer(IToken(token), relay, amount);
    }

    /**
     * @dev Adds the staked amount to the pool and updates the user's staked amount information.
     * @param token The address of the token.
     * @param amount The amount of tokens to be staked.
     */
    function _addStakeAmount(address token, uint amount) private {
        poolMap[token].amount += amount;
        poolMap[token].inAmount += amount;
        poolMap[token].stakeAmount += amount;
        address user = msg.sender;

        // Check if this is the first time the user stakes this token.
        if (userStakeAmountMap[user][token].token == address(0)) {
            // If it's the first time, initialize the token and set the amount type to 1 (stake value).
            userStakeAmountMap[user][token].token = token;
            userStakeAmountMap[user][token].amountType = 1;
        }

        // Increase the user's staked amount.
        userStakeAmountMap[user][token].amount += amount;
        // Calculate the new debt based on the staked amount and the current accumulated value.
        uint newDebt = (amount * poolMap[token].acc) >> 64;
        // Increase the user's debt.
        userStakeAmountMap[user][token].debt += newDebt;
    }

    /**
     * @dev Removes the staked amount from the pool and updates the user's staked amount information.
     * Also calculates and updates the user's remaining reward.
     * @param token The address of the token.
     * @param amount The amount of tokens to be removed from the stake.
     */
    function _removeStakeAmount(address token, uint amount) private {
        address user = msg.sender;
        uint userAllAmount = userStakeAmountMap[user][token].amount;
        require(amount <= userAllAmount, "not enough user assets");
        userStakeAmountMap[user][token].amount -= amount;

        require(amount <= poolMap[token].inAmount, "not enough pool assets");
        require(
            amount <= poolMap[token].stakeAmount,
            "not enough pool stakeAmount assets"
        );

        uint userStakeRatio = (userAllAmount * 1e18) /
            poolMap[token].stakeAmount;
        uint withdrawRatio = (amount * 1e18) / userAllAmount;
        uint stakedDecrease = (poolMap[token].amount * userStakeRatio) / 1e18;
        stakedDecrease = (stakedDecrease * withdrawRatio) / 1e18;
        require(
            stakedDecrease <= poolMap[token].amount,
            "pool amount insufficient for withdrawal"
        );
        
        poolMap[token].amount -= stakedDecrease;
        poolMap[token].inAmount -= amount;
        poolMap[token].stakeAmount -= amount;

        // Calculate the new reward based on the withdrawn amount and the current accumulated value.
        uint newReward = (amount * poolMap[token].acc) >> 64;
        uint partDebt = (userStakeAmountMap[user][token].debt * amount) /
            userAllAmount;
        if (newReward > partDebt) {
            userStakeAmountMap[user][token].remainReward +=
                newReward -
                partDebt;
        }

        // Decrease the user's debt.
        userStakeAmountMap[user][token].debt -= partDebt;
    }

    /**
     * @dev Adds the locked amount to the pool and updates the fee amount map.
     * @param token The address of the token.
     * @param amount The amount of tokens to be locked.
     */
    function _addLockAmount(address token, uint amount) private {
        // Increase the total amount in the pool.
        poolMap[token].inAmount += amount;
        // Increase the locked amount in the pool.
        poolMap[token].lockAmount += amount;
        // Increase the platform fee amount for the token.
        feeAmountMap[token] += amount;
    }

    /**
     * @dev Resets the user's bonus information after a bonus withdrawal.
     * @param token The address of the token.
     * @param amount_ The amount of bonus to be withdrawn.
     */
    function _resetBonus(address token, uint amount_) private {
        address user = msg.sender;
        uint amount = userStakeAmountMap[user][token].amount;
        uint newDebt = (amount * poolMap[token].acc) >> 64;

        // Calculate the total reward the user has earned.
        uint totalReward = newDebt -
            userStakeAmountMap[user][token].debt +
            userStakeAmountMap[user][token].remainReward;
        // Check if the user has enough reward.
        require(totalReward  >= amount_, "not enough reward");
        uint newReward = totalReward - amount_;

        // Update the user's remaining reward and debt.
        userStakeAmountMap[user][token].remainReward = newReward;
        userStakeAmountMap[user][token].debt = newDebt;
    }
}