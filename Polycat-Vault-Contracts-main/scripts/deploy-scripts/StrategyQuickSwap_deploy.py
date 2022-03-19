from brownie import *
import os


def deploy(_VaultChef, _wantAddr, _dev):
    VaultChef = _VaultChef
    wantAddr = _wantAddr
    token0 = interface.IUniPair(wantAddr).token0()
    token1 = interface.IUniPair(wantAddr).token1()
    dev = _dev

    QuickswapRouter = '0xa5E0829CaCEd8fFDD4De3c43696c57F7D7A678ff'
    USDC = '0x2791bca1f2de4661ed88a30c99a7a9449aa84174'
    QUICK = '0x831753dd7087cac61ab5644b308642cc1c33dc13'
    FISH = '0x3a3df212b7aa91aa0402b9035b098891d276572b'
    WMATIC = '0x0d500b1d8e8ef31e21c99d1db9a6444d3adf1270'

    StrategyQuickSwap.deploy(
        VaultChef,          # Vault Chef address
        QuickswapRouter,    # Quickswap Router address
        wantAddr,           # Want lp token address
        QUICK,              # Earned address (QUICK)
        [QUICK, WMATIC],    # QUICK -> WMATIC
        [QUICK, USDC],      # QUICK -> USDC
        [QUICK, FISH],      # QUICK -> FISH
        [QUICK, token0],    # QUICK -> Token 0
        [QUICK, token1],    # QUICK -> Token 1
        [token0, QUICK],    # Token 0 -> QUICK
        [token1, QUICK],    # Token 1 (USDT) -> QUICK
        {'from': dev}
    )


def main():
    myaccount = accounts.add(os.getenv("PRIVATE_KEY"))
    dev = accounts.at(myaccount)
    deploy(
        '0xFfAD7ef599B22674D141b24285D81246D82f283c',   # VaultChef
        '0xf6422b997c7f54d1c6a6e103bcb1499eea0a7046',   # LP
        dev
    )