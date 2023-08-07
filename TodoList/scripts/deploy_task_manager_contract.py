from brownie import config, accounts, network, SimpleTaskManager
from rich.console import Console
from rich import print
from rich.logging import RichHandler
from datetime import datetime as dt
import logging, sys
console = Console()

logging.basicConfig(
    level="NOTSET",
    format="%(message)s",
    datefmt="[%X]",
    handlers=[RichHandler(rich_tracebacks=True)]
)
log = logging.getLogger("rich")


def main():
    global wallet_addr
    if network.show_active() != 'sepolia2':
        log.exception('Netowrk is not on Sepolia')
    
    wallet_addr = config['wallets']['from_key']
    if not wallet_addr == '':
        account = accounts.add(wallet_addr)
    else: account = accounts[0]
    SimpleTaskManager.deploy({'from' : account},
                             publish_source=True)










