#!/bin/bash

# Set up script for Ubuntu 18.04 LTS on AWS t2 micro instance
# assumes repo has already been cloned so this setup script is available!
# git clone https://github.com/petecarkeek/multiVarAuction.git  
# cd multiVarAuction

sudo apt-get update

echo 'Set up memory swap'
# memory swap set up
sudo dd if=/dev/zero of=/swapfile bs=1M count=512
sudo mkswap /swapfile
sudo swapon /swapfile
sudo chown root:root /swapfile
sudo chmod 0600 /swapfile

echo 'Installing node v10.15.3'
## install node
wget https://nodejs.org/dist/v10.15.3/node-v10.15.3-linux-x64.tar.xz
tar -xf node-v10.15.3-linux-x64.tar.xz

sudo mv node-v10.15.3-linux-x64 /usr/local/
sudo ln -s /usr/local/node-v10.15.3-linux-x64/bin/node /usr/bin/node
node --version

## 
sudo ln -s /usr/local/node-v10.15.3-linux-x64/bin/npm /usr/bin/npm
sudo ln -s /usr/local/node-v10.15.3-linux-x64/bin/npx /usr/bin/npx

npm --version
npx --version


## Install truffle
echo 'Installing truffle'
npm install -g truffle

sudo ln -s /usr/local/node-v10.15.3-linux-x64/bin/truffle /usr/bin/truffle

echo 'Print truffle version and components'
truffle version

# install ganache-cli
echo 'Installing ganache-cli'

npm install -g ganache-cli 

sudo ln -s /usr/local/node-v10.15.3-linux-x64/bin/ganache-cli /usr/bin/ganache-cli

# Also install openzep sol test
echo 'Installing open zeppelin'

npm install -g openzeppelin-solidity

