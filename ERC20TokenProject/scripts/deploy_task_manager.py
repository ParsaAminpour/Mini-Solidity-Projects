from brownie import config, accounts, network, Taskmanager 
from rich.console import Console
from rich import print
import hashlib, sys, random
from datetime import datetime as dt
console = Console()

def generate_task_id(owner_address:str):
    timestamp = str(dt.timestamp(dt.now())).split('.')[0]  #without momiez
    nonce = random.randint(100,999)
    hashed = owner_address + str(timestamp) + str(nonce)
    return hashed[:7]


def main():
    owner_address = "0xe2A6c9cFBc1571114ABCF92D5C3C3520434Ee548"
    task_id = generate_task_id()
    Taskmanager.deploy(owner_address, task_id)

