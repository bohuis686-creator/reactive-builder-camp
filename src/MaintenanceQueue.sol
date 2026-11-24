// SPDX-License-Identifier: MIT
pragma solidity 0.8.29;

import {AbstractCallback} from "@reactive/src/base/AbstractCallback.sol";
import {IPayable} from "@reactive/src/interfaces/IPayable.sol";

contract MaintenanceQueue is AbstractCallback {
    struct Ticket {
        bytes32 deviceId;
        uint8 severity;
    }

    event TicketOpened(uint256 indexed incidentId, bytes32 indexed deviceId, uint8 severity);

    mapping(uint256 incidentId => Ticket) public tickets;

    constructor(IPayable callbackProxy, address faultRouter) payable AbstractCallback(callbackProxy, faultRouter) {}

    function openTicket(address reactiveSender, uint256 incidentId, bytes32 deviceId, uint8 severity)
        external
        onlyServiceProvider
        onlyCallbackSender(reactiveSender)
    {
        if (tickets[incidentId].severity != 0) return;

        tickets[incidentId] = Ticket(deviceId, severity);
        emit TicketOpened(incidentId, deviceId, severity);
    }
}
