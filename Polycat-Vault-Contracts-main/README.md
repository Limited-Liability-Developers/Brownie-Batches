# Polycat-Vault-Contracts

PolyCat Vault Contracts Readme

These are the official polycat finance vault contracts forked from https://github.com/polycatfi

These contracts are written in solidity version ^0.6.0 and compiled/deployed using brownie.  Brownie is the python world’s Truffle. https://eth-brownie.readthedocs.io/en/stable/install.html

Install the dependencies
``` 
pip install eth-brownie
``` 

While inside main directory Polycat-Vault-Contracts, compile the contracts with
``` 
brownie compile
``` 

Add a new network (matic) to brownie networks config
``` 
brownie networks add matic matic-mainnet host="https://rpc-mainnet.maticvigil.com/v1/4b331c188697971af1cd6f05bb7065bc358b7e89" chainid=137 explorer="https://polygonscan.com/"
``` 

store your key in an environment variable (use a throwaway wallet when testing).  By storing it in an env variable and calling it with os.getenv() in python, we are able to prevent exposing our private key in our code.
``` 
export PRIVATE_KEY=0xsdoi485jfoq3409t834p3n9jy4tf834iweqior234809
``` 

To deploy to mainnet run **will not run yet*
``` 
brownie run scripts/deploy.py --network matic-mainnet
``` 

###############################################
#     update 8/3/21                           #
###############################################


# Contract Addresses
* VaultChef: ```0xFfAD7ef599B22674D141b24285D81246D82f283c```
* StrategyFish: ```0x2d73f791294EC87A6856698700D6e00BC2647841```

# Wallet Addresses Variables. 
* Fees: ```create new Wallet```
* Withdraw Fees: ```Create new Wallet```
* Vault: ```Create new Wallet```
* Buy Back: ```Create new Wallet```

# Creating a new repository

1.) Create new folder on desktop

2.) Clone desired repo into created folder
```
git clone https://github.com/<*REPO_PATH_HERE*>
```

3.) Create virtual environment
```
pipenv shell
```

4.) Install black
```
pipenv install --pre black
```

5.) Install brownie
```
pipenv install eth-brownie
```

6.) Change ganache path **optional if using ganache for testing
```
export PATH="/Users/<user>/.npm-global/bin:$PATH" >> ~/.bash_profile
```


# Using Brownie
Similar to Truffle in Javascript, Brownie allows for quick and easy handling of smart contracts on the Ethereum blockchain while using Python. The Brownie docs can be referenced here:
* https://eth-brownie.readthedocs.io/en/stable/install.html

## Network Configuration
Brownie network information can be viewed with the following:
```
brownie networks list true
```

Add a new network to brownie networks config

* Matic
``` 
brownie networks add Polygon matic-mainnet host="https://rpc-mainnet.maticvigil.com/v1/<*PROJECT_ID_HERE*>" chainid=137 explorer="https://polygonscan.com/"
``` 

* Mumbai (Matic testnet)
``` 
brownie networks add Polygon matic-testnet host="https://rpc-mumbai.maticvigil.com/v1/<*PROJECT_ID_HERE*>" chainid=80001 explorer="https://mumbai.polygonscan.com/"
```

* Matic Fork *Not Working*
```
brownie networks add Development matic-fork cmd=ganache-cli host="http://127.0.0.1" fork=matic-mainnet port=8545
```

## Account Configuration
Adding a personal account

* Store your key in an environment variable (use a throwaway wallet when testing).  By storing it in an env variable and calling it with os.getenv() in python, we are able to prevent exposing our private key in our code.
``` 
export PRIVATE_KEY=<*PRIVATE_KEY_HERE*>
```

* Load account into 'dev' (python script)
```
import os
myaccount = accounts.add(os.getenv("PRIVATE_KEY"))

```

## Compiling Contracts
Compile all contracts inside of the ```/contracts``` folder
* NOTE: This only compiles contracts that have changed since last compile
```
brownie compile
```

Force recompile of the entire project
```
brownie compile --all
```

## Deploying Contracts
Deploying your own contracts should be performed through writing a Python script of the following format:
```
from brownie import *
import os

def main():
    myaccount = accounts.add(os.getenv("PRIVATE_KEY"))
    dev = accounts.at(myaccount)
    return <*CONTRACT_NAME_HERE*>.deploy({'from': dev})
```

Keep in mind that the example above would be used for a contract that does not have any parameters in the constructor. Given your contract does have constructor parameters, the following changes need to occur:
```
return <*CONTRACT_NAME*>.deploy(param0, param1, param2, ..., {'from': dev})
```

Once the Python deploy script is written, the contract is deployed to the desired network
```
brownie run scripts/<*SCRIPT_NAME_HERE*> --network <*NETWORK_NAME_HERE*>
```

Upon deploying your contract, a transaction hash and contract address are returned through the terminal. **Record the contract address for later use.**

## Interacting with Contracts
### Your Own Contracts
!!!

### Others Contracts
In order to access already deployed contracts, the contract address and ABI are needed. This can be done through a Python script or in the brownie console.
```
contract = Contract.from_abi("<*NAME_HERE*>", "<*CONTRACT_ADDRESS_HERE*>", <*CONTRACT_ABI_HERE*>)
```

Once the contract is loaded into ```contract```, the contract **READ** functions are accessed through:
```
contract.<*FUNCTION_NAME_HERE*>(param0, param1, ...)
```

For **WRITE** functions, the following is used:
```
contract.<*FUNCTION_NAME_HERE*>(param0, param1, ..., {'from': <*USER_ACCOUNT_HERE*>})
```

## Brownie Console
The brownie console is used as an alternative to writing Python scripts and using ```brownie run ...``` to execute. Within the console, scripts can be written and functions can be called directly. Additionally, contracts and their functions can be called directly by using the same format as shown under *Interacting with Contracts*.

# Polycat Vault Contracts

These are the official polycat finance vault contracts forked from https://github.com/polycatfi.

These contracts are written in solidity version ^0.6.0 and compiled/deployed using brownie.

The following steps must be following for proper contract operation:

* 1.) Deploy ```VaultChef.sol```.
```
brownie run scripts/VaultChef_deploy.py --network <*NETWORK_NAME_HERE*>
```

* 2.) Construct strategy contracts for desired tokens and deploy. NOTE: See *Strategy Contracts* for more information.

* 3.) Add strategy contracts to the *VaultChef* contract to create pools.

* 4.) Users stake tokens in created pools.

* 5.) Harvest rewards and compound for each strategy contract.
```
<*STRATEGY_CONTRACT_HERE*>.earn({'from': <*OWNER_ACCOUNT_HERE*>})
```

## Strategy Contracts
The strategy contracts are critical for vault operation as they provide the logic needed to deposit, withdraw, harvest, etc. on other protocols. Each pool within the vault requires a "strategy" that is unique to the protocol and the staked token. This means that if 50 pools are in the vault, 50 strategy contracts with the specific pool information are deployed. A pool cannot be created without a strategy contract address though. Thus, the strategy contract must be deployed first and only then can be added to the vault.

### AAVE
#### Deploying Strategy Contracts
Before deploying a strategy contract, change the following addresses in ```StrategyAave.sol``` to your own.
* ```vaultAddress```
* ```feeAddress```
* ```withdrawFeeAddress```
* ```buyBackAddress```

!!!

### FISH
The ```StrategyFish.sol``` contract 

### Master Chef
!!!

### Quickswap
#### Deploying Strategy Contracts
Before deploying a strategy contract, change the following addresses in ```StrategyQuickSwap.sol``` to your own.
* ```vaultAddress```
* ```feeAddress```
* ```withdrawFeeAddress```
* ```buyBackAddress```

Using ```StrategyQuickswap_deploy.py```, the strategy contract for a desired Quickswap LP token can be created. Inside of ```main()```, the following parameters need to be set to reflect the pool you want to create.
* ```_vaultChefAddress```: ```VaultChef.sol``` contract address
* ```_wantAddress```: LP token address
* ```_token0```: Address for token 0 of the LP token
* ```_token1```: Address for token 1 of the LP token

#### Auto-Compounding
Harvest reward token

### Sushiswap
Using ```StrategySushiswap_deploy.py```, the strategy contract for a desired Sushiswap LP token can be created. Inside of ```main()```, the following parameters need to be set to reflect the pool you want to create.
* ```_vaultChefAddress```: ```VaultChef.sol``` contract address
* ```_pid```: 
* ```_wantAddress```: LP token address
* ```_token0```: Address for token 0 of the LP token
* ```_token1```: Address for token 1 of the LP token

### Vault Burn
!!!

## Adding a Pool to the Vault
Once a strategy contract is deployed, it can be added to the vault as a pool. This allows a user to stake in a pool and then the strategy contract will handle the backend work of the specific protocol.
```
# Assumming 'VaultChef' is your VaultChef.sol contract

VaultChef.addPool('<*STRATEGY_CONTRACT_ADDRESS_HERE*>', {'from': USER_ACCOUNT_HERE})
```
