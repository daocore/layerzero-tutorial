手把手教你基于LayerZero开发一个跨链NFT(一)

## 一、什么是 LayerZero

[LayerZero](https://layerzero.network/) 是一种全链互操作性协议，专为跨链传递轻量级消息而设计，它提供了可靠和有保障的去信任的消息传递。本质上是利用了轻节点的技术原理，将中间链的置信环节一分为二，从而以更低的费用换取更好的安全性。它既大幅减少开发者的学习成本和运营成本，又能减少用户端的使用费率，使得建立在 LayerZero 上的应用拥有安全成本优势。因此本系列教程旨在巩固自己的开发技能和帮助从未接触LayerZero跨链开发的开发者学习和交流，如有表述不清楚或错误的地方，还请斧正。本系列完整代码可在[layerzero-tutorial](https://github.com/daocore/layerzero-tutorial)中查看和克隆，该仓库克隆并下载完依赖后，可直接运行package中的cross脚本命令，无需再次部署。

更多LayerZero相关信息请查看以下链接，本文不对LayerZero做更多介绍，只是讲解如何基于LayerZero实现数据的跨链。
    
  * [LayerZero- An Omnichain Interoperability Protocol](https://medium.com/layerzero-official/layerzero-an-omnichain-interoperability-protocol-b43d2ae975b6)
  * [Layerzero Labs：普及全链资产，抢占多链生态核心](https://www.ccvalue.cn/article/1404922.html)
  * [LayerZero — A Deep Dive](https://blog.li.fi/layerzero-a-deep-dive-6a46555967f5)
  * [Whitepaper](https://layerzero.network/pdf/LayerZero_Whitepaper_Release.pdf)
  * [LayerZero Docs](https://layerzero.gitbook.io/docs/)


## 二、配置[Hardhat](https://learnblockchain.cn/docs/hardhat/getting-started/)
当前教程基于Hardhat项目，因此在开始之前需要配置好Hardhat，做一些开发前的准备。
### 1. 初始化一个hardhat项目
### 2. 配置[hardhat-deploy](https://learnblockchain.cn/docs/hardhat/plugins/hardhat-deploy.html)插件
### 3. 新增以下[scripts](https://github.com/daocore/layerzero-tutorial/blob/main/package.json#L4)命令到package.json中
```shell
"chain": "hardhat node",
"test": "hardhat test",
"compile": "hardhat compile",
"deploy": "hardhat deploy",
"postdeploy": "hardhat run scripts/publish.ts"
```
### 4. 在scripts文件中新增一个[publish.ts](https://github.com/daocore/layerzero-tutorial/blob/main/scripts/publish.ts)脚本文件，用于处理部署后的各个网络数据等。
```ts
const fs = require("fs");
const chalk = require("chalk");

const deploymentsDir = "./deployments";

function publishContract(contractName: any, networkName: any) {
  let data = fs
    .readFileSync(`${deploymentsDir}/${networkName}/${contractName}.json`)
    .toString();
  let chainId = fs
    .readFileSync(`${deploymentsDir}/${networkName}/.chainId`)
    .toString();
  let contract = JSON.parse(data);
  return ({
    "contractName": contractName,
    "chainId": chainId,
    "address": contract.address,
    "netName": networkName
  })
}

async function main() {
  const directories = fs.readdirSync(deploymentsDir);
  const abis: any = [];
  directories.forEach(function (directory: any) {
    const files = fs.readdirSync(`${deploymentsDir}/${directory}`);
    files.forEach(function (file: any) {
      if (file.indexOf(".json") >= 0) {
        const contractName = file.replace(".json", "");
        const item = publishContract(contractName, directory);
        abis.push(item);
      }
    });
  });
  fs.writeFileSync(
    `deploy-contracts.json`,
    `${JSON.stringify(abis, null, 4)}`
  );
  console.log("✅ The file is generated successfully.");
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });

```

### 5. 在根目录中新增一个文件名为.env的文件，内容为以下代码
```
PRIVATE_KEY=0xabc123abc123abc123abc123abc123abc123abc123abc123abc123abc123abc1
```

### 6. 当代码准备完毕或clone后，运行各个scripts中的命令。例如执行以下命令后：
```
yarn deploy --network ftmtest
```

控制台会输出部署信息，并且在fantom的测试网上会部署一个Greeter合约，此时会在根目录新增一个 deploy-contracts.json 文件，内容大致如下：
```json
[
    {
        "contractName": "Greeter",
        "chainId": "4002",
        "address": "0x818e7F65Aa8295Ca49C6bD22FB9B4a86cEb180Ba",
        "netName": "ftmtest"
    },
    {
        "contractName": "Greeter",
        "chainId": "80001",
        "address": "0x6EB9889cAe997fE5F23207E3409672D860256B8E",
        "netName": "matictest"
    }
]
```

该文件是通过deploy命令执行后，自动执行publish.ts脚本来生成的。内容主要为合约部署的情况，哪条链部署了哪个合约，他的合约地址是什么等信息，这些信息用于后续功能的使用。

> 此步骤如果出现 deployments文件夹 找不到等报错，可以手动新增一个。

以上步骤完整代码： [layerzero-tutorial V1.0.0](https://github.com/daocore/layerzero-tutorial/releases/tag/v1.0.0)

## 三、部署ERC721合约以及发行NFT
### 1. 安装依赖
```
yarn add @openzeppelin/contracts -D
```

### 2. 重命名Greeter.sol文件为PPXLand.sol，并清空文件内容
> 我们使用ERC721合约，发行一系列的NFT，暂且将这些NFT称作皮皮虾大陆，所以名字就叫做PPXLand了。

### 3. 在PPXLand.sol文件中引入openzeppelin的ERC721合约以及编写发行逻辑
```sol
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";

contract PPXLand is ERC721 {
    uint256 private _lock = 1;
    uint256 private _id;

    constructor() ERC721("PPXLand", "PPXL") {
        _mint(msg.sender, 0);
        _id++;
    }

    modifier lock() {
        require(_lock == 1, "LOCKED");
        _lock = 2;
        _;
        _lock = 1;
    }

    function mint(address to, uint256 id) external lock {
        _mint(to, id);
        _id++;
    }

    function totalSupply() external view returns (uint256) {
        return _id;
    }
}
```

### 4. 修改test文件夹中的 index.ts 文件内容为以下内容,并执行 **yarn test** 命令，控制台会输出测试结果。
```ts
import { SignerWithAddress } from "@nomiclabs/hardhat-ethers/signers";
import { expect } from "chai";
import { Contract } from "ethers";
import { ethers } from "hardhat";

describe("PPXLand", function () {
  let LandContract: Contract, owner: SignerWithAddress, owner2: SignerWithAddress;

  it("Deploy Contract", async function () {
    const signers = await ethers.getSigners();
    owner = signers[0];
    owner2 = signers[1];

    const Land = await ethers.getContractFactory("PPXLand");
    LandContract = await Land.deploy();
    await LandContract.deployed();
    expect(await LandContract.ownerOf(0)).to.equal(owner.address);
  });

  it("Mint NFT", async function () {
    await LandContract.mint(owner.address, 1);
    expect(await LandContract.ownerOf(1)).to.equal(owner.address);

    await LandContract.connect(owner2).mint(owner2.address, 2);
    expect(await LandContract.ownerOf(2)).to.equal(owner2.address);

    expect(await LandContract.totalSupply()).to.equal(3);
  });
});

```

### 5. 修改deploy文件夹中的 00_deploy_my_contract.ts 文件内容为以下内容
```ts
module.exports = async ({ getNamedAccounts, deployments }: { getNamedAccounts: any, deployments: any }) => {
  const { deploy } = deployments;
  const { deployer } = await getNamedAccounts();

  const ppxland = await deploy("PPXLand", {
    from: deployer,
    args: [],
    log: true,
  });

  console.log("PPXLand deployed to:", ppxland.address);
};

module.exports.tags = ["PPXLand"];
```

### 6. 清除之前的部署信息
删除deployments文件夹下面的所有的部署记录数据，使其成为一个空文件夹

### 7. 部署PPXLand合约
```
yarn deploy --network ftmtest
```

运行该命令后，便会部署合约到fantom测试网，并且更新 deploy-contracts.json 文件内容。
```json
[
    {
        "contractName": "PPXLand",
        "chainId": "4002",
        "address": "0x4559E9409907198BF12F8061e901759E42A3460b",
        "netName": "ftmtest"
    }
]
```

### 8. 新增以下命令到package.json中的scripts中
```
"cross": "hardhat cross"
```

### 9. 新建一个名为cross的文件夹，并新增一个index.ts文件，添加以下内容到文件中
```ts
const deployContractsData = require("../deploy-contracts.json");
import { task } from "hardhat/config";

task("cross", "NFT Cross Chain Task")
    .addOptionalParam("id", "NFT ID example 1")
    .addOptionalParam("type", "action type")
    .addOptionalParam("address", "user address")
    .setAction(async (taskArgs, { network, ethers }: any) => {
        const signers = await ethers.getSigners();
        const deployer = signers[0];
        const deployContracts = {};
        const deployContractData = deployContractsData.filter(item => item.netName === network.name);

        for (let i = 0; i < deployContractData.length; i++) {
            const item = deployContractData[i];
            const factory = await ethers.getContractFactory(item.contractName);
            const c = await factory.attach(item.address);
            deployContracts[item.contractName] = {
                contract: c,
                ...item
            };
        };

        const contract = deployContracts["PPXLand"];
        const LandContract = contract?.contract;

        let id = taskArgs?.id, res;

        switch (taskArgs.type) {
            case "mint":
                res = await LandContract.mint(taskArgs.address || deployer.address, id);
                break;
            default:
                console.log(`❌ type: ${taskArgs.type}, type error`);
                return
        }
        res?.hash && console.log(`${res?.hash}`)
        console.log(`✅ ${taskArgs.type} success`);
    });
```

### 10. 发行NFT
执行以下命令后，可以给相应地址发行该ID的NFT(没有address参数和值的时候，则会发行到调用合约的地址).
```
yarn cross --network ftmtest --type mint --id 3
```
or
```
yarn cross --network ftmtest --type mint --id 3 --address 0x4559E9409907198BF12F8061e901759E42A3460b
```

至此我们就有了一个可以自己发行NFT的合约了。

以上步骤完整代码： [layerzero-tutorial V2.0.0](https://github.com/daocore/layerzero-tutorial/releases/tag/v2.0.0)

## 四、NFT跨链
### 1. 安装依赖
```
yarn add @layerzerolabs/scan-client @layerzerolabs/solidity-examples@https://gitclone.com/github.com/LayerZero-Labs/solidity-examples.git -D
```

### 2. 更新PPXLand.sol的内容为以下代码
```sol
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

interface ILayerZeroEndpoint {
    function send(
        uint16 _dstChainId,
        bytes calldata _destination,
        bytes calldata _payload,
        address payable _refundAddress,
        address _zroPaymentAddress,
        bytes calldata _adapterParams
    ) external payable;

    function estimateFees(
        uint16 _dstChainId,
        address _userApplication,
        bytes calldata _payload,
        bool _payInZRO,
        bytes calldata _adapterParam
    ) external view returns (uint256 nativeFee, uint256 zroFee);
}

contract PPXLand is ERC721, Ownable {
    uint256 private _lock = 1;
    uint256 internal _id;
    ILayerZeroEndpoint public immutable lzEndpoint;

    mapping(uint16 => bytes) public trustedRemoteLookup;
    event SetTrustedRemote(uint16 _remoteChainId, bytes _path);

    struct Assets {
        address owner;
        uint256[] ids;
    }
    event CrossEvent(address from, uint16 chainId, uint256[] ids);

    constructor(address _endpoint) ERC721("PPXLand", "PPXL") {
        lzEndpoint = ILayerZeroEndpoint(_endpoint);
    }

    modifier lock() {
        require(_lock == 1, "LOCKED");
        _lock = 2;
        _;
        _lock = 1;
    }

    function totalSupply() external view returns (uint256) {
        return _id;
    }

    function crossChain(
        address _receiver,
        uint16 _dstChainId,
        uint256[] calldata _ids,
        bytes memory _adapterParams
    ) external payable lock {
        uint256 len = _ids.length;

        unchecked {
            for (uint256 i = 0; i < len; ) {
                uint256 id = _ids[i];
                require(
                    ownerOf(id) == msg.sender,
                    "not token owner nor approved"
                );

                _transfer(msg.sender, address(this), id);
                ++i;
            }
        }
        bytes memory _payload = abi.encode(Assets(_receiver, _ids));

        lzEndpoint.send{value: msg.value}(
            _dstChainId,
            trustedRemoteLookup[_dstChainId],
            _payload,
            payable(msg.sender),
            address(this),
            _adapterParams
        );
        emit CrossEvent(msg.sender, _dstChainId, _ids);
    }

    function lzReceive(
        uint16 _srcChainId,
        bytes calldata _srcAddress,
        uint64,
        bytes calldata _payload
    ) public virtual {
        require(
            _msgSender() == address(lzEndpoint),
            "LzApp: invalid endpoint caller"
        );

        bytes memory trustedRemote = trustedRemoteLookup[_srcChainId];
        require(
            _srcAddress.length == trustedRemote.length &&
                trustedRemote.length > 0 &&
                keccak256(_srcAddress) == keccak256(trustedRemote),
            "LzApp: invalid source sending contract"
        );

        Assets memory assets = abi.decode(_payload, (Assets));

        uint256[] memory ids = assets.ids;
        uint256 len = ids.length;
        uint256 total = _id;
        unchecked {
            for (uint256 i = 0; i < len; ) {
                uint256 id = ids[i];
                if (_exists(id)) {
                    require(
                        ownerOf(id) == address(this),
                        "The current ID is abnormal"
                    );
                    _transfer(address(this), assets.owner, id);
                } else {
                    _mint(assets.owner, id);
                    ++total;
                }
                ++i;
            }
            _id = total;
        }
        emit CrossEvent(address(this), _srcChainId, ids);
    }

    function estimateFees(
        uint16 _dstChainId,
        address _userApplication,
        Assets memory _assets,
        bytes memory _adapterParams
    ) external view returns (uint256 fee) {
        bytes memory _payload = abi.encode(_assets);
        (fee, ) = lzEndpoint.estimateFees(
            _dstChainId,
            _userApplication,
            _payload,
            false,
            _adapterParams
        );
    }

    function setTrustedRemote(uint16 _srcChainId, bytes calldata _path)
        external
        onlyOwner
    {
        trustedRemoteLookup[_srcChainId] = _path;
        emit SetTrustedRemote(_srcChainId, _path);
    }
}
```

上述代码便是本次实现跨链的代码。在LayerZero中，消息是由**LayerZero Endpoint**发送和接收的，通过[LayerZeroEndpoint](https://layerzero.gitbook.io/docs/faq/layerzero-endpoint)来处理消息传输、验证、接收。本教程(一)只是简单实现了发送和接收，接下来将对代码进行一个简单的解析：

* lzEndpoint: lzEndpoint的值是当前链的endpoint，更多endpoint可查看[Mainnet Endpoint](https://layerzero.gitbook.io/docs/technical-reference/mainnet/supported-chain-ids)   [Testnet Endpoint](https://layerzero.gitbook.io/docs/technical-reference/testnet/testnet-addresses)，该地址用于合约调用其内部的发送和接收消息的函数来实现消息的传输。

* trustedRemoteLookup: 即为可信任的地址集。lzEndpoint在接收到消息后，会调用当前ERC721合约的lzReceive函数。而在开发的过程中，我们一般是不希望其他合约地址向当前合约发送消息的，所以我们需要配置一个所谓的白名单列表来，只有在这个列表里面的地址，才能给我们传消息，以及才会对该消息执行相应的功能。

* setTrustedRemote: 设置可信任的地址，键是链ID，该ID可以在[Mainnet Endpoint](https://layerzero.gitbook.io/docs/technical-reference/mainnet/supported-chain-ids)   [Testnet Endpoint](https://layerzero.gitbook.io/docs/technical-reference/testnet/testnet-addresses)查询到。

* estimateFees: 计算跨到目标链需要花的GAS，参数分别为
    * _dstChainId: 目标链ID
    * _userApplication: 目标链部署的当前ERC721合约地址
    * _assets: 当前跨链的数据，是Assets结构
    * _adapterParams: 跨链的高级参数，该[参数](https://layerzero.gitbook.io/docs/evm-guides/advanced/relayer-adapter-parameters)可以指定gas，默认是200000。前端该值的获取方式如下：
        ```js
        let gas = 500000; // 预估的需要花费的gas
        let adapterParams = ethers.utils.solidityPack(
            ['uint16','uint256'],
            [1, gas]
        )
        ```

* crossChain: 该函数便是用于跨链的函数。主要是对数据即NFT的接收者以及NFT ID列表进行编码后，通过Endpoint合约的send函数来发送消息，当前函数的参数分别是
    * _receiver: 当前跨链过去的NFT的接收者
    * _dstChainId: 目标链ID
    * _ids: 需要跨链的NFT的ID，是一个数组
    * _adapterParams: 同上

    更多发送消息的文档可查看官方文档[how-to-send-a-message](https://layerzero.gitbook.io/docs/evm-guides/master/how-to-send-a-message)

* lzReceive: 在接收端需要实现的接收函数，该函数将之前原链上经过编码后的数据进行解码，然后做相应的操作。原则上来讲只能由Endpoint合约调用，其次函数的接收也只是限于受信任合约的地址调用。该函数的参数固定不变，由Endpoint合约传输过来，参数分别是
    * _srcChainId: 原链ID，即哪条链传递过来的消息
    * _srcAddress: 原链合约地址，即哪个合约发送过来的消息
    * _nonce: 当前消息的nonce什么，当前合约暂时未设计，所以暂时忽略不计
    * _payload: 传递过来的数据，已签名的有效负载是已编码的要发送的UA字节

    更多接收消息的文档请查看官方文档[receive-messages](https://layerzero.gitbook.io/docs/evm-guides/master/receive-messages)


### 3. 新增一个PPXLandMint.sol合约文件，添加内容如下：
```sol
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./PPXLand.sol";

contract PPXLandMint is PPXLand {
    constructor(address _endpoint, uint256[] memory ids) PPXLand(_endpoint) {
        _id = ids.length;
        for (uint256 i = 0; i < _id; ) {
            _mint(msg.sender, ids[i]);
            unchecked {
                ++i;
            }
        }
    }

    function mint(address to, uint256[] memory ids) external lock {
        uint256 len = ids.length;
        unchecked {
            _id += len;
            for (uint256 i = 0; i < len; ) {
                uint256 id = ids[i];
                _mint(to, id);
                ++i;
            }
        }
    }
}
```

该合约在开发者指定的可以进行Mint NFT的链上部署，这个链可以在[across/config.ts](https://github.com/daocore/layerzero-tutorial/blob/main/cross/config.ts#L3)中配置。之所以将Mint函数单列出来，主要在于多个链的Mint可能会出现相同ID的NFT，所以跨链会有一些问题。事实上可以通过区分各个链来Mint不同范围的ID来进行避免，但是当前教程只是在一个链上Mint，其他链的对应合约的其他功能照旧。

### 4. 新增一个LZEndpointMock.sol文件，内容为以下代码：
```
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@layerzerolabs/solidity-examples/contracts/mocks/LZEndpointMock.sol";

contract LocalLZEndpoint is LZEndpointMock {
    constructor(uint16 _chainId) LZEndpointMock(_chainId) {}
}
```

### 5. 更新test文件夹中的index.ts测试文件为以下代码，并运行**yarn test**，确保合约跨链测试通过
```ts
import { SignerWithAddress } from "@nomiclabs/hardhat-ethers/signers";
import { expect } from "chai";
import { Contract } from "ethers";
import { ethers } from "hardhat";

describe("PPXLand", function () {
  let LandContract: Contract, LandMintContract: Contract, owner: SignerWithAddress, owner2: SignerWithAddress, lzEndpointMock, chainId = 123;
  beforeEach(async function () {
    const signers = await ethers.getSigners();
    owner = signers[0];
    owner2 = signers[1];

    const LayerZeroEndpointMock = await ethers.getContractFactory("LocalLZEndpoint")
    lzEndpointMock = await LayerZeroEndpointMock.deploy(chainId)

    const PPXLand = await ethers.getContractFactory("PPXLand")
    const PPXLandMint = await ethers.getContractFactory("PPXLandMint")
    LandContract = await PPXLand.deploy(lzEndpointMock.address)
    LandMintContract = await PPXLandMint.deploy(lzEndpointMock.address, [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19, 20, 21, 22, 23])

    lzEndpointMock.setDestLzEndpoint(LandContract.address, lzEndpointMock.address)
    lzEndpointMock.setDestLzEndpoint(LandMintContract.address, lzEndpointMock.address)

    LandContract.setTrustedRemote(
      chainId,
      ethers.utils.solidityPack(["address", "address"], [LandMintContract.address, LandContract.address])
    )
    LandMintContract.setTrustedRemote(
      chainId,
      ethers.utils.solidityPack(["address", "address"], [LandContract.address, LandMintContract.address])
    )
  })

  it("Mint NFT", async function () {
    expect(await LandMintContract.ownerOf(1)).to.equal(owner.address);

    await LandMintContract.connect(owner2).mint(owner2.address, [24, 25, 26, 27]);
    expect(await LandMintContract.ownerOf(27)).to.equal(owner2.address);

    expect(await LandMintContract.totalSupply()).to.equal(28);
  });

  it("CrossChain", async function () {
    let ids = [0, 1, 2];
    const [adapterParams1, fees1] = await crossChainData(owner, LandContract, LandMintContract, chainId, true, ids);
    await LandMintContract.crossChain(owner.address, chainId, ids, adapterParams1, {
      value: fees1
    });

    const [adapterParams2, fees2] = await crossChainData(owner, LandContract, LandMintContract, chainId, false, ids);
    await LandContract.crossChain(owner.address, chainId, ids, adapterParams2, {
      value: fees2
    });
  });
});

async function crossChainData(owner: SignerWithAddress, LandContract: Contract, LandMintContract: Contract, chainId: number, isMintContract: boolean, ids: number[]) {
  let adapterParams = ethers.utils.solidityPack(
    ['uint16', 'uint256'],
    [1, 200000 + ids.length * 50000]
  )
  let contract = isMintContract ? LandContract : LandMintContract;
  const fees = await contract.estimateFees(
    chainId,
    contract.address,
    {
      owner: owner.address,
      ids
    },
    adapterParams);

  return [adapterParams, fees] as const
}
```

如果报以下错误（没出现最好不过了），可以进入到node_modules的@layerzerolabs/solidity-examples/contracts/mocks/LZEndpointMock.sol 文件中，在estimateFees函数上添加一个 override 即可。
```
TypeError: Overriding function is missing "override" specifier.
   --> @layerzerolabs/solidity-examples/contracts/mocks/LZEndpointMock.sol:203:5:
    |
203 |     function estimateFees(uint16 _dstCh ... rns (uint nativeFee, uint zroFee) {
    |     ^ (Relevant source part starts here and spans across multiple lines).
Note: Overridden function is here:
  --> @layerzerolabs/solidity-examples/contracts/interfaces/ILayerZeroEndpoint.sol:41:5:
   |
41 |     function estimateFees(uint16 _dstCh ... urns (uint nativeFee, uint zroFee);
   |     ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^


Error HH600: Compilation failed
```

### 6. 在cross文件夹中新增config.ts文件，文件内容为：
```ts
module.exports = {
    //The value of is the network that mint nft
    landMintNetwork: {
        mainnet: "polygon",
        testnet: "ftmtest"
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
```
此处的landMintNetwork的mainnet和testnet的值可以自行指定，即开发者欲Mint NFT的网络。取值为[hardhat配置文件](https://github.com/daocore/layerzero-tutorial/blob/main/hardhat.config.ts#L32)中各个网络的名称。

### 7. 更新cross文件夹中的index.ts文件为以下内容
```ts
const deployContractsData = require("../deploy-contracts.json");
const config = require("./config.ts");
import { task } from "hardhat/config";

task("cross", "NFT Cross Chain Task")
    .addOptionalParam("to", "To Network")
    .addOptionalParam("ids", "Cross Chain ID example 1 or 1,2,3")
    .addOptionalParam("type", "action type")
    .addOptionalParam("address", "user address")
    .setAction(async (taskArgs, { network, ethers }: any) => {
        const { BigNumber } = ethers;
        const signers = await ethers.getSigners();
        const deployer = signers[0];
        const deployContracts = {};
        const deployContractData = deployContractsData.filter(item => item.netName === network.name);

        const networks = config.network;
        const landMintNetwork = config.landMintNetwork[network.name?.includes("test") ? "testnet" : "mainnet"];
        const contractName = (net) => net === landMintNetwork ? "PPXLandMint" : "PPXLand";
        const toData = deployContractsData.filter(item => item.netName === taskArgs.to && item?.contractName === contractName(taskArgs.to));
        const URLS = {
            testnet: 'https://api-testnet.layerzero-scan.com',
            mainnet: 'https://api-mainnet.layerzero-scan.com',
            sandbox: 'https://api-sandbox.layerzero-scan.com',
        };

        for (let i = 0; i < deployContractData.length; i++) {
            const item = deployContractData[i];
            const factory = await ethers.getContractFactory(item.contractName);
            const c = await factory.attach(item.address);
            deployContracts[item.contractName] = {
                contract: c,
                ...item
            };
        };

        const dstCrossChainData = networks[taskArgs.to];
        const srcCrossChainData = networks[network.name];

        if (!dstCrossChainData) {
            console.log("Cross Chain Error");
            return
        }

        const contract = deployContracts[contractName(network?.name)];
        const LandContract = contract?.contract;
        let dstChainId = BigNumber.from(dstCrossChainData.chainId);
        const trustedRemote = await LandContract.trustedRemoteLookup(dstChainId);
        const dstTrustedRemote = ethers.utils.solidityPack(
            ['address', 'address'],
            [toData[0].address, contract.address]
        )
        const isSetTrustedRemote = dstTrustedRemote?.toLowerCase() === trustedRemote?.toLowerCase();
        const output = {
            account: `${srcCrossChainData.blockscan}/address/${deployer.address}`,
            fromChain: {
                chainId: srcCrossChainData.chainId,
                endpoint: `${srcCrossChainData.blockscan}/address/${srcCrossChainData.endpoint}`,
                ppxland: `${srcCrossChainData.blockscan}/address/${LandContract.address}`,
                network: network.name
            },
            toChain: {
                chainId: dstCrossChainData.chainId,
                endpoint: `${dstCrossChainData.blockscan}/address/${dstCrossChainData.endpoint}`,
                ppxland: `${dstCrossChainData.blockscan}/address/${toData[0].address}`,
                network: toData[0].netName,
                trustedRemote,
            },
            ids: taskArgs.ids,
        }
        console.log(output);

        let ids = taskArgs?.ids?.split(",") || [], res, asstes;
        const receiver = taskArgs.address || deployer.address;

        switch (taskArgs.type) {
            case "mint":
                res = await LandContract.mint(receiver, ids);
                break;
            case "trust":
                if (!isSetTrustedRemote) {
                    await LandContract.setTrustedRemote(dstChainId, dstTrustedRemote);
                } else {
                    console.log("seted")
                    return
                }
                break;
            case "cross":
                asstes = {
                    owner: receiver,
                    ids
                }
                let adapterParams = ethers.utils.solidityPack(
                    ['uint16', 'uint256'],
                    [1, 200000 + ids.length * 50000]
                )
                const fees = await LandContract.estimateFees(
                    dstChainId,
                    toData[0].address,
                    asstes,
                    adapterParams);
                const fee = ethers.utils.formatEther(fees.toString());

                if (Number(ethers.utils.formatEther(fees.toString())) > 0.01) {
                    console.log("pause cross chain", fee)
                    return
                }

                res = await LandContract.crossChain(receiver, dstChainId, ids, adapterParams, {
                    value: fees
                });
                break;

            default:
                console.log(`❌ type: ${taskArgs.type}, type error`);
                return
        }
        if (res && taskArgs.type === "cross") {
            console.log(`${dstCrossChainData.chainId > 1000 ? URLS["testnet"] : URLS["mainnet"]}/tx/${res.hash}`)
        } else {
            res && console.log(`${srcCrossChainData.blockscan}/tx/${res.hash}`)
        }
        console.log(`✅ ${taskArgs.type} success`);
    });
```

### 8. 更新deploy文件夹中的部署文件为以下内容：
```ts
const config = require("../cross/config.ts");

module.exports = async ({ getNamedAccounts, deployments }: { getNamedAccounts: any, deployments: any }) => {
  const { deploy } = deployments;
  const { deployer } = await getNamedAccounts();

  const network = config.network;

  let net = "hardhat";
  for (let i = 0; i < process?.argv?.length; i++) {
    const arg = process.argv[i]
    if (arg === "--network") {
      net = process?.argv[i + 1];
    }
  }

  if (net === config.landMintNetwork[net?.includes("test") ? "testnet" : "mainnet"]) {
    const LandMint = await deploy("PPXLandMint", {
      from: deployer,
      args: [network[net].endpoint, [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19, 20, 21, 22, 23]],
      log: true,
    });
    console.log("LandMint deployed to:", LandMint.address, network[net].endpoint);
  } else {
    const Land = await deploy("PPXLand", {
      from: deployer,
      args: [network[net].endpoint],
      log: true,
    });
    console.log("Land deployed to:", Land.address, network[net].endpoint);
  }
};

module.exports.tags = ["PPXLand"];
```

### 9. 部署合约
```
yarn deploy --network ftmtest
yarn deploy --network matictest
```
执行后，将会更新 [deploy-contracts.json](https://github.com/daocore/layerzero-tutorial/blob/main/deploy-contracts.json) 文件中的内容为最新部署数据。

### 10. 设置受信地址，可配置多个链，部署了几个链就可以配置几个
```
yarn cross --network matictest --to ftmtest --type trust
yarn cross --network ftmtest --to matictest --type trust
```

### 11. NFT跨链到目标地址
```
yarn cross --network ftmtest --to matictest --type cross --ids 0,1,2
or
yarn cross --network ftmtest --to matictest --type cross --ids 3,4 --address your_other_address
```

### 12. 等待几分钟后可查看目标链地址是否跨链成功，若跨链成功，则可以将目标链跨过去的NFT跨链回来。
```
yarn cross --network matictest --to ftmtest --type cross --ids 0
```

> 跨链成功的前提是需要在目标链上配置受信任地址，如果没有配置，可能会造成NFT丢失。对于各种跨链事故，LayerZero也有相应的处理方案，下一篇将讲解如何处理各种异常，如支付GAS不足导致接收端函数未执行等问题。

以上步骤完整代码： [layerzero-tutorial V3.0.0](https://github.com/daocore/layerzero-tutorial/releases/tag/v3.0.0)

至此我们由LayerZero实现了一个简单的跨链NFT，官方的[事例代码](https://github.com/LayerZero-Labs/solidity-examples/tree/main/contracts/examples)中，也有相关ERC721如何跨链的例子。如果觉得在下的表述和代码编写能力欠佳，还请阁下海涵。阁下也可前往[LayerZero-Labs/solidity-examples](https://github.com/LayerZero-Labs/solidity-examples)了解更多跨链的信息和用法。