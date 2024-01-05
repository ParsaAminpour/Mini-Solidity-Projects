import { HardhatUserConfig } from "hardhat/config";
import "@nomicfoundation/hardhat-toolbox";
import { ethers } from "ethers";
import "hardhat-gas-reporter";
// import delay from "delay";
import "solidity-coverage";
import { HardhatEthersSigner } from "@nomicfoundation/hardhat-ethers/signers";
import { HardhatConfig, HardhatRuntimeEnvironment } from "hardhat/types";
// require("@nomiclabs/hardhat-etherscan");
require("dotenv").config();

const INFURA_API_KEY = process.env.WEB3_INFURA_ENDPOINT;

const delay = (ms: number) => {
  return new Promise((resolve) => {
    setTimeout(resolve, ms);
  })
}

// task scopes
const account_scope = scope("account-scope", "Accounts details");

const contract_status = scope("contract-status", "The status report from smart contract");


account_scope.task("balance", "Prints the balances of all accounts")
  .addParam("accounts", "The accounts' addresses")
  .setAction(async(_acc_address: string , hre: HardhatRuntimeEnvironment) => {
    try {
      const accounts: HardhatEthersSigner[] = await hre.ethers.getSigners();
      const addr = _acc_address.accounts;
      const is_exist = (accounts as Array<HardhatEthersSigner>)
        .some(acc => acc.address === addr);
      
      if(!is_exist) throw "account doesn't exist";

      const balance: bigint = await hre.ethers.provider.getBalance(addr);
      console.log(`The balance is ${ethers.formatEther(balance)} ETH\n`);
    }

    catch(err){
      console.error(err);
      process.exitCode = 1;
    }
  })


const config: HardhatUserConfig = {
  solidity: "0.8.20",

  gasReporter: {
    enabled: true,
    outputFile: "gas-report.txt",
    currency: "USD",
    token: "ETH",
    gasPrice: 20,
    coinmarketcap: process.env.COINMARKETCAP_API_KEY || "",
    noColors: true,
  }
};

export default config;
