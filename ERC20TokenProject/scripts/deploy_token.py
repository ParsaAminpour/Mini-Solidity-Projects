from rich import print
from rich.console import Console
from brownie import config, accounts, KIA, network
import argparse
console = Console()

# name:str, symbol:str, total:int
def main():
    wallet_addr = config['wallets']['from_key']
    if wallet_addr != '':
        account = accounts.add(wallet_addr)
    else: account = accounts[0]

    token = KIA.deploy('KiaToken', 'KIA', 1e20,
        {'from' : account}, publish_source=True)
    

if __name__ == '__main__':
    main()
