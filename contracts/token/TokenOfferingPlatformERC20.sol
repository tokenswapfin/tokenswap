// SPDX-License-Identifier: MIT
pragma solidity ^0.7.0;

import "./ERC20.sol";

contract TokenOfferingPlatformERC20 is ERC20 {
    address private _owner;

    constructor(
        string memory name,
        string memory symbol,
        uint256 totalSupply
    ) public ERC20(name, symbol, 18) {
        _mint(_msgSender(), totalSupply);
    }
}
