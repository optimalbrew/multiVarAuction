## Deploying and Interacting with Contracts

Start the project

    truffle init

This will create basic directory structure: `contracts`, `migrations`, etc. These will contain helper programs for deployment.

* Move relevant source files to contracts (Auction.sol) and migrations (2_deploy_contracts.js)

### Local Test Network

Get ganache started on a different termina via `ganache-cli` with host and port options, e.g. `ganache-cli -h 0.0.0.0 -p 7545`

### Deploying to the network

Command line:
 
    truffle console

In the console

    compile

then deploy to the chain

    migrate

check the deployment via 

    networks //--clean option to clean up past deployments

### Interactions

Use the web3 library to connect to the ethereum network

    let accounts = await web3.eth.getAccounts()

example, check balance

    web3.eth.getBalance(accounts[0])

connect to the deployed contract (with same arguments as in )

    let instance = await Auction.deployed()

or to a new instance of a contract (with **new arguments** for the *constructor*)

    let instance = await Auction.new(200,200,accounts[0])
    
    instance = await Auction.new(200,200,accounts[0]) //if instance already declared

Choose a new bid (encrypted)

    let encBid1 = await web3.utils.keccak256('10')

Submit bid to the contract

    let bid1 = instance.bid(encBid1, {from: accounts[1],value: 15})

Take a look at the transaction

    bid1

Another one
    let encBid2 = await web3.utils.keccak256('8')
    let bid2 = instance.bid(encBid2, {from: accounts[2],value: 8})

To clear all deployements use `networks --clean`