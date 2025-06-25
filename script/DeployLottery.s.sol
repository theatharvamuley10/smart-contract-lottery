// SPDX-License-Identifier: MIT
pragma solidity 0.8.30;

import {Script} from "forge-std/Script.sol";
import {Lottery} from "src/Lottery.sol";

contract DeployLottery is Script {
    function run() external {}

    function deployContract() returns (Lottery, HelperConfig) {}
}
