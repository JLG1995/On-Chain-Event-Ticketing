// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract EventTicket {
    address public owner;
    struct Ticket {
        uint256 id;
        string eventName;
        uint256 price;
        uint256 totalTickets;
        uint256 remainingTickets;
        bool isActive;
    }

    mapping(uint256 => Ticket) public tickets;
    mapping(uint256 => address) public ticketOwners; // Track ticket owners
    uint256 public ticketCount = 0;

    event TicketBought(address buyer, uint256 ticketId);
    event TicketTransferred(address from, address to, uint256 ticketId);
    event EventCancelled(uint256 ticketId);

    constructor() {
        owner = msg.sender;
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "Only owner can call this function");
        _;
    }

    function createTicket(string memory _eventName, uint256 _price, uint256 _totalTickets) public {
        require(_totalTickets > 0, "Total tickets must be greater than zero");
        ticketCount++;
        tickets[ticketCount] = Ticket({
            id: ticketCount,
            eventName: _eventName,
            price: _price,
            totalTickets: _totalTickets,
            remainingTickets: _totalTickets,
            isActive: true
        });
    }

    function buyTicket(uint256 _ticketId) public payable {
        require(_ticketId > 0 && _ticketId <= ticketCount, "Invalid ticket ID");
        Ticket storage ticket = tickets[_ticketId];
        require(ticket.isActive, "This event's ticket sales are closed");
        require(msg.value == ticket.price, "Incorrect Ether sent");
        require(ticket.remainingTickets > 0, "No more tickets available for this event");

        (bool success, ) = payable(owner).call{value: msg.value}("");
        require(success, "Transfer failed.");

        ticket.remainingTickets -= 1;
        ticketOwners[_ticketId] = msg.sender; // Track owner
        emit TicketBought(msg.sender, _ticketId);
    }

    function transferTicket(uint256 _ticketId, address _to) public {
        require(ticketOwners[_ticketId] == msg.sender, "Only the ticket owner can transfer");
        ticketOwners[_ticketId] = _to;
        emit TicketTransferred(msg.sender, _to, _ticketId);
    }

    function cancelEvent(uint256 _ticketId) public onlyOwner {
        require(_ticketId > 0 && _ticketId <= ticketCount, "Invalid ticket ID");
        Ticket storage ticket = tickets[_ticketId];
        require(ticket.isActive, "Event already canceled");

        ticket.isActive = false;
        ticket.remainingTickets = 0;

        payable(owner).transfer(address(this).balance);
        emit EventCancelled(_ticketId);
    }
}