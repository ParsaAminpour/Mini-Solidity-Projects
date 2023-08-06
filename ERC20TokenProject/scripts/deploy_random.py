from brownie import config, accounts, GenerateRandomNumLink


def main():
    cont = GenerateRandomNumLink.deploy()
    return cont.address
