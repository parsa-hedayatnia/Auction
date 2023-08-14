// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

contract SimpleAuction {
    address public auctionManager;
    uint256 public auctionEndTime;
    address public highestBidder;
    uint256 public highestBid;
    uint256 private duration;
    bool    public auctionEnded;
    

    mapping(address => uint256) public deposits;
    address[] public participants; 

    event HighestBidIncreased(address bidder, uint256 amount);
    event AuctionEnded(address winner, uint256 amount);

    constructor(address _manager, uint256 _duration) {
        auctionManager = _manager;
        auctionEndTime = block.timestamp + _duration;
        auctionEnded   = false;
        duration = _duration;
    }

    modifier onlyManager() {
        require(msg.sender == auctionManager, "Only the auction manager can perform this action");
        _;
    }

    modifier auctionNotEnded() {
        require(!auctionEnded, "Auction has already ended");
        _;
    }

    modifier auctionEndedOnly() {
        require(auctionEnded, "Auction has not yet ended");
        _;
    }
    //Specify msg.value as the suggested value
    function bid() public payable auctionNotEnded {
        require(msg.value >= highestBid, "Bid must be higher than the current highest bid");
        if (deposits[msg.sender] == 0) {
            participants.push(msg.sender); // Add new participants
        }

        if (highestBidder != address(0)) {
            deposits[highestBidder] += highestBid;
        }


        highestBidder = msg.sender;
        highestBid    = msg.value;
        //fine the new highestBid
        emit HighestBidIncreased(msg.sender, msg.value);
    }

    function Elapsed_time()public view returns(uint256) {
       return  block.timestamp - auctionEndTime; 
    }

        function cancelBid() public auctionNotEnded {
        require(deposits[msg.sender] > 0, "You haven't placed a bid to cancel");
        require(msg.sender != highestBidder, "You cannot cancel if you're the highest bidder");
        
        uint256 refundAmount = deposits[msg.sender];
        deposits[msg.sender] = 0;
        payable(msg.sender).transfer(refundAmount);
        
        for (uint256 i = 0; i < participants.length; i++) {
            if (participants[i] == msg.sender) {
                delete participants[i]; // Remove the participant from the list
                break;
            }
        }
    }

    function auctionEnd() public {
        require(Elapsed_time()> duration , "Auction end time has not been reached yet");
        auctionEnded = true;
        emit AuctionEnded(highestBidder, highestBid);
        //transfer from _owner to account that have the highestBid
        payable(auctionManager).transfer(highestBid);
        for (uint256 i = 0; i < participants.length; i++) {
            address participant = participants[i];
            if (participant != highestBidder) {
                uint256 refundAmount = deposits[participant];
                deposits[participant] = 0;
                payable(participant).transfer(refundAmount);
            }
        }
    }
}

