// SPDX-License-Identifier: MIT
pragma solidity 0.8.24;

import {Script} from "forge-std/Script.sol";
import {VaultCoin} from "../src/VaultCoin.sol";

contract DeployVaultCoin is Script {
    function run() external returns (VaultCoin token) {
        vm.startBroadcast();
        token = new VaultCoin();
        vm.stopBroadcast();
    }
}
