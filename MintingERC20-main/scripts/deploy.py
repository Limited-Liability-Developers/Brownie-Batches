from brownie import *
import os

def main():
    myaccount = accounts.add(os.getenv("PRIVATE_KEY"))
    deploy = MinterToken.deploy({"from": myaccount})
