module.exports = {
    //The value of is the network that mint nft
    landMintNetwork: {
        mainnet: "polygon",
        testnet: "matictest"
    },
    network: {
        "matictest": {
            chainId: 10109,
            endpoint: "0xf69186dfBa60DdB133E91E9A4B5673624293d8F8",
            blockscan: "https://mumbai.polygonscan.com"
        },
        "avaxtest": {
            chainId: 10106,
            endpoint: "0x93f54D755A063cE7bB9e6Ac47Eccc8e33411d706",
            blockscan: "https://testnet.snowtrace.io"
        },
        "ftmtest": {
            chainId: 10112,
            endpoint: "0x7dcAD72640F835B0FA36EFD3D6d3ec902C7E5acf",
            blockscan: "https://testnet.ftmscan.com"
        },
        "bsctest": {
            chainId: 10102,
            endpoint: "0x6Fcb97553D41516Cb228ac03FdC8B9a0a9df04A1",
            blockscan: "https://testnet.bscscan.com"
        },
        "hardhat": {
            chainId: 10103,
            endpoint: "0x6Fcb97553D41516Cb228ac03FdC8B9a0a9df04A1"
        },

        "polygon": {
            chainId: 109,
            endpoint: "0x3c2269811836af69497E5F486A85D7316753cf62",
            blockscan: "https://polygonscan.com"
        },
        "ftm": {
            chainId: 112,
            endpoint: "0xb6319cC6c8c27A8F5dAF0dD3DF91EA35C4720dd7",
            blockscan: "https://ftmscan.com"
        },
        "avax": {
            chainId: 106,
            endpoint: "0x3c2269811836af69497E5F486A85D7316753cf62",
            blockscan: "https://snowtrace.io"
        }
    }
}