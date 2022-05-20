const { ethers, upgrades, network, run } = require('hardhat')
const { getEnvAddr } = require('../env.js')

const addrs = getEnvAddr(network.config.chainId)
let store, controller

async function deploy (){
    console.log('Deploying V2 on the chainId ' + network.config.chainId)

    const Store = await ethers.getContractFactory('SoulmetaStore')
    store = await upgrades.deployProxy(Store)
    await store.deployed()
    console.log('Store deployed to: ', store.address)

    const params = [
        [
            addrs.usdt,
            store.address,
            addrs.soul1155,
            addrs.soul721,
            addrs.soul,
            addrs.team,
            addrs.soulPair,
            ...addrs.storeDist,
            addrs.soulAirdrop
        ]
    ]
    const Controller = await ethers.getContractFactory('SoulmetaController')
    controller = await upgrades.deployProxy(Controller, params)
    await controller.deployed()
    console.log('Controller deployed to: ', controller.address)


}

async function getDeployed() {
    store = await ethers.getContractAt('SoulmetaStore', addrs.store)
    controller = await ethers.getContractAt('SoulmetaController', addrs.controller)
}

async function verify() {
    const storeImpl = await upgrades.erc1967.getImplementationAddress(store.address)
    console.log('StoreImpl deployed to: ', storeImpl)
    await run('verify:verify', {
        address: storeImpl
    })
    console.log('Verify Store Successfully.')

    const controllerImpl = await upgrades.erc1967.getImplementationAddress(controller.address)
    console.log('ControllerImpl deployed to: ', controllerImpl)
    await run('verify:verify', {
        address: controllerImpl,
    })
    console.log('Verify Controller Successfully.')
}

async function init() {
    const smb = await ethers.getContractAt('SoulmetaItem1155', addrs.soul1155)
    const smbc = await ethers.getContractAt('SoulmetaItemBuilder721', addrs.soul721)

    await store.setApprovalForAll1155(smb.address, controller.address)
    await store.setOperator(controller.address, true)
    await smb.setMinter(controller.address, true)
    await smbc.setMinterBatch(controller.address, true)
    console.log('V2 Init done.')
}

async function main () {
    // await deploy()
    await getDeployed()
    // await verify()
    await init()

}

main().then(() => process.exit(0)).catch((error) => {
    console.error(error)
    process.exit(1)
})
