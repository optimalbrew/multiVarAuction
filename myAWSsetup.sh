#!/bin/bash

# Set up script for Ubuntu 18.04 LTS on AWS t2 micro instance
# assumes repo has already been cloned so this setup script is available!
# git clone https://github.com/petecarkeek/multiVarAuction.git  
# cd multiVarAuction
# chmod +x myAWSsetup.sh

sudo apt-get update

printf '\n\nSet up memory swap\n\n'
# memory swap set up
sudo dd if=/dev/zero of=/swapfile bs=1M count=512
sudo mkswap /swapfile
sudo swapon /swapfile
sudo chown root:root /swapfile
sudo chmod 0600 /swapfile


printf '\n\ninstalling python2 and build-essential (for use in the future)\n\n'

sudo apt.get install -y python

sudo apt install -y build-essential

printf '\n\nInstalling node v10.15.3\n\n'
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
printf '\n\nInstalling truffle\n\n'
npm install -g truffle

sudo ln -s /usr/local/node-v10.15.3-linux-x64/bin/truffle /usr/bin/truffle

printf '\n\nPrint truffle version and components\n\n'
truffle version

# install ganache-cli
printf '\n\nInstalling ganache-cli\n\n'

npm install -g ganache-cli 

sudo ln -s /usr/local/node-v10.15.3-linux-x64/bin/ganache-cli /usr/bin/ganache-cli

# Also install openzep sol test
printf '\n\nInstalling open zeppelin\n\n'

npm install -g openzeppelin-solidity

