// SPDX-License-Identifier: MIT
pragma solidity 0.8.24;

import {Test} from "forge-std/Test.sol";
import {ERC1967Proxy} from "@openzeppelin/contracts/proxy/ERC1967/ERC1967Proxy.sol";
import {VaultCoin} from "../src/VaultCoin.sol";
import {DeployVaultCoin} from "../script/DeployVaultCoin.s.sol";

contract DeployVaultCoinTest is Test {
    function testDeploymentScriptInitializesProxyForConfirmedSafe() public {
        DeployVaultCoin deployment = new DeployVaultCoin();
        (VaultCoin token, VaultCoin implementation, ERC1967Proxy proxy) = deployment.run();

        address expectedSafe = deployment.OWNER_AND_TREASURY();
        assertEq(address(token), address(proxy));
        assertTrue(address(implementation) != address(proxy));
        assertEq(token.owner(), expectedSafe);
        assertEq(token.feeRecipient(), expectedSafe);
        assertEq(token.balanceOf(expectedSafe), 100_000_000 ether);
        assertEq(token.totalSupply(), 100_000_000 ether);
        assertEq(token.cumulativeMinted(), 100_000_000 ether);
        assertEq(token.adminBurnFeeBps(), 100);
    }

    function testGenericDeploymentScriptRejectsNonLocalChain() public {
        vm.chainId(1);
        DeployVaultCoin deployment = new DeployVaultCoin();

        vm.expectRevert(abi.encodeWithSelector(DeployVaultCoin.InvalidDeploymentChain.selector, 1));
        // forge-lint: disable-next-line(unused-return)
        deployment.run();
    }
}
