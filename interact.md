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

    migrate //or deploy

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

    instance = await Auction.new(60,30,accounts[9]) //30 seconds bidding and reveal time for testing.
    let contractAddress = instance.address
    web3.eth.getBalance(contractAddress)

Example bids (with indicators for fake and nonce)

    let bidVal1 = [5,10]
    let fake1 = [false,true]
    let secret = web3.utils.asciiToHex('secret',32)
    let sec1 = [secret,secret]

Encrypt the bid

    let encBid10 = web3.utils.soliditySha3({t:'uint' , v: bidVal1[0]}, {t: 'bool', v: fake1[0]},{t:'bytes32' ,v: sec1[0]})
    let encBid11 = web3.utils.soliditySha3({t:'uint' , v: bidVal1[1]}, {t: 'bool', v: fake1[1]},{t:'bytes32' ,v: sec1[1]})
    

Submit  encrypted bid (with deposit) to the contract

    let bid10 = instance.bid(encBid10, {from: accounts[1],value: 15})
    web3.eth.getBalance(accounts[9]) //something other than accounts[0], as that has already spent eth as default account
    web3.eth.getBalance(accounts[1])
    web3.eth.getBalance(contractAddress)

    let bid11 = instance.bid(encBid11, {from: accounts[1],value: 12})
    web3.eth.getBalance(accounts[9])
    web3.eth.getBalance(accounts[1])
    web3.eth.getBalance(contractAddress)

Reveal bids

    let reveal1 = instance.reveal(bidVal1, fake1, sec1, {from: accounts[1]})


Ending the auction

    end = instance.auctionEnd({from: accounts[9]})

    web3.eth.getBalance(accounts[9])
    web3.eth.getBalance(accounts[1])
    web3.eth.getBalance(contractAddress)

