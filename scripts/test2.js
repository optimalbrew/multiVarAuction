//Not a standard test. Just checking scripts as a way to interact with contracts.
// single parameter callback function to run scripts using truffle exec

//This is for the "elliot" auction, i.e initial A+B procurement auction.
module.exports = async function(finished){
    const abAuction = artifacts.require("./abAuction.sol");

    console.log('********* \nOkay, Here we go!\n\n');
    let instance = await abAuction.deployed();    
    try {
        let accounts = await web3.eth.getAccounts();
        //console.log(accounts);
        instance = await abAuction.new(60,30,accounts[9],2000000,1000000);
        let contractAddress = instance.address;
        console.log('New instance deployed at ' + contractAddress);
        let contractBal = await web3.eth.getBalance(contractAddress);      
        console.log('New instance has balance ' + contractBal + ' wei.\n');

        console.log('Generating some sample bids \n********');
        let bidValue = [10,12,7];
        let days2Finish = [1,1,2];
        //let scores = [12,14,11];
        //let secret = web3.utils.asciiToHex('secret',32); //nonce
        let encBid0 = web3.utils.soliditySha3({t:'uint256' , v: bidValue[0]}, {t: 'uint16', v: days2Finish[0]});
        let encBid1 = web3.utils.soliditySha3({t:'uint256' , v: bidValue[1]}, {t: 'uint16', v: days2Finish[1]});
        let encBid2 = web3.utils.soliditySha3({t:'uint256' , v: bidValue[2]}, {t: 'uint16', v: days2Finish[2]});

        let hashedBid = [encBid0,encBid1,encBid2];

        //print bids for illustration
        console.log('The bids are .. (encrypted, but values displayed for illustration)');
        for (i = 0; i < hashedBid.length;i++){
            console.log('Bidder @', accounts[i+1], 'Cost: ', bidValue[i], ' & ',days2Finish[i], 'weeks with hash', hashedBid[i] );
        }

        //Actual bidding (interaction with contract..)
        console.log('\n\nActually place these bids.\n********');
        console.log('\nBalances before bidding.');
        for (i = 0; i < hashedBid.length;i++){
            let balB4Bid = await web3.eth.getBalance(accounts[i+1]);  
            console.log('Bidder', accounts[i+1], 'has balance', balB4Bid,' before biddding');
            instance.placeBid(hashedBid[i], {from: accounts[i+1],value: 3000000}); //deposit should not reveal bid value 
        }

        //check balances after bidding
        console.log('\nBalances after bidding.');
        for (i = 0; i < hashedBid.length;i++){
            let balAfterBid = await web3.eth.getBalance(accounts[i+1]);  
            console.log('Bidder', accounts[i+1], 'has balance', balAfterBid,' after biddding');
        }

        // contract balance    
        contractBal = await web3.eth.getBalance(contractAddress);      
        console.log('\nContract has balance ' + contractBal + ' wei.\n');



    } catch (error) {
        console.log(error.message);
    }
    finished(); 

};
