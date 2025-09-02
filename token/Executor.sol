// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.20;

import "@openzeppelin/contracts@5.0.0/utils/math/Math.sol";
import "@openzeppelin/contracts@5.0.0/utils/Address.sol";
import {Types} from "../comn/Types.sol";
import {IPool} from "../comn/IPool.sol";
import {IMessager} from "../comn/IMessager.sol";
import {IToken} from "../comn/IToken.sol";
import {ComFunUtil} from "../comn/ComFunUtil.sol";
import {SafeERC20} from "../comn/SafeERC20.sol";
import {BridgeToken} from "./Token.sol";
import {Comn} from "./Comn.sol";

/**
 * @title Executor
 * @dev This contract inherits from the Comn contract and is mainly used to manage cross - chain token relationships,
 * create new tokens, handle cross - chain token bridging, and process messages.
 */
contract Executor is Comn {
    // Mapping from source chain ID to source token to relationship information.
    // It stores the relationship information between tokens on different source chains and tokens on the destination chain.
    mapping(uint => mapping(bytes32 => Types.RelationShipInfo))
        public tokenRelationshipMap;

    // Mapping from source chain ID to source token to source token information.
    // It stores relevant information about tokens on different source chains.
    mapping(uint => mapping(bytes32 => Types.SourceTokenInfo))
        public sourceTokenInfoMap;

    // Array that stores cross - chain relationship information.
    // It contains all the relevant information about cross - chain tokens.
    Types.CrossRelation[] public crossArr;

    // Mapping from the address of a new ERC20 token to its status.
    // It records newly created tokens and their status.
    mapping(address => uint) public newMintMap;

    // Mapping from chain ID to contract address.
    // It stores the contract addresses corresponding to different chains.
    mapping(uint => bytes32) public chainContractMap;

    // Mapping from chain ID to fee token address.
    // It stores the fee token addresses corresponding to different chains.
    mapping(uint => bytes32) public chainFeeTokenMap;

    event TokenRelationshipSet(
        uint indexed source_chain_id,
        bytes32 indexed source_token,
        uint8 source_token_decimals,
        address dest_token,
        uint8 dest_token_type
    );

    event TokenRelationshipRemoved(
        uint indexed source_chain_id,
        bytes32 indexed source_token
    );

    event LogBizData(uint128 indexed amount, bytes biz_data);

    /**
     * @dev Sets the contract address for a specified chain. This function can only be called by the administrator.
     * @param source_chain_id The ID of the source chain.
     * @param contract_addr The address of the contract.
     */
    function setChainContract(
        uint source_chain_id,
        bytes32 contract_addr
    ) public onlyAdmin {
        chainContractMap[source_chain_id] = contract_addr;
    }

    /**
     * @dev Sets the fee token address for a specified chain. This function can only be called by the administrator.
     * @param source_chain_id The ID of the source chain.
     * @param fee_token_addr The address of the fee token.
     */
    function setChainFeeToken(
        uint source_chain_id,
        bytes32 fee_token_addr
    ) public onlyAdmin {
        chainFeeTokenMap[source_chain_id] = fee_token_addr;
    }

    /**
     * @dev Sets the token relationship. Before setting the relationship, the pool or minted token must exist.
     * This function can only be called by the administrator.
     * @param source_chain_id The combined chain type and chain ID of the source chain.
     * @param source_token The source token in bytes32 format.
     * @param source_token_decimals The number of decimals of the source token.
     * @param _dest_token The destination token in bytes32 format.
     * @param dest_token_type The type of the destination token.
     */
    function setTokenRelationship(
        uint source_chain_id, // combain chain_type&chain_id
        bytes32 source_token,
        uint8 source_token_decimals,
        bytes32 _dest_token,
        uint8 dest_token_type
    ) public onlyAdmin {
        address dest_token = ComFunUtil.bytes32ToAddress(_dest_token);
        if (dest_token_type == uint8(Types.TokenType.pool)) {
            // 0 means pool map
            require(
                IPool(PoolAddr).getPoolInfo(dest_token).token != address(0),
                "no token for type 0"
            );
        } else {
            // 1 means mint token.
            require(newMintMap[dest_token] > 0, "no token for type 1");
        }
        require(
            tokenRelationshipMap[source_chain_id][source_token].dest_token ==
                address(0),
            "has been set"
        );

        tokenRelationshipMap[source_chain_id][source_token] = Types
            .RelationShipInfo(dest_token, dest_token_type);

        sourceTokenInfoMap[source_chain_id][source_token] = Types
            .SourceTokenInfo(1, source_token_decimals);

        crossArr.push(
            Types.CrossRelation(
                source_chain_id,
                source_token,
                source_token_decimals,
                dest_token,
                dest_token_type
            )
        );

        emit TokenRelationshipSet(
            source_chain_id,
            source_token,
            source_token_decimals,
            dest_token,
            dest_token_type
        );
    }

    /**
     * @dev Removes the token relationship. This function can only be called by the administrator.
     * @param source_chain_id The ID of the source chain.
     * @param source_token The source token in bytes32 format.
     */
    function removeTokenRelationship(
        uint source_chain_id,
        bytes32 source_token
    ) public onlyAdmin {
        // Types.RelationShipInfo memory data;
        delete tokenRelationshipMap[source_chain_id][source_token];
        delete sourceTokenInfoMap[source_chain_id][source_token];

        for (uint i = 0; i < crossArr.length; i++) {
            Types.CrossRelation memory data = crossArr[i];
            if (
                data.source_chain_id == source_chain_id &&
                data.source_token == source_token
            ) {
                crossArr[i] = crossArr[crossArr.length - 1];
                crossArr.pop();

                emit TokenRelationshipRemoved(source_chain_id, source_token);
                break;
            }
        }
    }

    /**
     * @dev Creates a new token for minting on the local chain. This function can only be called by the administrator.
     * @param name The name of the token.
     * @param symbol The symbol of the token.
     * @param decimals The number of decimals of the token.
     * @return The address of the newly created token.
     */
    function createNewToken(
        string memory name,
        string memory symbol,
        uint8 decimals
    ) public onlyAdmin returns (address) {
        BridgeToken newToken = new BridgeToken{salt: bytes32(0)}(
            name,
            symbol,
            decimals,
            address(this)
        );

        emit Types.Log("newToken", address(newToken));

        if (newMintMap[address(newToken)] != 0) {
            revert("token already in use");
        }
        newMintMap[address(newToken)] = 1;

        return address(newToken);
    }

    /**
     * @dev Bridges a token across chains.
     * @param source_token The source token in bytes32 format.
     * @param to_chain The destination chain information.
     * @param to_who The recipient in bytes32 format on the destination chain.
     * @param receiver The destination bridger in bytes32 format.
     * @param all_amount The total amount of tokens to be bridged.
     * @param upload_gas_fee The gas fee for uploading, converted from the target platform token to the source platform token.
     */
    function bridgeToken(
        bytes32 source_token,
        Types.Chain memory to_chain,
        bytes32 to_who,
        bytes32 receiver, // destination bridger
        uint128 all_amount,
        uint128 upload_gas_fee, // convert target platform token to source platform token
        bytes calldata biz_data
    ) public payable {
        uint all_value = msg.value;
        uint msger_value;

        // transfer gas fee to pool
        require(all_value >= upload_gas_fee, "please send enough gas");
        msger_value = all_value - upload_gas_fee;
        IPool(PoolAddr).sendEthFee{value: upload_gas_fee}(WTOKEN_ADDRESS);

        address source_address = ComFunUtil.bytes32ToAddress(source_token);
        // exist in poolMap
        if (IPool(PoolAddr).getPoolInfo(source_address).token != address(0)) {
            if (isWToken(source_address)) {
                require(
                    all_value >= all_amount + upload_gas_fee,
                    "please send enough value, or adjust amount"
                );
                msger_value = all_value - all_amount - upload_gas_fee;
                IPool(PoolAddr).sendEthFee{value: all_amount}(WTOKEN_ADDRESS);
            } else {
                SafeERC20.safeTransferFrom(
                    IToken(source_address),
                    msg.sender,
                    address(this),
                    all_amount
                );
                uint256 allowance = IToken(source_address).allowance(
                    address(this),
                    PoolAddr
                );
                if (allowance < all_amount) {
                    SafeERC20.safeIncreaseAllowance(
                        IToken(source_address),
                        PoolAddr,
                        type(uint256).max
                    );
                }
                IPool(PoolAddr).sendTokenFee(source_address, all_amount);
            }
        } else if (newMintMap[source_address] > 0) {
            // burn token.
            IToken tokenOp = IToken(source_address);
            tokenOp.burnFor(msg.sender, all_amount);
        } else {
            revert("source token not supported");
        }

        //  all amount = amount + platform_fee + upload_gas_fee * upload_fee_price
        bytes memory messageBody = abi.encodePacked(
            source_token, // source_token
            uint128(all_amount), // all_amount
            // upload_gas_fee, // upload_gas_fee
            ComFunUtil.addressToBytes32(address(msg.sender)), // from_who
            to_who, // to 
            biz_data
            // slipage
        );

        IMessager(MessagerAddr).emit_msg{value: msger_value}(
            0,
            to_chain,
            receiver,
            messageBody,
            upload_gas_fee
        );
    }

    /**
     * @dev Processes a received message.
     * @param message The received message.
     * @param signature The array of signatures for the message. Each signature is 65 bytes.
     * @return A boolean indicating whether the message was processed successfully.
     */
    function processMsg(
        Types.Message memory message,
        bytes[] memory signature // 65bytes for one signature
    ) public returns (bool) {
        
        (
            Types.MessageHeader memory msg_header,
            Types.BridgeMessageBody memory msg_body
        ) = decode_bridge_msg(message);


        uint from_chain = ComFunUtil.combainChain(msg_header.from_chain);
        require(
            address(this) == ComFunUtil.bytes32ToAddress(msg_header.receiver),
            "processMsg receiver error"
        );
        require(
            chainContractMap[from_chain] == msg_header.sender,
            "processMsg sender error"
        );

        bytes32 source_token = msg_body.source_token;
        (
            bool exist,
            Types.RelationShipInfo memory tokenRInfo
        ) = getStrictTokenRelationship(from_chain, source_token);

        if (!exist) {
            revert("no token relation ship");
        }

        bool consume_success = IMessager(MessagerAddr).consume_bridge_msg(
            message,
            signature
        );
        if (
            !consume_success &&
            msg.sender != address(0x0000000000000000000000000000000000000001)
        ) {
            revert("nonce has been uploaded");
        }

        // amount decimal process
        bytes32 to_who = msg_body.to_who;
        uint all_amount = msg_body.all_amount;
        Types.SourceTokenInfo
            memory source_token_info = getStrictSourceTokenInfo(
                from_chain,
                source_token
            );
        IToken tokenOp = IToken(tokenRInfo.dest_token);
        uint8 dest_decimals = tokenOp.decimals();

        if (dest_decimals > source_token_info.decimals) {
            all_amount =
                all_amount *
                10 ** (dest_decimals - source_token_info.decimals);
        } else if (dest_decimals < source_token_info.decimals) {
            all_amount =
                all_amount /
                10 ** (source_token_info.decimals - dest_decimals);
        }

        if (tokenRInfo.dest_token_type == uint8(Types.TokenType.pool)) {
            IPool(PoolAddr).transferFromPool(
                tokenRInfo.dest_token,
                ComFunUtil.bytes32ToAddress(to_who),
                all_amount
            );
        } else {
            // only mint token
            BridgeToken destTokenOp = BridgeToken(tokenRInfo.dest_token);
            destTokenOp.mintFor(
                ComFunUtil.bytes32ToAddress(to_who),
                all_amount
            );
        }

        {
            // mint gas_fee to sender
            uint128 gas_fee = msg_header.upload_gas_fee;
            if (gas_fee > 0) {
                emit Types.Log("send gas fee to sender", gas_fee);
                bytes32 fee_token = chainFeeTokenMap[from_chain];
                (exist, tokenRInfo) = getStrictTokenRelationship(
                    from_chain,
                    fee_token
                );
                if (!exist) {
                    revert("no token relation ship for fee token");
                }
                Types.SourceTokenInfo
                    memory fee_token_info = getStrictSourceTokenInfo(
                        from_chain,
                        fee_token
                    );
                tokenOp = IToken(tokenRInfo.dest_token);
                uint8 fee_dest_decimals = tokenOp.decimals();

                if (fee_dest_decimals > fee_token_info.decimals) {
                    gas_fee = uint128(
                        uint(gas_fee) *
                            10 ** (fee_dest_decimals - fee_token_info.decimals)
                    );
                } else if (fee_dest_decimals < source_token_info.decimals) {
                    gas_fee = uint128(
                        uint(gas_fee) /
                            10 ** (fee_token_info.decimals - fee_dest_decimals)
                    );
                }

                if (tokenRInfo.dest_token_type == uint8(Types.TokenType.pool)) {
                    IPool(PoolAddr).transferFeeToRelay(
                        tokenRInfo.dest_token,
                        msg.sender,
                        gas_fee
                    );
                } else {
                    BridgeToken destTokenOp = BridgeToken(
                        tokenRInfo.dest_token
                    );
                    destTokenOp.mintFor(msg.sender, gas_fee);
                }
            }
        }

        // Check if biz_data has value and call it directly in the contract
        if (msg_body.biz_data.length > 0) {
            emit LogBizData(msg_body.all_amount, msg_body.biz_data);
        }

        return true;

    }

    /**
     * @dev Calculates the LP fee and the final amount after fee deduction.
     * @param source_chain_id The ID of the source chain.
     * @param source_token The source token in bytes32 format.
     * @param all_amount The total amount of tokens.
     * @return lp_fee The LP fee and the final amount after fee deduction.
     */
    function getLpFeeAndFinalAmount(
        uint source_chain_id,
        bytes32 source_token,
        uint all_amount
    ) public view returns (uint lp_fee, uint final_amount) {
        (
            bool exist,
            Types.RelationShipInfo memory tokenRInfo
        ) = getStrictTokenRelationship(source_chain_id, source_token);
        if (!exist) {
            return (0, 0);
        }
        if (tokenRInfo.dest_token_type == uint8(Types.TokenType.pool)) {
            uint pool_fee = IPool(PoolAddr).getLpFee(
                tokenRInfo.dest_token,
                all_amount
            );
            uint amount = all_amount - pool_fee;
            return (pool_fee, amount);
        } else {
            return (0, all_amount);
        }
    }

    /**
     * @dev Decodes a bridge message.
     * @param decMsg The message to be decoded.
     * @return The message header and the bridge message body.
     */
    function decode_bridge_msg(
        Types.Message memory decMsg
    )
        public
        pure
        returns (Types.MessageHeader memory, Types.BridgeMessageBody memory)
    {
        Types.BridgeMessageBody memory bridgeMsgBody = IMessager(MessagerAddr)
            .decode_bridge_msg_body(decMsg.msg_body);

        return (decMsg.msg_header, bridgeMsgBody);
    }

    /**
     * @dev Retrieves all cross - chain relationship information.
     * @return An array containing all cross - chain relationship information.
     */
    function getAllCrossRelation()
        public
        view
        returns (Types.CrossRelation[] memory)
    {
        return crossArr;
    }

    /**
     * @dev Retrieves the token relationship information.
     * @param source_chain_id The ID of the source chain.
     * @param source_token The source token in bytes32 format.
     * @return A boolean indicating whether the relationship exists and the relationship information.
     */
    function getTokenRelationship(
        uint source_chain_id,
        bytes32 source_token
    ) public view returns (bool, Types.RelationShipInfo memory) {
        Types.RelationShipInfo memory data = tokenRelationshipMap[
            source_chain_id
        ][source_token];
        if (data.dest_token == address(0)) {
            return (false, data);
        }
        return (true, data);
    }

    /**
     * @dev Retrieves the strict token relationship information. Checks if the destination token exists in the pool or mint map.
     * @param source_chain_id The ID of the source chain.
     * @param source_token The source token in bytes32 format.
     * @return A boolean indicating whether the relationship exists and the relationship information.
     */
    function getStrictTokenRelationship(
        uint source_chain_id,
        bytes32 source_token
    ) public view returns (bool, Types.RelationShipInfo memory) {
        Types.RelationShipInfo memory data = tokenRelationshipMap[
            source_chain_id
        ][source_token];
        if (data.dest_token == address(0)) {
            return (false, data);
        }

        if (data.dest_token_type == uint8(Types.TokenType.pool)) {
            if (
                IPool(PoolAddr).getPoolInfo(data.dest_token).token == address(0)
            ) {
                return (false, data);
            }
        } else {
            if (newMintMap[data.dest_token] == 0) {
                return (false, data);
            }
        }

        return (true, data);
    }

    /**
     * @dev Retrieves the source token information.
     * @param source_chain_id The ID of the source chain.
     * @param source_token The source token in bytes32 format.
     * @return The source token information.
     */
    function getSourceTokenInfo(
        uint source_chain_id,
        bytes32 source_token
    ) public view returns (Types.SourceTokenInfo memory) {
        return sourceTokenInfoMap[source_chain_id][source_token];
    }

    /**
     * @dev Retrieves the strict source token information. Ensures the source token information is initialized.
     * @param source_chain_id The ID of the source chain.
     * @param source_token The source token in bytes32 format.
     * @return rs The source token information. Reverts if the information is not initialized.
     */
    function getStrictSourceTokenInfo(
        uint source_chain_id,
        bytes32 source_token
    ) public view returns (Types.SourceTokenInfo memory rs) {
        rs = sourceTokenInfoMap[source_chain_id][source_token];
        if (rs.initialized == 0) {
            revert("source token info is empty");
        }
    }

    /**
     * @dev Checks if a given token is the wrapped token.
     * @param token The address of the token to check.
     * @return A boolean indicating whether the token is the wrapped token.
     */
    function isWToken(address token) public pure returns (bool) {
        return token == WTOKEN_ADDRESS;
    }
}
