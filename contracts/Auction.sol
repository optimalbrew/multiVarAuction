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
    bool public ended; //indicate auction is over

    // multiple bids are allowed (including bids that are explicitly marked 'fake', strategic to confuse or obfuscate)
    mapping(address => Bid[]) public bids; //from address to array of sealed bids?

    address public highestBidder;
    uint public highestBid; //public because it is hashed? Is there is gettor function 

    /// to handle returns/withdrawals
    mapping(address => uint) pendingReturns;

    event AuctionEnded(address winner, uint highestBid);

    //modifiers
    modifier onlyBefore(uint _time){
        require(now < _time);
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

    /// pcar: A function (for testing) that does not change the state (calls, not transactions)
    /// all example functions change state, so they can only be executed as transactions, not calls.
    /// from Metacoin ex on https://truffleframework.com/docs/truffle/getting-started/interacting-with-your-contracts
    function getPendReturn(address addr) public view returns(uint) {
        return pendingReturns[addr];
    }

    /// Place a blinded bid with `_blindedBid`
    /// keccak256(abi.encodePacked(value, fake, secret))

    function bid(bytes32 _blindedBid) public payable onlyBefore(biddingEnd) {
        bids[msg.sender].push(Bid({ //recall this is a struct
            blindedBid: _blindedBid,
            deposit: msg.value
        }//end struct 
        )//end Bid
        ); //end push
    }

    /// reveal blinded bids. NTS: this is also where bids are marked as fake. Only 'non' fake bids need to be revealed (to get deposit back)
    /// Do they check that winner cannot back out by claiming a fake bid? That's the only deposit that should not be returned, no 
    /// matter what the intent was (mistake or unintentional real bid etc).
    /// refund for all correctly blinded invalid bids, and all bids except the winning one.
    /// more details..
    function reveal(
        uint[] memory _values,
        bool[] memory _fake,
        bytes32[] memory _secret
    )
        public
        onlyAfter(biddingEnd)
        onlyBefore(revealEnd)
        {
            uint length = bids[msg.sender].length;

            require(_values.length == length);
            require(_fake.length == length);
            require(_secret.length == length);

            uint refund;

            for (uint i=0; i < length; i++){
                Bid storage bidToCheck = bids[msg.sender][i];
                (uint value, bool fake, bytes32 secret) = 
                    (_values[i], _fake[i], _secret[i]);
                
                if (bidToCheck.blindedBid != keccak256(abi.encodePacked(value,fake,secret))){
                    //bid not actually revealed
                    //do  not refund
                    continue; //not break, just skip current one and move to next in list
                }
                refund += bidToCheck.deposit;

                if (!fake && bidToCheck.deposit >= value) {
                    if (placeBid(msg.sender, value)){
                        refund -= value;
                    }
                }

                //make impossible for the sender to reclaim the same deposit
                bidToCheck.blindedBid = bytes32(0);
            }
            msg.sender.transfer(refund);
        }

    /// Internal function (can only be called by this contract or its derivatives)
    function placeBid(address bidder, uint value) internal returns (bool success)
    {
        if (value <= highestBid){
            return false;
        }
        if (highestBidder != address(0)){
            //refund prev. highest bidder
            pendingReturns[highestBidder] += highestBid;
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
            // before `transfer` returns (see the remark above about
            // conditions -> effects -> interaction).
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