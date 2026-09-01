// SPDX-License-Identifier: MIT
pragma solidity 0.8.24;

import {Script} from "forge-std/Script.sol";
import {ERC1967Proxy} from "@openzeppelin/contracts/proxy/ERC1967/ERC1967Proxy.sol";
import {VaultCoin} from "../src/VaultCoin.sol";

contract DeployVaultCoin is Script {
    address public constant OWNER_AND_TREASURY = 0xc1cC3138699e07B6d7b990DBa8fAE30b332a1eA6;
    uint16 public constant INITIAL_ADMIN_BURN_FEE_BPS = 100;

    function run() external returns (VaultCoin token, VaultCoin implementation, ERC1967Proxy proxy) {
        vm.startBroadcast();
        implementation = new VaultCoin();
        bytes memory initializer =
            abi.encodeCall(VaultCoin.initialize, (OWNER_AND_TREASURY, OWNER_AND_TREASURY, INITIAL_ADMIN_BURN_FEE_BPS));
        proxy = new ERC1967Proxy(address(implementation), initializer);
        vm.stopBroadcast();

        token = VaultCoin(payable(address(proxy)));
        require(token.owner() == OWNER_AND_TREASURY, "unexpected owner");
        // forge-lint: disable-next-line(incorrect-strict-equality)
        require(token.balanceOf(OWNER_AND_TREASURY) == token.INITIAL_SUPPLY(), "unexpected initial balance");
        require(token.totalSupply() == token.INITIAL_SUPPLY(), "unexpected total supply");
        require(token.cumulativeMinted() == token.INITIAL_SUPPLY(), "unexpected cumulative mint");
    }
}
