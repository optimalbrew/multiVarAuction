pragma solidity ^0.5.0; //0.5.0 for Truffle

contract abAuction{
    
    struct Bid {
        bytes32 hashedBid;
        uint256 bidValue;
        uint16 days2Finish; //limited small integer range (2^16 -1), not so small
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
    
    Bid private topBid; //keep track of winning bid (private?) //initialized to zero. So score is 0?
    
    //Bid public winningBid; // 
    
    address payable public beneficiary; //seller (or buyer in procurement auction).
    uint public biddingEnd; //time limit for last bid
    uint public revealEnd; //time limit to reveal bids
    bool public ended; //indicate auction is over (default if false)
    uint public userCost; //
    uint public minDeposit; // moved to constructor
    
    uint topScore = 1000000000; //initial score to beat (in a seller's auction, this could be 0)
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
        uint _userCost,
        uint _minDeposit
    ) public {
        beneficiary = _beneficiary;
        biddingEnd = now + _biddingTime;
        revealEnd = biddingEnd + _revealTime;
        userCost = _userCost;
        minDeposit = _minDeposit;
    }
    
    // Bidding Phase (bids are encrypted)
    // do not store the unhashed values on chain!
    function placeBid(bytes32 hashedBid) onlyBiddingPeriod public payable {
        //input validation
        require(addressToBid[msg.sender].depositVal == 0, "error: cannot place multiple bids.");
        require(msg.value > minDeposit, "error: Minimum Deposit not met.");
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
    
    // Scoring rule
    function score(uint bidValue, uint days2Finish) public view returns (uint){
        return bidValue + (userCost * days2Finish);
    }
    

    // Bid Reveal phase
    function revealBid(uint256 bidCost, uint16 bidTime) onlyRevealPeriod public {
        //validate inputs: hashes should match
        address revealer = addressToBid[msg.sender].bidder;
        //"might" not be able to compare 2 bytes32's 
        require(calculateHashForBid(bidCost, bidTime) == addressToBid[msg.sender].hashedBid, "error: hashes do not match.");
           
        //update storage
        Bid storage currentBid = addressToBid[revealer];
        currentBid.bidValue = bidCost;
        currentBid.days2Finish = bidTime;
        currentBid.isBidRevealed = true;
        
        //rank determination
        uint scoreCurrentBid = score(bidCost, bidTime);
        if (scoreCurrentBid < topScore) { //lower score wins here
            topBid = currentBid;    //assignment of structs in storage may be problematic
            topScore = score(topBid.bidValue,topBid.days2Finish); //from now on..
        }
             
    }
    

    // Selection phase: 
    //WARNING: TODO* 
    //This should either be an internal function, so the money is returned from the contract, 
    // or the contract should transfer the funds to the beneficiary.
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