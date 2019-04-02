pragma solidity >=0.4.23;
// modified from https://solidity.readthedocs.io/en/latest/solidity-by-example.html

contract Auction {

    // data structure for a bid: see `function bid` below.
    struct Bid{
        bytes32 blindedBid; // keccak256 encrypted bid to be revealed later (if winning bid)
        uint deposit; //deposit, for bid to be credible, this is `msg.value`
        // bidder's identity (i.e. `msg.sender`) not required explicitly.
    }

    address payable public beneficiary; //seller (or buyer in procurement auction).
    uint public biddingEnd; //time limit for last bid
    uint public revealEnd; //time limit to reveal bids
    bool public ended; //indicate auction is over (default if false)

    // multiple bids are allowed (including bids that are explicitly marked 'fake', strategic to confuse or obfuscate)
    mapping(address => Bid[]) public bids; //from address to array of sealed bids?

    address public highestBidder;
    uint public highestBid; //init 0 


    // to handle returns/withdrawals
    mapping(address => uint) pendingReturns; //to handle refunds of bids that get outbidded

    event AuctionEnded(address winner, uint highestBid);

    //modifiers
    modifier onlyBefore(uint _time){
        require(now < _time);   //WARN: 'now' is alias for block.timestamp, does not mean current time.   
        _;
    }

    modifier onlyAfter(uint _time){
        require(now > _time);
        _;
    }

    //constructor: needs to be initialized (e.g. through 2_deploy_contracts or instance = Contract.new() on truffle console)
    constructor(
        uint _biddingTime,
        uint _revealTime,
        address payable _beneficiary
    ) public {
        beneficiary = _beneficiary;
        biddingEnd = now + _biddingTime;
        revealEnd = biddingEnd + _revealTime;
    }

    // pcar: A function (for testing) that does not change the state (calls, not transactions)
    // all example functions change state, so they can only be executed as transactions, not calls.
    // from Metacoin ex on https://truffleframework.com/docs/truffle/getting-started/interacting-with-your-contracts
    function getPendReturn(address addr) public view returns(uint) {
        return pendingReturns[addr];
    }
    

    /// Place a blinded bid with `_blindedBid` = keccak256(abi.encodePacked(value, fake, secret)).
    /// The sent ether is only refunded if the bid is correctly revealed in the revealing phase. The bid is valid if the
    /// ether sent together with the bid is at least "value" and "fake" is not true. Setting "fake" to true and sending
    /// not the exact amount are ways to hide the real bid but still make the required deposit. The same address can
    /// place multiple bids. 
    function bid(bytes32 _blindedBid) public payable onlyBefore(biddingEnd) {
        bids[msg.sender].push(Bid({ //recall this is a struct
            blindedBid: _blindedBid,
            deposit: msg.value
        }//end struct 
        )//end Bid
        ); //end push
        /* bid value, fake indicator, secret/nonce (so value cannot be inferred e.g. via grid search between [1,deposit] and 
        comparing the hash), send multiple bids (fakes), to obfusctate via different deposits */
    }

    // Reveal all bids (including 'fake' bids): submit a list of all bid values, followed by fake indicators, and secrets
    /// Reveal all bids (more user instructions here.. natspec)
    function reveal(
        uint[] memory _values,
        bool[] memory _fake,
        bytes32[] memory _secret
    )
        public
        onlyAfter(biddingEnd) //after bids are in
        onlyBefore(revealEnd) // before reveal time period is over
        {
            uint length = bids[msg.sender].length;

            require(_values.length == length);
            require(_fake.length == length);
            require(_secret.length == length);

            bytes32 encBidKeccak;
            uint refund;

            for (uint i=0; i < length; i++){
                Bid storage bidToCheck = bids[msg.sender][i]; //why in storage? possible explanation. Prevent multiple deposit refunds.
                (uint value, bool fake, bytes32 secret) = 
                    (_values[i], _fake[i], _secret[i]);
                
                encBidKeccak = keccak256(abi.encodePacked(value,fake,secret)); 
                if (bidToCheck.blindedBid != encBidKeccak){
                    //if bid not revealed or does not match
                    //then do  not refund deposit for that bid
                    continue; //not 'break', just skip current one and move to next in list
                }
                refund += bidToCheck.deposit; //including deposit for bid that is eventually placed

                if (!fake && bidToCheck.deposit >= value) {
                    //if actual bid and deposit was higher than value then 'place the bid' and if it returns a `success'
                    // then do not refund the deposit (the bid was placed).
                    if (placeBid(msg.sender, value)){   //call internal function
                        refund -= value; //if deposit was higher than value, just keep the value
                    }
                }
                //make it impossible for any sender to reclaim the same deposit twice during reveal phase
                bidToCheck.blindedBid = bytes32(0); //using bytes32()
            }
            msg.sender.transfer(refund); //refund deposits (excess of any placed bid). What if multiple bids are placed? 
                                        // That's handled in pendingReturns
        }

    // Internal function (can only be called by this contract or its derivatives)
    // its called in the reveal phase, when verifying bids 
    function placeBid(address bidder, uint value) internal returns (bool success)
    {
        if (value <= highestBid){
            return false;
        }
        if (highestBidder != address(0)){ //i.e. enter this loop only if at least one bid has been placed.
            //refund prev. highest bid
            pendingReturns[highestBidder] += highestBid; //no transfers or refunds yet.. user has to call withdraw
        }
        highestBid = value;
        highestBidder = bidder;
        return true;
    }


    /// withdraw 'overbid' bids
    function withdraw() public {
        uint amount = pendingReturns[msg.sender];
        if (amount > 0 ){
            // It is important to set this to zero because the recipient
            // can call this function again as part of the receiving call
            // before `transfer` returns (following "conditions -> effects -> interaction" guideline).
            pendingReturns[msg.sender] = 0;
            //and then do the actual transfer
            msg.sender.transfer(amount);
        }
    }

    /// End auction, send proceeds to beneficiary
    function auctionEnd() 
        public
        onlyAfter(revealEnd) 
    {
        require(!ended);
        emit AuctionEnded(highestBidder, highestBid);
        ended = true;
        beneficiary.transfer(highestBid);
    }
}