// SPDX-License-Identifier: MIT
pragma solidity 0.8.24;

import {Script} from "forge-std/Script.sol";
import {console2} from "forge-std/console2.sol";

interface ISafe {
    function getOwners() external view returns (address[] memory);
    function getThreshold() external view returns (uint256);
}

library SepoliaChecks {
    uint256 internal constant SEPOLIA_CHAIN_ID = 11155111;
    address internal constant CONFIRMED_SAFE = 0xc1cC3138699e07B6d7b990DBa8fAE30b332a1eA6;

    error InvalidChain(uint256 actualChainId);
    error UnexpectedSafe(address actualSafe);
    error SafeCodeMissing(address safe);
    error SafeOwnersCallFailed(address safe);
    error SafeThresholdCallFailed(address safe);
    error InvalidSafeOwner(address owner);
    error DuplicateSafeOwner(address owner);
    error UnexpectedOwnerCount(uint256 actualOwnerCount);
    error UnexpectedThreshold(uint256 actualThreshold);

    function verify(address safe) internal view returns (address[] memory owners, uint256 threshold) {
        if (block.chainid != SEPOLIA_CHAIN_ID) revert InvalidChain(block.chainid);
        if (safe != CONFIRMED_SAFE) revert UnexpectedSafe(safe);
        if (safe.code.length == 0) revert SafeCodeMissing(safe);

        try ISafe(safe).getOwners() returns (address[] memory safeOwners) {
            owners = safeOwners;
        } catch {
            revert SafeOwnersCallFailed(safe);
        }

        try ISafe(safe).getThreshold() returns (uint256 safeThreshold) {
            threshold = safeThreshold;
        } catch {
            revert SafeThresholdCallFailed(safe);
        }

        if (owners.length != 4) revert UnexpectedOwnerCount(owners.length);
        if (threshold != 3) revert UnexpectedThreshold(threshold);

        _requireValidOwner(owners[0]);
        _requireValidOwner(owners[1]);
        _requireValidOwner(owners[2]);
        _requireValidOwner(owners[3]);
        _requireDistinctOwners(owners[0], owners[1]);
        _requireDistinctOwners(owners[0], owners[2]);
        _requireDistinctOwners(owners[0], owners[3]);
        _requireDistinctOwners(owners[1], owners[2]);
        _requireDistinctOwners(owners[1], owners[3]);
        _requireDistinctOwners(owners[2], owners[3]);
    }

    function _requireValidOwner(address owner) private pure {
        if (owner == address(0)) revert InvalidSafeOwner(owner);
    }

    function _requireDistinctOwners(address firstOwner, address secondOwner) private pure {
        if (firstOwner == secondOwner) revert DuplicateSafeOwner(secondOwner);
    }
}

contract SepoliaPreflight is Script {
    address public constant CONFIRMED_SAFE = 0xc1cC3138699e07B6d7b990DBa8fAE30b332a1eA6;

    /// @notice Performs read-only Sepolia and Safe checks. Never use --broadcast.
    function run() external view {
        (address[] memory owners, uint256 threshold) = SepoliaChecks.verify(CONFIRMED_SAFE);

        console2.log("Sepolia preflight: OK");
        console2.log("Safe address:");
        console2.logAddress(CONFIRMED_SAFE);
        console2.log("Owners:");
        for (uint256 i = 0; i < owners.length; ++i) {
            console2.logAddress(owners[i]);
        }
        console2.log("Threshold:");
        console2.logUint(threshold);

        address deployer = vm.envOr("DEPLOYER_ADDRESS", address(0));
        if (deployer == address(0)) {
            console2.log("DEPLOYER_ADDRESS not set; balance check skipped.");
        } else {
            console2.log("Deployer address:");
            console2.logAddress(deployer);
            console2.log("Deployer Sepolia ETH balance (wei):");
            console2.logUint(deployer.balance);
        }
    }
}
