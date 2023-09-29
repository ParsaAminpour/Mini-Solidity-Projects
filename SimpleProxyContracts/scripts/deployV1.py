from datetime import datetime as dt
from brownie import (
    accounts,
    SimpleVoteV1,
    SimpleVoteV2,
    ProxyAdmin, 
    TransparentUpgradeableProxy,
    config,
    network, 
    Contract
)
from rich import print
import time, sys


animation = [
"[        ]",
"[=       ]",
"[===     ]",
"[====    ]",
"[=====   ]",
"[======  ]",
"[======= ]",
"[========]",
"[ =======]",
"[  ======]",
"[   =====]",
"[    ====]",
"[     ===]",
"[      ==]",
"[       =]",
"[        ]",
"[        ]"
]
def until_complete(message:str, period:int):
    flag_ = 0
    i = 0
    death = int(dt.now().timestamp()) + period

    while flag_ == 0:
        print(animation[i % len(animation)], message, sep=' ', end='\r')
        time.sleep(.1)
        i += 1

        if int(dt.now().timestamp()) == death: flag_ = 1 



def deploy_simple_vote_v1():
    acc = accounts[0]
    print(acc)

    simpleVote = SimpleVoteV1.deploy({'from':acc})

    init = simpleVote.initialize({'from':acc, 'value':1e6})
    init.wait(1)
    print(f"SimpleVoteV1 contract created at: {simpleVote.address}\nAnd the owner is {simpleVote.owner()[:6]}...\n")

    set_vote_tx = simpleVote.setVote("Killing Ali Khameneiee", {'from':acc})
    set_vote_tx.wait(1)
    
    vote_signatuer = set_vote_tx.events['LogSignature']['signature']

    print(f"""[bold green]{acc.address[:10]}...[/bold green] created new Vote\n\
          The Signature is => {vote_signatuer}\n\
          The Vote Message is => [bold purple]{simpleVote.VotesMap(vote_signatuer)}[/bold purple]\n""")

    until_complete("[bold green]Preperation for proxies to upgrade contract in future[/bold green]", 3)


    # Make the SimpleVoteV1 smart contract 'upgrade-able'

    admin = ProxyAdmin.deploy({'from':acc})
    print(f"Proxy admin is => {admin}")

    proxy = TransparentUpgradeableProxy.deploy( 
        simpleVote.address, admin, b'' ,{'from':acc, 'gas_limit':1e6})

    proxy_contract = Contract.from_abi("SimpleVoteV1", proxy.address, simpleVote.abi)

    print(f"[bold green]The proxy_contract address is {proxy_contract.address}[/bold green]")
    print(f"Proxy contract status_number is => {proxy_contract.getStatusNumber()}")
    print(f"SimpleVoteV1 contract status_number is => {simpleVote.getStatusNumber()}")




    
def prepare_proxy_v2():
    acc = accounts[0]
    simpleVoteV2 = SimpleVoteV2.deploy({'from':acc})

    # -1 is based on a brownie docs that gives us last instance
    PROXY_ADMIN = ProxyAdmin[-1]
    PROXY = TransparentUpgradeableProxy[-1]

    upgrade_tx = PROXY_ADMIN.upgrade(
        PROXY, simpleVoteV2, {'from':acc}
    )
    upgrade_tx.wait(1)

    upgraded_contract = Contract.from_abi("SimpleVoteV2", PROXY.address, SimpleVoteV2.abi)
    print(f"[bold green]The SimpleVoteV1 successfuly upgraded to SimpleVoteV2 in address of\n{upgraded_contract.address}[/bold green]")
    print(f"[bold green]And now we are able to add memeber to our contract\n[/bold green]")

    NEW_MEMBER = accounts[1]
    adding_new_member_tx = upgraded_contract.addMemeberDao(NEW_MEMBER, {'from':acc})
    print(upgraded_contract.status_number())


def main():
    deploy_simple_vote_v1() 
    _ = int(input("Should continue to upgrading contract (1 or 0)?"))

    if _ == 0:
        sys.exit()
    
    prepare_proxy_v2()
    

    
    