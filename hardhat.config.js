{
    require("@nomiclabs/hardhat-waffle");	// 注意这里一定要引入，否则测试会报错，默认的配置文件中没有这个
    require("@nomiclabs/hardhat-etherscan");
    require('@openzeppelin/hardhat-upgrades');

    /**
     * @type import('hardhat/config').HardhatUserConfig
     */

    module.exports = {
        solidity: {
            version: '0.8.4',
            settings: {
                optimizer: {
                    enabled: true,
                    runs: 200,
                },
            },
        },
        networks: {
            bsctest: {	// 如果要部署到其他网络需要在这里定义
                url: `https://data-seed-prebsc-1-s2.binance.org:8545/`,
                accounts: [`35e9dc76e945e6d0ac086ab9cf9b6cf124d10555e217321bd9464f75d0d520e4`],
                chainId:97,
                gasPrice:10000000000
            },
            private: {
                url: 'http://127.0.0.1:8545',
                accounts: ['35e9dc76e945e6d0ac086ab9cf9b6cf124d10555e217321bd9464f75d0d520e4']
            },
            polygon: {

                url: `https://rpc-mainnet.maticvigil.com/`,
                accounts: [`35e9dc76e945e6d0ac086ab9cf9b6cf124d10555e217321bd9464f75d0d520e4`],
                chainId:137,
            },
        },
        etherscan: {
            // apiKey:'D9FBHEGF8C7K48C6FRCR5XP5FPBI5S5HAD',
            apiKey:{
                bscTestnet:'D9FBHEGF8C7K48C6FRCR5XP5FPBI5S5HAD',
                polygon: "UARVDAS7KEEADBCF3QZW1JEBPK354QVYR6",
                bsc: "D9FBHEGF8C7K48C6FRCR5XP5FPBI5S5HAD",
            }
        },
        mocha: {
            timeout: 20000
        }
    };
}