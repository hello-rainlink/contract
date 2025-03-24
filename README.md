The entire contract project is located under src/and mainly includes the following parts:

###Deploy contracts using remix
Ethereum usage: https://remix.ethereum.org/
Wave field usage: https://www.tronide.io/

Contract deployment sequence:

1. Deploy core/Admin.sol administrator contract
After successful deployment, proxy/AdminProxy. sol can be used to proxy the administrator contract and initialize the administrator through the initMaster method of executing logical contracts through the proxy contract.
After setting it up, add the administrator proxy contract address to the AdminAddr of Comn.sol

2. Deploy core/Validator. sol and use proxy/HypProxy. sol to proxy it out.
Then add the proxy contract address to the ValidatorAddr of Comn.sol

3. Create two empty proxy/MyProxy.sol proxy contracts separately to proxy token/Pool.sol token/Executor.sol.
Then add the two proxy contract addresses to Comn.sol's PoolAddr and ExecutorAddr
Note: When publishing Message. sol on the Tron chain, it is necessary to change the internal/core/Commn method: ChainType uint8 (Types. ChainType. ETH) to uint8 (Types. ChainType. TRX)

4. Deploy the core/Message. sol message contract and use proxy/HypProy.sol proxy to execute the init method of the logical contract through the proxy contract.
Then add the proxy contract address to the Messenger Addr of Comn.sol

5. Deploy token/Pool.sol and token/Executor.sol pool sub contracts, and then use the proxy contract generated in step 3 to re proxy the pool and executor logical contracts.
Finally, execute the init method of the logical contract through the executor proxy contract.