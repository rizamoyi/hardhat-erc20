// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;
import {ERC20} from "./ERC20";

contract DepositorCoin is ERC20 {
    address public owner;

    constructor() ERC("DepositorCoin", "DPC") {
        owner = msg.sender;
    }
}
