// SPDX-License-Identifier: MIT
pragma solidity 0.8.29;

contract FaultRegistry {
    error UnauthorizedReporter();
    error InvalidFault();

    event FaultReported(uint256 indexed incidentId, bytes32 indexed deviceId, uint8 severity);

    address public immutable reporter = msg.sender;
    uint256 public incidentCount;

    function report(bytes32 deviceId, uint8 severity) external returns (uint256 incidentId) {
        if (msg.sender != reporter) revert UnauthorizedReporter();
        if (deviceId == bytes32(0) || severity == 0 || severity > 5) revert InvalidFault();

        incidentId = ++incidentCount;
        emit FaultReported(incidentId, deviceId, severity);
    }
}
