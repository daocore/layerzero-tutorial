// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./PPXLand.sol";

contract PPXLandMint is PPXLand {
    constructor(address _endpoint, uint256[] memory ids) PPXLand(_endpoint) {
        totalSupply = ids.length;
        for (uint256 i = 0; i < totalSupply; ) {
            _mint(msg.sender, ids[i]);
            unchecked {
                ++i;
            }
        }
    }

    function mint(address to, uint256[] memory ids) external lock {
        uint256 len = ids.length;
        unchecked {
            totalSupply += len;
            for (uint256 i = 0; i < len; ) {
                uint256 id = ids[i];
                _mint(to, id);
                ++i;
            }
        }
    }
}
