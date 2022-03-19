from brownie import *
import os

def erc20(address):
    erc20 = interface.IERC20(str(address))
    return erc20

def checkBalance():
    aave = interface.IERC20("0x7fc66500c84a76ad7e9c93437bfc5ac33e2ddae9")
    balance = aave.balanceOf("0x3f5CE5FBFe3E9af3971dD833D26bA9b5C936f0bE")
    return balance

def main():
    forkeddev = accounts.at('0x3f5CE5FBFe3E9af3971dD833D26bA9b5C936f0bE', force=True)
    aave = "0x7fc66500c84a76ad7e9c93437bfc5ac33e2ddae9"

    aaveERC20 = interface.IERC20(aave)
    withdrawamount = 9 *10**18


    vaultID = 0 #first vault ID is 0 because its an array :) 
    
    Vault[0].withdraw(9*10**18, 0, {"from": forkeddev})

