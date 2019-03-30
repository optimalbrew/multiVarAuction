## Getting started Truffle and Ganache

### Truffle
https://github.com/trufflesuite/truffle

Javascript based ethereum development environment + testing framework. Works nicely with React and other front ends.


### Ganache
* A blockchain for local development. A way to test contracts without using the mainnet or the testnets (no mining or faucets needed).
* available as a desktop app as well as a CLI.

*ganache-cli* is what was previously known as *testrpc*. 

https://github.com/trufflesuite/ganache-cli/blob/master/README.md


### Basic ubuntu ec2 setup

Tested on Ubuntu 16.04  or 18.04 LTS.

    sudo apt-get update  && sudo apt-get -y upgrade


Optional for small/micro instances: 

    free -m #check how much memory we have
    sudo dd if=/dev/zero of=/swapfile bs=1M count=512
    #sudo dd if=/dev/zero of=/swapfile bs=1G count=2 

    sudo mkswap /swapfile
    sudo swapon /swapfile
    sudo chown root:root /swapfile
    sudo chmod 0600 /swapfile

### Python and devtools?
Not needed right away, but eventually.

    sudo apt install python #for python2
    sudo apt-get install build-essential #gcc

### Install node
Do not install system version. This will also install *npm* (manage packages) and *npx* (execute packages)

    wget https://nodejs.org/dist/v10.15.3/node-v10.15.3-linux-x64.tar.xz
    tar -xf node-v10.15.3-linux-x64.tar.xz

Copy to /usr/local/ and then create symlinks

    sudo mv node-v10.15.3-linux-x64 /usr/local/
    sudo ln -s /usr/local/node-v10.15.3-linux-x64/bin/node /usr/bin/node
    node --version

Then symlink npm and npx and check those

    sudo ln -s /usr/local/node-v10.15.3-linux-x64/bin/npm /usr/bin/npm
    sudo ln -s /usr/local/node-v10.15.3-linux-x64/bin/npx /usr/bin/npx

    npm --version
    npx --version
    

### Install truffle and ganache

    npm install -g truffle

    sudo ln -s /usr/local/node-v10.15.3-linux-x64/bin/truffle /usr/bin/truffle

    truffle version

This will print out something like (**this includes Web3.js**)

    Truffle v5.0.8 (core: 5.0.8)
    Solidity v0.5.0 (solc-js)
    Node v10.15.3
    Web3.js v1.0.0-beta.37



For a default set of contracts and tests, run the following within an **empty** project directory:

    truffle init #run only EMPTY dir

From there, you can run `truffle compile`, `truffle migrate` and `truffle test` to compile your contracts, deploy those contracts to the network, and run their associated unit tests.

Truffle comes bundled with a local development blockchain server that launches automatically when you invoke the commands above. If you'd like to configure a more advanced development environment we recommend you install the blockchain server separately by running 

    npm install -g ganache-cli 

    sudo ln -s /usr/local/node-v10.15.3-linux-x64/bin/ganache-cli /usr/bin/ganache-cli

Let's see if that works

    ganache-cli -h 0.0.0.0 -p 7545 --verbose #skip verbose 

default port is 8545. 

