import { HardhatRuntimeEnvironment } from "hardhat/types";
import { DeployFunction } from "hardhat-deploy/dist/types";

const deployAnyaToken: DeployFunction = async function (
  hre: HardhatRuntimeEnvironment
) {
  const {
    deployments: { deploy },
    getNamedAccounts,
  } = hre;

  const { deployer } = await getNamedAccounts();

  const tx = await deploy("AnyaToken", {
    from: deployer,
    log: true,
    waitConfirmations: 1,
  });
};

export default deployAnyaToken;
deployAnyaToken.tags = ["AnyaToken"];
