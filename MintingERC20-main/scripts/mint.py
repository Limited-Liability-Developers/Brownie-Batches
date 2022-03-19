from brownie import *
import os

def main():
    myaccount = accounts.add(os.getenv("PRIVATE_KEY"))
    minter = MinterToken[0]
    mint = minter.mintRack({"from": myaccount})
    