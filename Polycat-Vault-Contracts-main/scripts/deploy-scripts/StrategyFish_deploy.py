from brownie import *
import os

def main():
    myaccount = accounts.add(os.getenv("PRIVATE_KEY"))
    dev = accounts.at(myaccount)
    StrategyFish.deploy('0x50b6755845E3c8593EF4EEBC996CFf0ca131bb5c', {'from': dev})