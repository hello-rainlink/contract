By default, you have a plugin wallet and the ability to publish contracts. The following is just a simple guide

The entire contract project is located under src/and mainly includes the following parts:

###Deploy contracts using remix
Ethereum usage: https://remix.ethereum.org/#lang=en&optimize=true&runs=200&evmVersion=london&version=soljson-v0.8.20+commit.a1b79de6.js
Wave field usage: https://www.tronide.io/#optimize=true&runs=200&evmVersion=null&version=soljson_v0.8.20+commit.5f1834b.js



Contract deployment sequence:
1. Release the Admin contract first. Select core/Admin.sol
Activate the plugin wallet signature, sign the transaction, and wait for on chain completion. Record the Admin contract address again.

2. Deploy 4 empty proxy contracts, default proxy Admin itself, steps: 1. Select proxy/HypProxy; Fill in the Admin contract address for both IMPL and A_Admin parameters. Data fixed value 0x.
After deployment, record four proxy addresses, which we collectively refer to as Proxy 1 Proxy2、Proxy3、Proxy4.

3. [Visit](https://tron-converter.com/) Convert Proxy 1-4 to Hex address
And record the corresponding Hex address.

4. Modify the ValidatorAdd parameter in core/Comn.sol to the value of Proxy1. It should be noted that when sending contracts on the Tron chain, the Types ChainType constant ChainType=Types must be enabled. Chain type. TRX。 Enable the ChainType constant ChainType=Types for other chain contracts. Chain type. ETH！

5. Modify the address of Message Addr in token/Commn.sol to be the value of Proxy 2, Pool Addr to be the value of Proxy 3, and Executor to be the value of Proxy 4. The WTOKN_EXPRESS here corresponds to the Warp address of the corresponding main currency on the current chain and network.You can also publish comn/WToken.sol to the current chain and record WTOKN_EXPRESS. It should be noted that when publishing WToken contracts, the contract name and token information in the contract need to be changed for the current chain.
WETH 18
WBNB 18
WTRX 6

6. Publish four logical contracts: core/Virtual.sol, core/Messenger. sol, token/Pool.sol, and token/Executor.sol, and record the corresponding addresses.

7. Proxy Proxy 1-4 onto a real logical contract. The steps to proxy the Executor contract are as follows: open and select MyProxy. sol; Enter the Proxy 4 contract address and at Address to obtain the contract method; Select the proxy Update Implementation method and fill in the Executor logical contract address; Submit updates and sign the transaction for on chain confirmation.

8. We also need to send comn/TokenBatch.sol and record the contract address.

Complete the above 8 steps to deploy the entire contract.