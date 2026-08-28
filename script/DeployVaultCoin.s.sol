// SPDX-License-Identifier: MIT
pragma solidity 0.8.24;

import {Script} from "forge-std/Script.sol";
import {VaultCoin} from "../src/VaultCoin.sol";

contract DeployVaultCoin is Script {
    error UnexpectedChain(uint256 actual, uint256 expected);

    function run() external returns (VaultCoin token) {
        uint256 privateKey = vm.envUint("PRIVATE_KEY");
        uint256 expectedChainId = vm.envUint("EXPECTED_CHAIN_ID");
        address initialOwner = vm.envAddress("INITIAL_OWNER");
        address initialTreasury = vm.envAddress("INITIAL_TREASURY");

        if (block.chainid != expectedChainId) {
            revert UnexpectedChain(block.chainid, expectedChainId);
        }

        vm.startBroadcast(privateKey);
        token = new VaultCoin(initialOwner, initialTreasury);
        vm.stopBroadcast();
    }
}
