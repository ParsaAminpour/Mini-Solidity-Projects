from rich import print
from rich.console import Console
from brownie import config, accounts, ERC20Token
import sys, time, warning

def main(name:str, symbol:str, total:int):
    global token_name, token_symbol, total_supply, account
    token_name, token_symbol, total_supply = name, symbol, total
    
    account = accounts.add(config.get('wallets').get('from_key',accounts[0])

    token = ERC20Token.deploy(token_name, token_symbol, total_supply,
        {'from' : account})
    
    

        
