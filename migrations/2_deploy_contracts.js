var Auction = artifacts.require("Auction");

module.exports = function(deployer){
    deployer.deploy(Auction, 300,200,'0x35dc609b8d67667a4ff75a1c8d4f87069a83c9e2');
    /*
    //Arguments: bidding time, e.g. 300 seconds, bid reveal time 200 seconds, benefiary address
    //these should be changed post migration e.g.
    // let accounts = await web3.eth.getAccounts()
    // let instance = Auction.new(300, 100, accounts[0]) 
    */
};