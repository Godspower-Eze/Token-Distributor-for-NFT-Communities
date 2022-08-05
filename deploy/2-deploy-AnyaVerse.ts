import { HardhatRuntimeEnvironment } from "hardhat/types";
import { DeployFunction } from "hardhat-deploy/dist/types";
import { Framework } from "@superfluid-finance/sdk-core";
import { ethers } from "hardhat";

const deployAnyaVerse: DeployFunction = async function (
  hre: HardhatRuntimeEnvironment
) {
  const {
    deployments: { deploy, get },
    getNamedAccounts,
  } = hre;

  const url = process.env.GOERLI_URL;
  const httpProvider = new ethers.providers.JsonRpcProvider(url);
  const network = await httpProvider._networkPromise;
  

  // Setting up the out Framework object with Goerli
  const sf = await Framework.create({
    chainId: network.chainId,
    provider: httpProvider,
  });
    
  const SuperAnyaToken = await get("SuperAnyaToken");

  const { deployer } = await getNamedAccounts();

  const tx = await deploy("AnyaVerse", {
    from: deployer,
    log: true,
    waitConfirmations: 1,
    proxy: {
      owner: deployer,
      proxyContract: "OptimizedTransparentProxy",
      execute: {
        methodName: "initialize",
        args: [sf.settings.config.hostAddress, SuperAnyaToken.address],
      },
    },
  });
};

export default deployAnyaVerse;
deployAnyaVerse.tags = ["AnyaVerse"];
