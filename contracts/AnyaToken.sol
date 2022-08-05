// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.9;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract AnyaToken is ERC20 {

    constructor() ERC20("Anya Token", "AT"){
        _mint(msg.sender, 1000000000000000000 * 10 ** decimals());
    }
}