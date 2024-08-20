import type { SignerWithAddress } from "@nomiclabs/hardhat-ethers/signers"
import { task, types } from "hardhat/config"
import type { TaskArguments } from "hardhat/types"

import { verify } from "."

task("deploy:DendrETH")
  .addParam("lightclient", "address of the the light client contract", undefined, types.string)
  .addParam("sourcechainid", "source chain ID", undefined, types.int)
  .addFlag("verify", "whether to verify the contract on Etherscan")
  .setAction(async function (taskArguments: TaskArguments, hre) {
    console.log("Deploying DendrETH adapter...")
    const signers: SignerWithAddress[] = await hre.ethers.getSigners()
    const DendrETHAdapter = await hre.ethers.getContractFactory("DendrETHAdapter")
    const constructorArguments = [taskArguments.sourcechainid, taskArguments.lightclient] as const
    const dendrethAdapter = await DendrETHAdapter.connect(signers[0]).deploy(...constructorArguments)
    await dendrethAdapter.deployed()
    console.log("DendrETH adapter deployed to:", dendrethAdapter.address)
    if (taskArguments.verify) await verify(hre, dendrethAdapter, constructorArguments)
  })
