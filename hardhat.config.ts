import * as dotenv from "dotenv";

import { HardhatUserConfig } from "hardhat/config";
import "@nomiclabs/hardhat-etherscan";
import "@nomiclabs/hardhat-waffle";
import "@typechain/hardhat";
import "@tenderly/hardhat-tenderly";
import "hardhat-deploy";

dotenv.config();

const config: HardhatUserConfig = {
  solidity: {
    version: "0.8.14",
    settings: {
      optimizer: {
        enabled: true,
        runs: 500,
      },
    },
  },
  networks: {
    goerli: {
      url: process.env.GOERLI_URL,
      accounts: {
        mnemonic: process.env.MNEMONIC || "",
      },
    },
  },
  etherscan: {
    apiKey: process.env.ETHERSCAN_API_KEY,
  },
  namedAccounts: {
    deployer: {
      default: 0,
    },
    godspower: {
      default: 1,
    },
  },
  mocha: {
    timeout: 50000000
  },
};

export default config;
