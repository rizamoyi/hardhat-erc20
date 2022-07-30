// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;
import {ERC20} from "./ERC20";
import {DepositorCoin} from "./DepositorCoin";

contract StableCoin is ERC20 {
    DepositorCoin public depositorCoin;

    constructor() ERC("Stablecoin", "STC") {}
}
