// SPDX-License-Identifier: MIT
pragma solidity 0.8.29;

import {IReactive} from "@reactive/src/interfaces/IReactive.sol";
import {ISystemContract} from "@reactive/src/interfaces/ISystemContract.sol";
import {IPayable} from "@reactive/src/interfaces/IPayable.sol";
import {FaultRegistry} from "../src/FaultRegistry.sol";
import {FaultRouter} from "../src/FaultRouter.sol";
import {MaintenanceQueue} from "../src/MaintenanceQueue.sol";

interface Vm {
    struct Log {
        bytes32[] topics;
        bytes data;
        address emitter;
    }

    function etch(address target, bytes calldata code) external;
    function prank(address sender) external;
    function recordLogs() external;
    function getRecordedLogs() external returns (Log[] memory);
}

contract MockSystem {
    uint256 public requests;
    ISystemContract.CallbackConfiguration_V_1_0 private latestRequest;

    function subscribe(uint256, address, uint256, uint256, uint256, uint256) external {}

    function requestCallbackV_1_0(ISystemContract.CallbackConfiguration_V_1_0 calldata request) external {
        requests++;
        latestRequest = request;
    }

    function lastRequest() external view returns (ISystemContract.CallbackConfiguration_V_1_0 memory) {
        return latestRequest;
    }
}

contract MaintenanceFlowTest {
    Vm private constant VM = Vm(address(uint160(uint256(keccak256("hevm cheat code")))));
    address private constant SYSTEM = 0x8888888888888888888888888888888888888888;
    address private constant PROXY = address(0x1234);
    uint256 private constant SEPOLIA = 11155111;
    bytes32 private constant DEVICE = keccak256("pump-17");

    FaultRegistry private registry;
    FaultRouter private router;
    MaintenanceQueue private queue;

    function setUp() external {
        VM.etch(SYSTEM, address(new MockSystem()).code);
        registry = new FaultRegistry();
        router = new FaultRouter(SEPOLIA, address(registry));
        queue = new MaintenanceQueue(IPayable(payable(PROXY)), address(router));
        router.setQueue(address(queue));
    }

    function testSevereFaultOpensExactlyOneTicket() external {
        IReactive.LogRecord memory record = report(4);
        VM.prank(SYSTEM);
        router.react(record);

        require(MockSystem(SYSTEM).requests() == 1, "wrong request count");
        ISystemContract.CallbackConfiguration_V_1_0 memory request = MockSystem(SYSTEM).lastRequest();
        require(request.chainId == SEPOLIA && request.recipient == address(queue), "wrong destination");
        bytes memory expected = abi.encodeCall(MaintenanceQueue.openTicket, (address(0), 1, DEVICE, 4));
        require(keccak256(request.payload) == keccak256(expected), "wrong payload");

        VM.prank(PROXY);
        queue.openTicket(address(router), 1, DEVICE, 4);
        VM.prank(PROXY);
        queue.openTicket(address(router), 1, keccak256("other device"), 5);
        (bytes32 device, uint8 severity) = queue.tickets(1);
        require(device == DEVICE && severity == 4, "ticket missing or overwritten");
    }

    function testLowSeverityDoesNotRequestCallback() external {
        IReactive.LogRecord memory record = report(3);
        VM.prank(SYSTEM);
        router.react(record);
        require(MockSystem(SYSTEM).requests() == 0, "low severity generated a request");
    }

    function testRejectsUntrustedActors() external {
        IReactive.LogRecord memory record = report(5);
        (bool directReact,) = address(router).call(abi.encodeCall(FaultRouter.react, (record)));
        require(!directReact, "unauthorized react");

        (bool directCallback,) =
            address(queue).call(abi.encodeCall(MaintenanceQueue.openTicket, (address(router), 1, DEVICE, 5)));
        require(!directCallback, "unauthorized callback proxy");

        VM.prank(PROXY);
        (bool wrongSender,) =
            address(queue).call(abi.encodeCall(MaintenanceQueue.openTicket, (address(this), 1, DEVICE, 5)));
        require(!wrongSender, "unauthorized Reactive sender");

        VM.prank(PROXY);
        (bool wrongReporter,) = address(registry).call(abi.encodeCall(FaultRegistry.report, (DEVICE, 5)));
        require(!wrongReporter, "unauthorized reporter");
    }

    function report(uint8 severity) private returns (IReactive.LogRecord memory record) {
        VM.recordLogs();
        registry.report(DEVICE, severity);
        Vm.Log[] memory logs = VM.getRecordedLogs();
        Vm.Log memory entry = logs[0];
        record.chainId = SEPOLIA;
        record.contractAddress = entry.emitter;
        record.topic0 = uint256(entry.topics[0]);
        record.topic1 = uint256(entry.topics[1]);
        record.topic2 = uint256(entry.topics[2]);
        record.data = entry.data;
        record.opCode = entry.topics.length;
    }
}
