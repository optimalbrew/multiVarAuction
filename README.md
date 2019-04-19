## Smart Contracts for Scoring Auctions on Ethereum 

This project implements smart contracts for *Scoring Auctions* on Ethereum for the specific use case of  **"Cost + Time" bidding.** 

Cost + Time bidding is a procurement mechanism used by various state departments of transportation to incentivize contractors to minimize construction costs as well as time. In these processes, contractors submit 2-part bids that include a "price quote" (cost to complete project) and a "time quote" (days to complete the project). Bids are compared using a scoring rule that uses an estimate of the "Cost of Time". 

### Example
Suppose a contractor bids a *cost* of USD 800K and *completion time*  of 3 weeks. Let the DOT's estimate for cost-of-time be USD 200K/week. Then  the **bid score** is 800 + (3 X 200) = USD 1400K. Naturally, the bidder with the **lowest score** wins. 



### Implementation

The project uses the [Truffle suite](https://truffleframework.com/). In addition to Node and Truffle, the Ganache command line interface (`ganache-cli`) is also needed to run the demo example.  

### Set up to run the demo on AWS/EC2

Basic setup to work with auction contracts on ethereum using truffle and ganache-cli.

	git clone https://github.com/petecarkeek/multiVarAuction.git  
	cd multiVarAuction

Then use the set up script `myAWSsetup.sh` (and `chmod +x`) to install node, python, dev tools, Truffle, Ganache, 
Open Zeppelin. Works fine on Ubuntu 18.04 LTS on AWS EC2 (T2 micro) instance.

### Running the demo

Use `ganache-cli` to start an Ethereum client

	ganache-cli -h 0.0.0.0 -p 7545

Once the client is running and listening on the specified port, use `truffle console` from a **different terminal** to deploy and interact with the contracts

	truffle console

From truffle console

	compile
	deploy

View the deployment on the test network

	networks

Run the demo

	exec scripts/test2.js

### Background Information

For additional  details regarding cost + time bidding  see [CalTrans policy directive](http://www.dot.ca.gov/pd/directive/PD-14-Cost-and-Time-Bidding.pdf). 


For academic research on the effectiveness of scoring auctions see 
* [*Procurement Contracting With Time Incentives: Theory and Evidence,* **Gregory Lewis and Patrick Bajari**, *The Quarterly Journal of Economics*, Volume 126, Issue 3, August 2011, Pages 1173–1211](https://doi.org/10.1093/qje/qjr026)
* [*Contractors’ and Agency Decisions and Policy Implications in A+B Bidding,* **Diwakar Gupta, Eli M. Snir,  Yibin Chen**, *Production and Operations Management* February 2014](https://doi.org/10.1111/poms.12217)
