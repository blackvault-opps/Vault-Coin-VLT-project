// SPDX-License-Identifier: MIT
pragma solidity 0.8.24;

import {Test} from "forge-std/Test.sol";
import {ERC1967Proxy} from "@openzeppelin/contracts/proxy/ERC1967/ERC1967Proxy.sol";
import {VaultCoin} from "../src/VaultCoin.sol";
import {DeployVaultCoinSepolia} from "../script/DeployVaultCoinSepolia.s.sol";
import {ISafe, SepoliaChecks, SepoliaPreflight} from "../script/SepoliaPreflight.s.sol";

contract MockSepoliaSafe is ISafe {
    function getOwners() external pure returns (address[] memory owners) {
        owners = new address[](4);
        owners[0] = address(0x1001);
        owners[1] = address(0x1002);
        owners[2] = address(0x1003);
        owners[3] = address(0x1004);
    }

    function getThreshold() external pure returns (uint256) {
        return 3;
    }
}

contract SepoliaPreflightTest is Test {
    uint256 private constant SEPOLIA_CHAIN_ID = 11155111;
    address private constant CONFIRMED_SAFE = 0xc1cC3138699e07B6d7b990DBa8fAE30b332a1eA6;

    function setUp() public {
        vm.chainId(SEPOLIA_CHAIN_ID);
        MockSepoliaSafe safe = new MockSepoliaSafe();
        vm.etch(CONFIRMED_SAFE, address(safe).code);
    }

    function testReadOnlyPreflightAcceptsConfirmedSafe() public {
        SepoliaPreflight preflight = new SepoliaPreflight();
        preflight.run();
    }

    function testReadOnlyPreflightRejectsWrongChain() public {
        vm.chainId(1);
        SepoliaPreflight preflight = new SepoliaPreflight();
        vm.expectRevert(abi.encodeWithSelector(SepoliaChecks.InvalidChain.selector, 1));
        preflight.run();
    }

    function testReadOnlyPreflightRejectsMissingSafeCode() public {
        vm.etch(CONFIRMED_SAFE, hex"");
        SepoliaPreflight preflight = new SepoliaPreflight();
        vm.expectRevert(abi.encodeWithSelector(SepoliaChecks.SafeCodeMissing.selector, CONFIRMED_SAFE));
        preflight.run();
    }

    function testReadOnlyPreflightRejectsFailedOwnerQuery() public {
        vm.mockCallRevert(CONFIRMED_SAFE, ISafe.getOwners.selector, hex"01");
        SepoliaPreflight preflight = new SepoliaPreflight();

        vm.expectRevert(abi.encodeWithSelector(SepoliaChecks.SafeOwnersCallFailed.selector, CONFIRMED_SAFE));
        preflight.run();
    }

    function testReadOnlyPreflightRejectsFailedThresholdQuery() public {
        vm.mockCallRevert(CONFIRMED_SAFE, ISafe.getThreshold.selector, hex"01");
        SepoliaPreflight preflight = new SepoliaPreflight();

        vm.expectRevert(abi.encodeWithSelector(SepoliaChecks.SafeThresholdCallFailed.selector, CONFIRMED_SAFE));
        preflight.run();
    }

    function testReadOnlyPreflightRejectsUnexpectedOwnerCount() public {
        address[] memory owners = new address[](3);
        owners[0] = address(0x1001);
        owners[1] = address(0x1002);
        owners[2] = address(0x1003);
        vm.mockCall(CONFIRMED_SAFE, abi.encodeCall(ISafe.getOwners, ()), abi.encode(owners));
        SepoliaPreflight preflight = new SepoliaPreflight();

        vm.expectRevert(abi.encodeWithSelector(SepoliaChecks.UnexpectedOwnerCount.selector, 3));
        preflight.run();
    }

    function testReadOnlyPreflightRejectsUnexpectedThreshold() public {
        vm.mockCall(CONFIRMED_SAFE, abi.encodeCall(ISafe.getThreshold, ()), abi.encode(uint256(2)));
        SepoliaPreflight preflight = new SepoliaPreflight();

        vm.expectRevert(abi.encodeWithSelector(SepoliaChecks.UnexpectedThreshold.selector, 2));
        preflight.run();
    }

    function testReadOnlyPreflightRejectsZeroOwner() public {
        address[] memory owners = _owners();
        owners[2] = address(0);
        vm.mockCall(CONFIRMED_SAFE, abi.encodeCall(ISafe.getOwners, ()), abi.encode(owners));
        SepoliaPreflight preflight = new SepoliaPreflight();

        vm.expectRevert(abi.encodeWithSelector(SepoliaChecks.InvalidSafeOwner.selector, address(0)));
        preflight.run();
    }

    function testReadOnlyPreflightRejectsDuplicateOwner() public {
        address[] memory owners = _owners();
        owners[3] = owners[1];
        vm.mockCall(CONFIRMED_SAFE, abi.encodeCall(ISafe.getOwners, ()), abi.encode(owners));
        SepoliaPreflight preflight = new SepoliaPreflight();

        vm.expectRevert(abi.encodeWithSelector(SepoliaChecks.DuplicateSafeOwner.selector, owners[1]));
        preflight.run();
    }

    function testSepoliaDeploymentInitializesProxyForConfirmedSafe() public {
        DeployVaultCoinSepolia deployment = new DeployVaultCoinSepolia();
        (VaultCoin token, VaultCoin implementation, ERC1967Proxy proxy) = deployment.run();

        assertEq(address(token), address(proxy));
        assertTrue(address(implementation) != address(proxy));
        assertEq(token.owner(), CONFIRMED_SAFE);
        assertEq(token.feeRecipient(), CONFIRMED_SAFE);
        assertEq(token.balanceOf(CONFIRMED_SAFE), token.INITIAL_SUPPLY());
        assertEq(token.adminBurnFeeBps(), 100);
        assertFalse(token.paused());
    }

    function _owners() private pure returns (address[] memory owners) {
        owners = new address[](4);
        owners[0] = address(0x1001);
        owners[1] = address(0x1002);
        owners[2] = address(0x1003);
        owners[3] = address(0x1004);
    }
}
