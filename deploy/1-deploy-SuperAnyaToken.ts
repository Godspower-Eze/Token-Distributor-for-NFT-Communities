import { HardhatRuntimeEnvironment } from "hardhat/types";
import { DeployFunction } from "hardhat-deploy/dist/types";
import { Framework } from "@superfluid-finance/sdk-core";
import { ethers } from "hardhat";

const deploySuperAnyaToken: DeployFunction = async function (
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

  const { deployer } = await getNamedAccounts();

  const AnyaToken = await get("AnyaToken");

  const tx = await deploy("SuperAnyaToken", {
    from: deployer,
    log: true,
    args: [sf.settings.config.hostAddress],
    waitConfirmations: 1,
    proxy: {
      owner: deployer,
      proxyContract: "OptimizedTransparentProxy",
      execute: {
        methodName: "initialize",
        args: [AnyaToken.address, 18, "Super Anya Token", "SAT"],
      },
    },
  });
};

export default deploySuperAnyaToken;
deploySuperAnyaToken.tags = ["SuperAnyaToken"];
