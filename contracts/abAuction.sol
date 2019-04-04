pragma solidity ^0.5.1;

contract newAuction{
    
    struct Bid {
        bytes32 hashedBid;
        uint256 bidValue;
        uint16 days2Finish; //limited small integer range
        bool isBidRevealed; //default is false
        address payable bidder; //msg.sender
        uint depositVal; //bid deposit
        bool isAllowedToWithdraw; //for those not selected
    }
    /*
    store all bids in an array, even though it is bad practice to use arrays in general.
    Going thru all array elements is expensive. 
    If we do not have a dynamic data store, then it's hard to solve the problem 
    (keeping track of bids).
    */
    
    Bid[] private allBids; //dyn. aray
    Bid private topBid; //keep track of winning bid
    
    uint minDeposit = 1 ether; //
    Bid public winningBid;
    
    address payable public beneficiary; //seller (or buyer in procurement auction).
    uint public biddingEnd; //time limit for last bid
    uint public revealEnd; //time limit to reveal bids
    bool public ended; //indicate auction is over (default if false)
    uint public userCost; //public so auto getter function.
    //track if someone has placed a bid at all
    mapping(address => Bid) public addressToBid;
    
     //modifiers
    modifier onlyBiddingPeriod(){
        require(now < biddingEnd);   //WARN: 'now' is alias for block.timestamp, does not mean current time.   
        _;
    }

    modifier onlyRevealPeriod(){
        require(now > biddingEnd);
        require(now < revealEnd); //don't allow revelation after period is over
        _;
    }
    
    modifier onlySelectionPhase(){
        require(now > revealEnd); //select anytime after revealEnd
        _;
    }
    
    modifier onlyBeneficiary(){
        require(msg.sender == beneficiary);
        _;
    }
    
    //constructor: needs to be initialized (e.g. through 2_deploy_contracts or instance = Contract.new() on truffle console)
    constructor(
        uint _biddingTime,
        uint _revealTime,
        address payable _beneficiary,
        uint _userCost
    ) public {
        beneficiary = _beneficiary;
        biddingEnd = now + _biddingTime;
        revealEnd = biddingEnd + _revealTime;
        userCost = _userCost;
    }
    
    // Bidding Phase (bids are encrypted)
    // do not store the unhashed values on chain!
    function placeBid(bytes32 hashedBid) onlyBiddingPeriod public payable {
        //input validation
        require(addressToBid[msg.sender].depositVal == 0, "error: cannot place multiple bids.");
        require(msg.value > 0, "error: can't leave 0 deposit'.");
        //temporarily store Bid
        Bid memory newBid; //allocate memory for this instance "newBid" of type Bid
        //store data on chain
        newBid.hashedBid = hashedBid; //saved on chain
        newBid.bidder = msg.sender; //saved to 
        newBid.depositVal= msg.value; //saved on chain
        allBids.push(newBid); //saved on chain
        addressToBid[msg.sender] = allBids[allBids.length-1]; //saved on chain
    }
    function calculateHashForBid(uint256 bidValue, uint16 days2Finish) public pure returns (bytes32) {
        return keccak256(abi.encodePacked(bidValue, days2Finish));
    }
    
    // Bid Reveal phase
    function revealBid(uint256 bidValue, uint16 days2Finish) onlyRevealPeriod public {
        //validate inputs: hashes should match
        address revealer = addressToBid[msg.sender].bidder;
        //"might" not be able to compare 2 bytes32's 
        require(calculateHashForBid(bidValue, days2Finish) == addressToBid[msg.sender].hashedBid);
           
        //update storage
        Bid storage currentBid = addressToBid[revealer];
        currentBid.bidValue = bidValue;
        currentBid.days2Finish = days2Finish;
        currentBid.isBidRevealed = true;
        
        //rank determination
        uint scoreCurrentBid = score(bidValue,days2Finish);
        uint topScore = score(topBid.bidValue,topBid.days2Finish);
        if (scoreCurrentBid < topScore ) { //lower score wins here
            topBid = currentBid;    //assignment of structs in storage may be problematic
        }
             
    }
    
    function score(uint bidValue, uint days2Finish) public view returns (uint){
        return bidValue + (userCost * days2Finish);
    }
    
    // Selection phase
    function awardContract() onlyBeneficiary onlySelectionPhase public  {
        //verify inputs
            //not needed at present (and taken care of by modifiers)
        
        //return deposts of everyone (except winner)
        //WARN: uint8 implies #bidders < 255!
        for (uint8 i=0; i < allBids.length; i++) {
            if (allBids[i].bidder != topBid.bidder){
            allBids[i].bidder.send(allBids[i].depositVal); //ignore send failure.
            /* if a single 'transfer' fails, then all previous transfers are reverted,
            meaning people will not get their deposits back. Use 'send' instead.
            */
            }
        }
        
        //assuming winner is not paid (that happens off chain) 
    }    
    
    // function to return winner's deposit (eventually)
    function giveWinnerDeposit() onlyBeneficiary public {
    topBid.bidder.send(topBid.depositVal);    
    }
    
    
    function getCurrentTime() public view returns(uint) {return now;}
    
    function getCurrentTimePlus1Week() public view returns(uint) {return now + 1 weeks;}
}