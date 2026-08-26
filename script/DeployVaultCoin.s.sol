// SPDX-License-Identifier: MIT
pragma solidity 0.8.24;

import {Script} from "forge-std/Script.sol";
import {VaultCoin} from "../src/VaultCoin.sol";

contract DeployVaultCoin is Script {
    function run() external returns (VaultCoin token) {
        uint256 privateKey = vm.envUint("PRIVATE_KEY");
        address initialOwner = vm.envAddress("INITIAL_OWNER");
        address initialRecipient = vm.envAddress("INITIAL_RECIPIENT");

        vm.startBroadcast(privateKey);
        token = new VaultCoin(initialOwner, initialRecipient);
        vm.stopBroadcast();
    }
}
