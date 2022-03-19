from brownie import *
import os

def erc20(address):
    erc20 = interface.IERC20(str(address))
    return erc20

def main():
    forkeddev = accounts.at('0x3f5CE5FBFe3E9af3971dD833D26bA9b5C936f0bE', force=True)
    aave = "0x7fc66500c84a76ad7e9c93437bfc5ac33e2ddae9"

    aaveERC20 = interface.IERC20(aave)
    depositamount = 9 *10**18

    aaveERC20.approve("0x4D912D80402f7C9290263A78773BB37E1510129e", depositamount, {"from": forkeddev})

    Vault[0].createVault(aave, {"from": forkeddev})

    vaultID = 0 #first vault has 0 ID
    
    Vault[0].deposit(depositamount, vaultID, {"from": forkeddev})