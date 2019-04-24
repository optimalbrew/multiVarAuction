pragma solidity ^0.5.0; //0.5.0 for Truffle

contract cptAuction{
    
    struct Bid {
        bytes32 hashedBid;
        uint256 bidValue;
        uint16 days2Finish; //limited small integer range (2^16 -1), not so small
        bool isBidRevealed; //default is false
        address payable bidder; //msg.sender
        uint256 depositVal; //bid deposit
        bool isAllowedToWithdraw; //for those not selected, return deposits
    }
    /*
    store all bids in an array, even though it is bad practice to use arrays in general.
    Going thru all array elements is expensive. But if we do not have a dynamic data store, then it's hard to solve the problem 
    (of keeping track of bids).
    */ 
    
    // All of these 'state' variables can be accessed by anyone on a public blockchain. Even private and internal ones. But they have to indirectly
    // accessed through the contract's storage space. Public ones can be accessed easily with automatic getter calls.  
    // The private label only hides visibility from other 'contracts'.
    // 'public' tag simply creates automatic getter functions.
    // the default is 'internal' i.e. visible only to contract and its derivatives.
    
    Bid[] private allBids; //dyn. aray // 'private': not visible to other contracts, but indirectly visible via contract's storage space.
    
    Bid private topBid; //keep track of winning bid (private?) //initialized to zero. So score is 0?
   
    address payable public beneficiary; //seller (or buyer in procurement auction).
    // payable? What should happen to funds in the contract? Contract should not have any funds left.

    uint public biddingEnd; //time limit for last bid
    uint public revealEnd; //time limit to reveal bids
    bool public ended; //indicate auction is over (default if false)
    uint public userCost; // social cost of delay
    uint public minDeposit; // moved to constructor
    
    uint topScore = 1000000000; //initial score to beat (in a seller's auction, this could be a non zero reserve price)
    
    //mapping to track if someone has placed a bid at all
    mapping(address => Bid) public addressToBid;
    
    //modifiers
    modifier onlyBiddingPeriod(){
        require(now < biddingEnd, "error: not bidding period.");   //WARN: 'now' is alias for block.timestamp, does not mean current time.   
        _;
    }

    modifier onlyRevealPeriod(){
        require(now > biddingEnd, "error: not reveal period (too early).");
        require(now < revealEnd, "error: not reveal period (expired)."); //don't allow revelation after period is over
        _;
    }
    
    modifier onlySelectionPhase(){
        require(now > revealEnd, "error: not selection phase"); //select anytime after revealEnd
        _;
    }
    
    modifier onlyBeneficiary(){
        require(msg.sender == beneficiary, "error: sender not benefiary");
        _;
    }
    
    //constructor: needs to be initialized (e.g. through 2_deploy_contracts or instance = Contract.new() on truffle console)
    constructor(
        uint _biddingTime,
        uint _revealTime,
        address payable _beneficiary,
        uint _userCost,
        uint _minDeposit
    ) public {
        beneficiary = _beneficiary;
        biddingEnd = now + _biddingTime;
        revealEnd = biddingEnd + _revealTime;
        userCost = _userCost;
        minDeposit = _minDeposit;
    }
    
    // Helper to compare hash of revealed bid with previously submitted hash (encrypted or sealed bid).
    function calculateHashForBid(uint256 bidValue, uint16 days2Finish) public pure returns (bytes32) {
        return keccak256(abi.encodePacked(bidValue, days2Finish));
    }
    
    // Scoring rule to rank bids
    function score(uint bidValue, uint days2Finish) public view returns (uint){
        return bidValue + (userCost * days2Finish);
    }


    // Bidding Phase: function to place a sealed (hashed) bid
    function placeBid(bytes32 hashedBid) onlyBiddingPeriod public payable {
        //input validation
        require(addressToBid[msg.sender].depositVal == 0, "error: bidders cannot place multiple bids."); // MOD: allow updates?  
        require(msg.value > minDeposit, "error: Minimum Deposit not met.");
        
        //temporarily store Bid
        Bid memory newBid; //allocate temporary memory for this instance of the struct call it newBid
        //store data on chain
        newBid.hashedBid = hashedBid; //saved on chain
        newBid.bidder = msg.sender; //saved to 
        newBid.depositVal= msg.value; //saved on chain
        
        //now use this to update the dynamic array of sealed bids
        allBids.push(newBid); //saved on chain (only the info we want stored)
        // and update the mapping of address (bidders) who have already bid.
        addressToBid[msg.sender] = allBids[allBids.length-1]; //set Bid for msg.Sender to latest entry in allBids
    }
    
        
    // Revealing bids (only during  reveal phase)
    function revealBid(uint256 bidCost, uint16 bidTime) onlyRevealPeriod public {
        //validate inputs: hashes should match
        address revealer = addressToBid[msg.sender].bidder; //find sender's hashed bid (from addressToBid), then exatract the identity (which should be same)
        
        //require(revealer == msg.sender, "error: sender and bid revealer mismatch."); //should never happen.
        //"might" not be able to compare 2 bytes32's 
        require(calculateHashForBid(bidCost, bidTime) == addressToBid[msg.sender].hashedBid, "error: hashes do not match.");
           
        //persistent storage
        Bid storage currentBid = addressToBid[revealer]; // this instance of the struct is to be stored persistently, so use 'storage' not 'memory'.
        currentBid.bidValue = bidCost;
        currentBid.days2Finish = bidTime;
        currentBid.isBidRevealed = true;
        
        //rank determination:
        /*
        In this implementation, scoring and winner determination are done in one step. 
        Otherwise, we'd have to maintain all revealed bids in an array and rank them later. That would be wasteful.
        */
        uint scoreCurrentBid = score(bidCost, bidTime);
        if (scoreCurrentBid < topScore) { //lower score wins here. In case of tie, first to reveal stays on top.
            topBid = currentBid;    //assignment of structs in storage may be problematic
            topScore = scoreCurrentBid; //score(topBid.bidValue,topBid.days2Finish); //from now on..
        }            
    }
    
    // Selection phase: 
    function awardContract() 
    onlyBeneficiary 
    //onlySelectionPhase //comment this out
    public  {
        //verify inputs: not needed at present (taken care of by modifiers)
        
        //return deposts of everyone (except winner)
        //WARN: uint8 implies #bidders < 255!
        for (uint8 i=0; i < allBids.length; i++) {
            if (allBids[i].bidder != topBid.bidder){
            // the send will transfer amounts from the contract's address (not the beneficiary's), 
            // however since benefiaciry calls this transaction, they pay the gas (not the contract). 
            allBids[i].bidder.send(allBids[i].depositVal); //ignore send failure.
            /* if a single 'transfer' fails, then all previous transfers are reverted,
            meaning people will not get their deposits back. Use 'send' instead.
            */
            }
        }  
        //assuming winner is not paid (that happens off chain) 
    }    
    
    // function to return winner's deposit (eventually)
    function returnWinnerDeposit() onlyBeneficiary public {
    topBid.bidder.send(topBid.depositVal);    
    }
    
    //Use: debugging to estimate run time certain steps are taking.
    function getCurrentTime() public view returns(uint) {return now;}
    
    //function getCurrentTimePlus1Week() public view returns(uint) {return now + 1 weeks;}

    // return string from bid struct for winning bid
    function winBid() public view returns (uint, uint, address) {
        return (topBid.bidValue, topBid.days2Finish, topBid.bidder);
    }
}