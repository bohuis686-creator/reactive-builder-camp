// SPDX-License-Identifier: MIT
pragma solidity 0.8.29;

import {AbstractReactive} from "@reactive/src/base/AbstractReactive.sol";
import {ISystemContract} from "@reactive/src/interfaces/ISystemContract.sol";
import {FaultRegistry} from "./FaultRegistry.sol";
import {MaintenanceQueue} from "./MaintenanceQueue.sol";

contract FaultRouter is AbstractReactive {
    error UnauthorizedOwner();
    error InvalidRegistry();
    error InvalidQueue();
    error QueueAlreadySet();

    uint8 public constant MIN_SEVERITY = 4;
    uint64 private constant CALLBACK_GAS_LIMIT = 500_000;

    address public immutable owner = msg.sender;
    uint256 public immutable registryChainId;
    address public immutable registry;
    address public queue;

    constructor(uint256 registryChainId_, address registry_) payable {
        if (registryChainId_ == 0 || registry_ == address(0)) revert InvalidRegistry();
        registryChainId = registryChainId_;
        registry = registry_;
        SYSTEM.subscribe(
            registryChainId_,
            registry_,
            uint256(FaultRegistry.FaultReported.selector),
            REACTIVE_IGNORE,
            REACTIVE_IGNORE,
            REACTIVE_IGNORE
        );
    }

    function setQueue(address queue_) external {
        if (msg.sender != owner) revert UnauthorizedOwner();
        if (queue_ == address(0)) revert InvalidQueue();
        if (queue != address(0)) revert QueueAlreadySet();
        queue = queue_;
    }

    function react(LogRecord memory log) external override onlySystem {
        address recipient = queue;
        if (
            recipient == address(0) || log.chainId != registryChainId || log.contractAddress != registry
                || log.topic0 != uint256(FaultRegistry.FaultReported.selector) || log.opCode != 3
                || log.data.length != 32
        ) return;

        uint8 severity = abi.decode(log.data, (uint8));
        if (severity < MIN_SEVERITY) return;

        // Omni replaces the first payload address with this router's address.
        bytes memory payload =
            abi.encodeCall(MaintenanceQueue.openTicket, (address(0), log.topic1, bytes32(log.topic2), severity));
        SYSTEM.requestCallbackV_1_0(
            ISystemContract.CallbackConfiguration_V_1_0({
                chainId: registryChainId, recipient: recipient, gasLimit: CALLBACK_GAS_LIMIT, payload: payload
            })
        );
    }
}
