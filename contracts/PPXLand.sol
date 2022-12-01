// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@layerzerolabs/solidity-examples/contracts/lzApp/NonblockingLzApp.sol";

contract PPXLand is ERC721, NonblockingLzApp {
    uint256 private _lock = 1;
    uint256 internal _id;

    struct Assets {
        address owner;
        uint256[] ids;
    }
    event CrossEvent(address from, uint16 chainId, uint256[] ids);

    constructor(address _endpoint)
        ERC721("PPXLand", "PPXL")
        NonblockingLzApp(_endpoint)
    {}

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

    function _nonblockingLzReceive(
        uint16 _srcChainId,
        bytes memory,
        uint64,
        bytes memory _payload
    ) internal override {
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
}
