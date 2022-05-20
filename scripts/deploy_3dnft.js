const { ethers, upgrades, network, run } = require("hardhat");
const { getEnvAddr } = require('../env.js')

async function main () {
    const addrs = getEnvAddr(network.config.chainId)

    const Sm3d = await ethers.getContractFactory("Soulmeta3dnft");
    const params = [
        addrs.soul
    ]
    const sm3d = await Sm3d.deploy(...params);
    await sm3d.deployed();
    console.log("Soulmeta3dnft deployed to:", sm3d.address);

    await run("verify:verify", {
        address: sm3d.address,
        constructorArguments: params,
    });
    console.log("Verify Soulmeta3dnft Successfully.");
}

main()
    .then(() => process.exit(0))
    .catch((error) => {
        console.error(error)
        process.exit(1)
    })
