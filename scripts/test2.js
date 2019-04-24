//Not a standard test. Just checking scripts as a way to interact with contracts.
// single parameter callback function to run scripts using truffle exec


module.exports = async function(finished){
    const cptAuction = artifacts.require("./cptAuction.sol");

    console.log('********* \nOkay, Here we go!  \n(Check if font size is okay...)\n');
    let instance = await cptAuction.deployed();    
    try {
        let accounts = await web3.eth.getAccounts();
        
        //parameters for contract constructor
        let bidTime = 5;
        let revealTime = 5;
        let beneficiary = accounts[9];
        let userCost = 2;  //unit must match 'cost/time' e.g. $million/day       
        let minDeposit = 1e14; //ISSUE: Does not accept val>1e15 https://github.com/ethereum/web3.js/issues/2077
                               //scaling this during bidding (by a factor 20000!!) 

        //console.log(accounts);
        instance = await cptAuction.new(bidTime, revealTime, beneficiary, userCost, minDeposit);
        
        //time check
        let tCheck1 = await instance.getCurrentTime();

        console.log('\n\x1b[34m%s\x1b[0m','*****************************\nDeploy Contract Instance\n*****************************');
       
        let contractAddress = instance.address;
        console.log('\n\x1b[32m%s\x1b[0m','New contract instance deployed at address ' + contractAddress + ' and block timestamp ' + tCheck1);
        
        let contractBal = await web3.eth.getBalance(contractAddress);    
        let cBalEth = web3.utils.fromWei(contractBal);  
    
        
        console.log('\n\x1b[32m%s\x1b[0m','"Social Cost" multiplier passed to constructor (for scoring) is ' +  userCost);
        console.log('\n\x1b[32m%s\x1b[0m','"Minimum deposit" passed to constructor is 2 Eth.'); //(weird web3 issue, 20000 X 1e14).');
        console.log('\nContract', contractAddress,'has balance ' + cBalEth + ' Eth.\n');


        // bidding phase
        console.log('\n\n\n\x1b[34m%s\x1b[0m','*****************************\nBidding Phase \n*****************************');
        
        let bids = [[10,2], [13,1], [7,3], [8,2]];
        // nonce or salt for hashing
        let bidSalt = ['salt1', 'salt2','salt3','salt4']; //index is still 0 based, but bidders are numbered for illustration.
        
        console.log('\nSample [ "cost", "time" ] bids from 4 bidders = [[10,2], [13,1], [7,3], [8,2]]');

        //scoring function
        function score(cost, time){return (cost + (time * userCost));}
        //score the bids
        
        let bidScores = [];
        for (i=0;i<bids.length;i++){bidScores.push(score(bids[i][0],bids[i][1]));} // should be done later (after bids revealed, but okay for illustration)

        //let hashedBid = [encBid0,encBid1,encBid2];
        let hashedBid = [];
        for (i = 0; i < bids.length;i++){
            let str2bytes = web3.utils.sha3(bidSalt[i]);
            hashedBid.push(web3.utils.soliditySha3({t:'uint256' , v: bids[i][0]}, {t: 'uint16', v: bids[i][1]}, {t:'bytes32',v: str2bytes}));
        }
        /* single version of above for easy copy pasting into truffle developer
        for (i = 0; i < bids.length;i++){hashedBid.push(web3.utils.soliditySha3({t:'uint256' , v: bids[i][0]}, {t: 'uint16', v: bids[i][1]}));}
        */

         // Balance before bidding)
         //console.log('\n\nDeposit (Minimum .0002 Eth assumed) to place a bid. These funds are held in the contract.\n********');
         console.log('\n\x1b[34m%s\x1b[0m','\n# Check bidder balances prior to bidding.\n');
         for (i = 0; i < bids.length;i++){
             let balB4Bid = await web3.eth.getBalance(accounts[i+1]);  
             console.log('Bidder',i+1, '@', accounts[i+1], 'has balance', web3.utils.fromWei(balB4Bid)+ ' Eth.\n\n');
         }
        

         console.log('\n\n\n\n\n\x1b[34m%s\x1b[0m','# Bidders submit "Solidity SHA3"/Keccak256 hashes of (cost, time, secret)');
         console.log('\n\x1b[34m%s\x1b[0m','# Secret is just SHA3() of some string');
         // Place bids (bidding phase)
         for (i = 0; i < bids.length;i++){
             instance.placeBid(hashedBid[i], {from: accounts[i+1],value: 20000*minDeposit}); //deposit should not reveal bid value (assumed same for now).
             console.log('\n\nBidder',i+1, 'submits SHA3 hash', hashedBid[i]);
         }    

        //check balances after bidding
        console.log('\n\n\n\n\n\n\x1b[34m%s\x1b[0m','# Bidder balances after bidding (reduced by deposits + "gas").\n');
        for (i = 0; i < bids.length;i++){
            let balAfterBid = await web3.eth.getBalance(accounts[i+1]);  
            console.log('Bidder',i+1, '@', accounts[i+1], 'has balance', web3.utils.fromWei(balAfterBid)+ ' Eth.\n');

        }

        // contract balance    
        contractBal = await web3.eth.getBalance(contractAddress);
        console.log('\n\n\x1b[34m%s\x1b[0m', '# Deposits are held in the contract, so let us check the balance ..\n' );      
        console.log('\x1b[34m%s\x1b[0m','Contract ' + contractAddress +' has balance ' + web3.utils.fromWei(contractBal) + ' Eth.\n');


        console.log('\n\x1b[34m%s\x1b[0m','*************************************************************************************\
        \nBidders query contract (or blockchain) to check phase  (contract cannot self execute a "timer")\
        \n*************************************************************************************');

        //get a time check
        //let tCheck2 = await instance.getCurrentTime();
        //console.log('Time elapsed since instance created', tCheck2-tCheck1, 'sec.');

        //moving on to bid revelation phase using the same bids as before (no need for new ones).
        var check = async function(){
            
            let tCheck2 = await instance.getCurrentTime();
            if((tCheck2 - tCheck1) > (bidTime + 1)){
                // reveal bids when condition is met
                console.log('\n\x1b[34m%s\x1b[0m','\n*******************************\n# Bids can now be revealed\n*******************************\n');
                for (i=0; i< bids.length;i++){
                    instance.revealBid(bids[i][0], bids[i][1], web3.utils.sha3(bidSalt[i]), {from: accounts[i+1]});
                    console.log('\n\x1b[32m%s\x1b[0m','Bid '+ (i+1) + ' revealed.');
                }
                
                //After bids revealed, show what they are and the result 
                // scoring phase
                console.log('\n\x1b[34m%s\x1b[0m','\n********************************************\n# Scoring phase: \n##Compare Hash \n##Recall: lowest score wins!!\n******************************************')
        
                    for (i = 0; i < bids.length;i++){
                        console.log('\n\nBidder',i+1, ' with secret "', web3.utils.sha3(bidSalt[i]),  '"\n => cost quote:', bids[i][0], 'time quote:', bids[i][1],  ', and overall Score: ', bidScores[i]);
                    }
        
                    // Fetch winning bid
                    let winningBid = await instance.winBid();
                    console.log('\n\n\x1b[32m%s\x1b[0m','\nThe winning bid is\n') 
                    console.log(winningBid);  

            // return deposits
            console.log('\n\x1b[34m%s\x1b[0m','************************************\n\n\n\n# Time to return the deposits.\n************************************\n');
        
            instance.awardContract({from: beneficiary});

            //check balances of accounts and contracts
            // contract balance    
            contractBal = await web3.eth.getBalance(contractAddress);      
            console.log('\n\x1b[34m%s\x1b[0m','Contract ' + contractAddress +' has balance ' + web3.utils.fromWei(contractBal) + ' Eth.\n');
                    
                    
            //check bidder balances to verify deposits returned
            console.log('\n\x1b[34m%s\x1b[0m','Balances after winner determined (verify deposits returned).\n');
            for (i = 0; i < bids.length;i++){
                let balAfterOver = await web3.eth.getBalance(accounts[i+1]);  
                console.log('Bidder',i+1, '@', accounts[i+1], 'has balance', web3.utils.fromWei(balAfterOver), ' Eth.\n');
            }            

            // contract balance    
            contractBal = await web3.eth.getBalance(contractAddress);      
            console.log('\n\x1b[34m%s\x1b[0m','Contract ' + contractAddress +' has balance ' + web3.utils.fromWei(contractBal) + ' Eth.\n');

            // beneficiary balance
            //benBal = await web3.eth.getBalance(beneficiary);      
            //console.log('\n\x1b[34m%s\x1b[0m','Beneficiary has balance ' + web3.utils.fromWei(benBal) + ' Eth.\n');

            }
            else {
                console.log('\n\x1b[31m%s\x1b[0m','Still in bidding phase: Bids cannot be revealed yet.');
                setTimeout(check, 2000); // check again in 2 secs
            }
        }
        // Check if it is time to reveal.
        check();
                  
        

    } catch (error) {
        console.log(error.message);
    }
    finished(); 

};
