from brownie import config, accounts, network, TaskToken
from rich.console import Console 
console = Console()

def main():
    token = TaskToken.deploy({'from':accounts[0]})
    console.log(token.address)