// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.20;
import "./Types.sol";

interface IMessager {
    event Msg(Types.Message);
    event UploadFee(uint);

    function set_bridge_fee(uint v) external;

    function verify_msg(
        Types.Message memory messageDec,
        // uint16[] memory signer_index,
        bytes[] memory signature
    ) external returns (bool);

    function decode_msg(
        bytes memory message
    ) external pure returns (Types.Message memory);

    function decode_bridge_msg_body(
        bytes memory msg_body
    ) external pure returns (Types.BridgeMessageBody memory);

    // verify and consume it.
    function consume_bridge_msg(
        Types.Message memory messageDec,
        bytes[] memory signature
    ) external returns (bool);

    function emit_msg(
        uint8 msg_type,
        Types.Chain memory to_chain,
        bytes32 receiver,
        bytes memory message,
        uint128 upload_gas_fee // source p token.
    ) external payable;

    function withdrawFee(uint amount) external;
}
