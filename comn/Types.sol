// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.20;

// all data in this file we should remain static.
// as this file may be used when create empty StoreHouse. to avoid any data not being initialized. we should keet it static.

library Types {
    event Log(string);
    event Log(string, bytes);
    event Log(uint);
    event Log(string, uint);
    event Log(string, bytes32);
    event Log(string, bytes32, uint);
    event Log(string, address);

    struct PoolInfo {
        address token;
        uint amount; // actual remain amount.
        uint inAmount; // all in token = all in lock amount + all in stake amount.
        uint lockAmount; // actual locked by contract
        uint stakeAmount; // actual user stake into contract.
        uint rewardAmount; // reward for staker, will used in future. now all reward will added to stake amount.
        uint acc; // Q64.64
        uint last_apy; // Q64.64
        uint last_receive_rewards_time;
    }

    enum AmountType {
        locked,
        staked
    }

    enum TokenType {
        pool,
        mint
    }

    struct UserAmountInfo {
        address token;
        uint8 amountType; // 0 locked value. 1 staked value.
        uint amount;
        uint debt;
        uint remainReward;
        // for locked user. all amount = amount
        // for stake user all amount = amount*acc - debt + amount + remainReward
    }

    // for front end.
    struct UserAmountInfoForView {
        address token;
        uint8 amountType; // 0 locked value. 1 staked value.
        uint amount;
        uint debt;
        uint remainReward;
        uint acc;
        uint bonus;
        // for locked user. all amount = amount
        // for stake user all amount = amount*acc - debt + amount + remainReward
    }

    // for front end.
    struct UserAmountInfoForViewV2 {
        address token;
        uint8 amountType; // 0 locked value. 1 staked value.
        uint amount;
        uint debt;
        uint remainReward;
        uint acc;
        uint bonus;
        // for locked user. all amount = amount
        // for stake user all amount = amount*acc - debt + amount + remainReward
        uint earns;
    }

    struct FromSource {
        uint source_chain_id;
        bytes32 source_token;
    }

    struct RelationShipInfo {
        address dest_token;
        uint8 dest_token_type; // 0 for pool, 1 for new mint
    }

    struct SourceTokenInfo {
        uint8 initialized;
        uint8 decimals; // record the decimals for source token
    }

    struct CrossRelation {
        uint source_chain_id;
        bytes32 source_token;
        uint8 source_token_decimals;
        address dest_token;
        uint8 dest_token_type;
    }

    struct MessageMeta {
        // BridgeMessage bridgeMsg;
        // // other fields
        uint8 status; //
        uint[4] reserves;
    }

    struct Chain {
        uint8 chain_type;
        uint64 chain_id;
    }

    enum ChainType {
        ETH,
        TRX,
        SOL
    }

    struct Message {
        MessageHeader msg_header;
        bytes msg_body;
    }

    struct MessageHeader {
        uint8 msg_type; // 0 means bridge message
        uint64 nonce;
        Chain from_chain; //
        bytes32 sender;
        // address messager;
        Chain to_chain; //
        bytes32 receiver;
        uint128 upload_gas_fee;
    }

    struct BridgeMessageBody {
        // body
        bytes32 source_token;
        uint128 all_amount;
        // uint amount;
        // uint platform_fee;

        // uint upload_fee_price; // all amount = amount + platform_fee + upload_gas_fee * upload_fee_price
        bytes32 from_who;
        bytes32 to_who;
        bytes biz_data;
        // uint slipage;
    }

    struct ERC20Permit {
        address owner;
        address spender;
        uint256 value;
        uint256 deadline;
        uint8 v;
        bytes32 r;
        bytes32 s;
    }

    struct UserWithdrawData {
        address token;
        uint amount; // uni decimal.
        // string symbol;
    }

    struct UserWithdrawDataDetail {
        address token;
        string symbol;
        string name;
        uint8 decimal;
        uint amount;
    }

    struct ErrorObj {
        uint key;
        uint error_type;
        string sMsg;
        uint cMsg;
        bytes bMsg;
        string desc; // description
    }
}
