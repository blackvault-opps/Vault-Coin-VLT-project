// SPDX-License-Identifier: MIT
pragma solidity 0.8.24;

import {ERC1967Proxy} from "@openzeppelin/contracts/proxy/ERC1967/ERC1967Proxy.sol";
import {VaultCoin} from "../src/VaultCoin.sol";
import {DeployVaultCoin} from "./DeployVaultCoin.s.sol";
import {SepoliaChecks} from "./SepoliaPreflight.s.sol";

/// @notice Sepolia-only deployment entry point. Omit --broadcast for simulation.
contract DeployVaultCoinSepolia is DeployVaultCoin {
    function run()
        external
        override
        returns (VaultCoin token, VaultCoin implementation, ERC1967Proxy proxy)
    {
        SepoliaChecks.verify(OWNER_AND_TREASURY);
        return _deploy();
    }
}
