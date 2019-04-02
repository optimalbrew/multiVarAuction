//Not a standard test. Just checking scripts as a way to interact with contracts.
// single parameter callback function to run scripts using truffle exec
module.exports = async function(finished){
    const Auction = artifacts.require("./Auction.sol");

    console.log('Here we go. Deploying instance..');
    let instance = await Auction.deployed();    
    try {
        let accounts = await web3.eth.getAccounts();
        //console.log(accounts);
        instance = await Auction.new(60,30,accounts[9]);
        let contractAddress = instance.address;
        console.log('New instance deployed at ' + contractAddress);
        let contractBal = await web3.eth.getBalance(contractAddress);      
        console.log('New instance has balance ' + contractBal + ' wei.');
                
    } catch (error) {
        console.log(error.message);
    }
    finished(); 

};
