//Not a standard test. Just checking scripts as a way to interact with contracts.
// single parameter callback function to run scripts using truffle exec

//Initial A+B procurement auction (Elliot Auction).
module.exports = async function(finished){
    const abAuction = artifacts.require("./abAuction.sol");

    console.log('********* \nOkay, Here we go \n(Font size okay at the back?)\n');
    let instance = await abAuction.deployed();    
    try {
        let accounts = await web3.eth.getAccounts();
        
        //parameters for contract constructor
        let bidTime = 4;
        let revealTime = 5;
        let beneficiary = accounts[9];
        let userCost = 2;  //the unit for this must match 'cost/time' e.g. $million/day       
        let minDeposit = 2000000;
        //console.log(accounts);
        instance = await abAuction.new(bidTime, revealTime, beneficiary, userCost, minDeposit);
        
        //time check
        let tCheck1 = await instance.getCurrentTime();

        let contractAddress = instance.address;
        console.log('\n\x1b[32m%s\x1b[0m','New Auction contract instance deployed at ' + contractAddress);
        let contractBal = await web3.eth.getBalance(contractAddress);      
        console.log('\nContract', contractAddress,'has balance ' + contractBal + ' wei.\n');
        //console.log('\nNew instance has balance ' + contractBal + ' wei.\n');

        console.log('\n\x1b[34m%s\x1b[0m','Create some sample bids \n********');
        console.log('let bids = [[10,2], [13,1], [7,3], [8,2]];');
        // let bidValue = [10,12,7];
        // let days2Finish = [1,1,2];
        // using the first elem is bid cost (or value) and the second elem is bid time
        let bids = [[10,2], [13,1], [7,3], [8,2]];

        //scoring function
        function score(cost, time){return (cost + (time * userCost));}
        //score the bids
        let bidScores = [];
        for (i=0;i<bids.length;i++){bidScores.push(score(bids[i][0],bids[i][1]));}

        //let hashedBid = [encBid0,encBid1,encBid2];
        let hashedBid = [];
        for (i = 0; i < bids.length;i++){
            hashedBid.push(web3.utils.soliditySha3({t:'uint256' , v: bids[i][0]}, {t: 'uint16', v: bids[i][1]}));
        }
        /* single version of above for easy copy pasting into truffle developer
        for (i = 0; i < bids.length;i++){hashedBid.push(web3.utils.soliditySha3({t:'uint256' , v: bids[i][0]}, {t: 'uint16', v: bids[i][1]}));}
        */

        //print bids for illustration
        console.log('The bids are encrypted. Displaying values for illustration.');
        for (i = 0; i < bids.length;i++){
            console.log('\n\nBidder',i+1, '@', accounts[i+1]);
            console.log('Submits bid hash', hashedBid[i]);
            console.log('bid cost: ', bids[i][0], ' & ', 'bid time:', bids[i][1], '(not revealed yet)');
            console.log('Score: ', bidScores[i]);
        }

        console.log('\n*********\nRecall: lowest score wins.\n*******')
        //single line version of above
        //for (i = 0; i < bids.length;i++){console.log('Bidder @', accounts[i+1], 'Cost: ', bids[i][0], ' & ', bid[i][1], 'weeks with hash', hashedBid[i] );}

        //Actual bidding (interaction with contract..)
        console.log('\n\nDeposit (3 million wei assumed, minimum is 2 million) to place a bid. These funds are held in the contract.\n********');
        console.log('\n\x1b[34m%s\x1b[0m','Balances before bidding.');
        for (i = 0; i < bids.length;i++){
            let balB4Bid = await web3.eth.getBalance(accounts[i+1]);  
            console.log('Bidder',i+1, '@', accounts[i+1], 'has balance', balB4Bid);
            instance.placeBid(hashedBid[i], {from: accounts[i+1],value: 3000000}); //deposit  identical as it should not reveal bid value 
        }

        //check balances after bidding
        console.log('\n\x1b[34m%s\x1b[0m','Balances after bidding.');
        for (i = 0; i < bids.length;i++){
            let balAfterBid = await web3.eth.getBalance(accounts[i+1]);  
            console.log('Bidder',i+1, '@', accounts[i+1], 'has balance', balAfterBid);
        }

        // contract balance    
        contractBal = await web3.eth.getBalance(contractAddress);      
        console.log('\n\x1b[34m%s\x1b[0m','Contract ' + contractAddress +' has balance ' + contractBal + ' wei.\n');

        //get a time check
        let tCheck2 = await instance.getCurrentTime();
        //console.log('Time elapsed since instance created', tCheck2-tCheck1, 'sec.');

        //moving on to bid revelation phase using the same bids as before (no need for new ones).
        var check = async function(){
            tCheck2 = await instance.getCurrentTime();
            if((tCheck2 - tCheck1) > (bidTime + 1)){
                // reveal bids when condition is met
                console.log('\n******');
                for (i=0; i< bids.length;i++){
                    instance.revealBid(bids[i][0], bids[i][1], {from: accounts[i+1]});
                    console.log('\n\x1b[32m%s\x1b[0m','Bid '+ (i+1) + ' revealed.');
                }
                //If the above worked then we will have a top bid
                let winningBid = await instance.winBid();
                console.log(winningBid);        

            }
            else {
                console.log('\n\x1b[31m%s\x1b[0m','Bidding phase: Bids cannot be revealed yet.');
                setTimeout(check, 2000); // check again in 2 secs
            }
        }
        check();
        
        
        // Finalize auction outcome

    } catch (error) {
        console.log(error.message);
    }
    finished(); 

};
