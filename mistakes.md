## Common mistakes

When using truffle console
* forgeting `await` e.g.

	instance  = await Contract.new() 

or 
	 a = await instance.function()

* Forgeting toString() works directly on BN. No need for any special web3.utils... call
