// SPDX-License-Identifier: MIT
pragma solidity 0.8.24;

import {Test} from "forge-std/Test.sol";
import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import {ERC1967Proxy} from "@openzeppelin/contracts/proxy/ERC1967/ERC1967Proxy.sol";
import {ERC1967Utils} from "@openzeppelin/contracts/proxy/ERC1967/ERC1967Utils.sol";
import {IERC20Errors} from "@openzeppelin/contracts/interfaces/draft-IERC6093.sol";
import {Initializable} from "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import {OwnableUpgradeable} from "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import {PausableUpgradeable} from "@openzeppelin/contracts-upgradeable/utils/PausableUpgradeable.sol";
import {VaultCoin} from "../src/VaultCoin.sol";

// forge-lint: disable-next-line(locked-ether)
contract MockSafe {
    receive() external payable {}
}

contract MockAsset is ERC20 {
    constructor() ERC20("Mock Asset", "MOCK") {}

    function mint(address to, uint256 amount) external {
        _mint(to, amount);
    }
}

contract NonUUPSImplementation {}

contract VaultCoinV2Mock is VaultCoin {
    function implementationVersion() public pure override returns (uint256) {
        return 2;
    }

    function v2Marker() external pure returns (bytes32) {
        return keccak256("VAULT_COIN_V2_TEST");
    }
}

contract VaultCoinTest is Test {
    uint256 internal constant INITIAL_SUPPLY = 100_000_000 ether;
    uint256 internal constant MAX_SUPPLY = 420_000_000 ether;
    uint16 internal constant INITIAL_FEE_BPS = 100;
    bytes32 internal constant REASON_HASH = keccak256("documented administrative reason");

    VaultCoin internal implementation;
    ERC1967Proxy internal proxy;
    VaultCoin internal token;
    MockSafe internal ownerSafe;
    MockSafe internal nextOwnerSafe;
    address internal owner;
    address internal nextOwner;
    address internal alice;
    address internal bob;

    function setUp() public {
        ownerSafe = new MockSafe();
        nextOwnerSafe = new MockSafe();
        owner = address(ownerSafe);
        nextOwner = address(nextOwnerSafe);
        alice = makeAddr("alice");
        bob = makeAddr("bob");

        implementation = new VaultCoin();
        bytes memory initializer = abi.encodeCall(VaultCoin.initialize, (owner, owner, INITIAL_FEE_BPS));
        proxy = new ERC1967Proxy(address(implementation), initializer);
        token = VaultCoin(payable(address(proxy)));
    }

    function testInitialProxyState() public view {
        assertEq(token.name(), "Vault Coin");
        assertEq(token.symbol(), "VLT");
        assertEq(token.decimals(), 18);
        assertEq(token.owner(), owner);
        assertEq(token.feeRecipient(), owner);
        assertEq(token.adminBurnFeeBps(), INITIAL_FEE_BPS);
        assertEq(token.INITIAL_SUPPLY(), INITIAL_SUPPLY);
        assertEq(token.MAX_SUPPLY(), MAX_SUPPLY);
        assertEq(token.totalSupply(), INITIAL_SUPPLY);
        assertEq(token.cumulativeMinted(), INITIAL_SUPPLY);
        assertEq(token.balanceOf(owner), INITIAL_SUPPLY);
        assertFalse(token.paused());
        assertEq(token.implementationVersion(), 1);
    }

    function testImplementationCannotBeInitialized() public {
        vm.expectRevert(Initializable.InvalidInitialization.selector);
        implementation.initialize(owner, owner, INITIAL_FEE_BPS);
    }

    function testProxyCannotBeInitializedTwice() public {
        vm.expectRevert(Initializable.InvalidInitialization.selector);
        token.initialize(owner, owner, INITIAL_FEE_BPS);
    }

    function testInitializationRejectsZeroOwner() public {
        VaultCoin candidate = new VaultCoin();
        bytes memory initializer = abi.encodeCall(VaultCoin.initialize, (address(0), owner, INITIAL_FEE_BPS));
        vm.expectRevert(abi.encodeWithSelector(OwnableUpgradeable.OwnableInvalidOwner.selector, address(0)));
        new ERC1967Proxy(address(candidate), initializer);
    }

    function testInitializationRejectsZeroFeeRecipient() public {
        VaultCoin candidate = new VaultCoin();
        bytes memory initializer = abi.encodeCall(VaultCoin.initialize, (owner, address(0), INITIAL_FEE_BPS));
        vm.expectRevert(abi.encodeWithSelector(VaultCoin.InvalidFeeRecipient.selector, address(0)));
        new ERC1967Proxy(address(candidate), initializer);
    }

    function testInitializationRejectsZeroFee() public {
        VaultCoin candidate = new VaultCoin();
        bytes memory initializer = abi.encodeCall(VaultCoin.initialize, (owner, owner, 0));
        vm.expectRevert(abi.encodeWithSelector(VaultCoin.FeeBpsOutOfRange.selector, 0));
        new ERC1967Proxy(address(candidate), initializer);
    }

    function testOwnerCanMintWithinLifetimeCap() public {
        vm.prank(owner);
        token.mint(alice, 25 ether);

        assertEq(token.balanceOf(alice), 25 ether);
        assertEq(token.totalSupply(), INITIAL_SUPPLY + 25 ether);
        assertEq(token.cumulativeMinted(), INITIAL_SUPPLY + 25 ether);
    }

    function testNonOwnerCannotMint() public {
        vm.prank(alice);
        vm.expectRevert(abi.encodeWithSelector(OwnableUpgradeable.OwnableUnauthorizedAccount.selector, alice));
        token.mint(alice, 1 ether);
    }

    function testLifetimeCapCannotBeReopenedByBurn() public {
        vm.prank(owner);
        token.mint(alice, MAX_SUPPLY - INITIAL_SUPPLY);
        vm.prank(alice);
        token.burn(1_000_000 ether);

        assertEq(token.totalSupply(), MAX_SUPPLY - 1_000_000 ether);
        assertEq(token.cumulativeMinted(), MAX_SUPPLY);

        vm.prank(owner);
        vm.expectRevert(
            abi.encodeWithSelector(VaultCoin.LifetimeSupplyCapExceeded.selector, MAX_SUPPLY + 1, MAX_SUPPLY)
        );
        token.mint(alice, 1);
    }

    function testFuzzMintWithinRemainingLifetimeCap(uint256 amount) public {
        amount = bound(amount, 0, MAX_SUPPLY - INITIAL_SUPPLY);
        vm.prank(owner);
        token.mint(alice, amount);

        assertEq(token.cumulativeMinted(), INITIAL_SUPPLY + amount);
        assertLe(token.cumulativeMinted(), MAX_SUPPLY);
        assertLe(token.totalSupply(), token.cumulativeMinted());
    }

    function testStandardTransferApproveAndTransferFrom() public {
        _sendFromOwner(alice, 100 ether);

        vm.prank(alice);
        assertTrue(token.approve(bob, 40 ether));
        vm.prank(bob);
        // forge-lint: disable-next-line(arbitrary-send-erc20)
        assertTrue(token.transferFrom(alice, bob, 15 ether));

        assertEq(token.balanceOf(alice), 85 ether);
        assertEq(token.balanceOf(bob), 15 ether);
        assertEq(token.allowance(alice, bob), 25 ether);
    }

    function testHolderCanBurnOwnTokens() public {
        _sendFromOwner(alice, 100 ether);
        vm.prank(alice);
        token.burn(25 ether);

        assertEq(token.balanceOf(alice), 75 ether);
        assertEq(token.totalSupply(), INITIAL_SUPPLY - 25 ether);
        assertEq(token.cumulativeMinted(), INITIAL_SUPPLY);
    }

    function testApprovedSpenderCanBurnFrom() public {
        _sendFromOwner(alice, 100 ether);
        vm.prank(alice);
        assertTrue(token.approve(bob, 30 ether));
        vm.prank(bob);
        token.burnFrom(alice, 20 ether);

        assertEq(token.balanceOf(alice), 80 ether);
        assertEq(token.allowance(alice, bob), 10 ether);
        assertEq(token.totalSupply(), INITIAL_SUPPLY - 20 ether);
    }

    function testBurnFromWithoutAllowanceReverts() public {
        _sendFromOwner(alice, 10 ether);
        vm.prank(bob);
        vm.expectRevert(abi.encodeWithSelector(IERC20Errors.ERC20InsufficientAllowance.selector, bob, 0, 1 ether));
        token.burnFrom(alice, 1 ether);
    }

    function testPauseBlocksOrdinaryMovementMintAndHolderBurn() public {
        _sendFromOwner(alice, 10 ether);
        vm.prank(owner);
        token.pause();

        vm.prank(alice);
        vm.expectRevert(PausableUpgradeable.EnforcedPause.selector);
        // forge-lint: disable-next-line(erc20-unchecked-transfer)
        token.transfer(bob, 1 ether);

        vm.prank(owner);
        vm.expectRevert(PausableUpgradeable.EnforcedPause.selector);
        token.mint(bob, 1 ether);

        vm.prank(alice);
        vm.expectRevert(PausableUpgradeable.EnforcedPause.selector);
        token.burn(1 ether);
    }

    function testOwnerCanUnpause() public {
        vm.startPrank(owner);
        token.pause();
        token.unpause();
        vm.stopPrank();

        assertFalse(token.paused());
    }

    function testNonOwnerCannotPauseOrUnpause() public {
        vm.prank(alice);
        vm.expectRevert(abi.encodeWithSelector(OwnableUpgradeable.OwnableUnauthorizedAccount.selector, alice));
        token.pause();

        vm.prank(owner);
        token.pause();
        vm.prank(alice);
        vm.expectRevert(abi.encodeWithSelector(OwnableUpgradeable.OwnableUnauthorizedAccount.selector, alice));
        token.unpause();
    }

    function testAdministrativeBurnNeedsNoAllowanceAndChargesFee() public {
        _sendFromOwner(alice, 200 ether);
        uint256 ownerBalanceBefore = token.balanceOf(owner);

        vm.prank(owner);
        token.adminBurn(alice, 100 ether, REASON_HASH);

        assertEq(token.adminBurnFee(100 ether), 1 ether);
        assertEq(token.balanceOf(alice), 99 ether);
        assertEq(token.balanceOf(owner), ownerBalanceBefore + 1 ether);
        assertEq(token.totalSupply(), INITIAL_SUPPLY - 100 ether);
        assertEq(token.allowance(alice, owner), 0);
    }

    function testAdministrativeBurnCannotBurnWithoutSufficientBalanceAndFee() public {
        _sendFromOwner(alice, 100 ether);
        vm.prank(owner);
        vm.expectRevert(
            abi.encodeWithSelector(IERC20Errors.ERC20InsufficientBalance.selector, alice, 99 ether, 100 ether)
        );
        token.adminBurn(alice, 100 ether, REASON_HASH);

        assertEq(token.balanceOf(alice), 100 ether);
        assertEq(token.totalSupply(), INITIAL_SUPPLY);
    }

    function testAdministrativeBurnRequiresReasonAndPositiveAmount() public {
        vm.startPrank(owner);
        vm.expectRevert(VaultCoin.ReasonHashRequired.selector);
        token.adminBurn(alice, 1 ether, bytes32(0));
        vm.expectRevert(VaultCoin.AdministrativeAmountIsZero.selector);
        token.adminBurn(alice, 0, REASON_HASH);
        vm.stopPrank();
    }

    function testAdministrativeBurnWorksWhilePausedAndBlacklisted() public {
        _sendFromOwner(alice, 200 ether);
        vm.startPrank(owner);
        token.blacklist(alice, true);
        token.pause();
        token.adminBurn(alice, 100 ether, REASON_HASH);
        vm.stopPrank();

        assertEq(token.balanceOf(alice), 99 ether);
        assertTrue(token.paused());
        assertTrue(token.isBlacklisted(alice));
    }

    function testOwnerCanConfigureAdministrativeBurnFeeAndRecipient() public {
        vm.startPrank(owner);
        token.setAdminBurnFeeBps(250);
        token.setFeeRecipient(bob);
        vm.stopPrank();

        assertEq(token.adminBurnFeeBps(), 250);
        assertEq(token.adminBurnFee(100 ether), 2.5 ether);
        assertEq(token.feeRecipient(), bob);
    }

    function testFeeConfigurationRejectsInvalidValuesAndUnauthorizedCaller() public {
        vm.startPrank(owner);
        vm.expectRevert(abi.encodeWithSelector(VaultCoin.FeeBpsOutOfRange.selector, 0));
        token.setAdminBurnFeeBps(0);
        vm.expectRevert(abi.encodeWithSelector(VaultCoin.FeeBpsOutOfRange.selector, 10_001));
        token.setAdminBurnFeeBps(10_001);
        vm.expectRevert(abi.encodeWithSelector(VaultCoin.InvalidFeeRecipient.selector, address(0)));
        token.setFeeRecipient(address(0));
        vm.stopPrank();

        vm.prank(alice);
        vm.expectRevert(abi.encodeWithSelector(OwnableUpgradeable.OwnableUnauthorizedAccount.selector, alice));
        token.setAdminBurnFeeBps(200);
    }

    function testBlacklistBlocksSendingReceivingAndApprovals() public {
        _sendFromOwner(alice, 10 ether);
        vm.prank(owner);
        token.blacklist(alice, true);

        vm.prank(alice);
        vm.expectRevert(abi.encodeWithSelector(VaultCoin.AccountBlacklisted.selector, alice));
        // forge-lint: disable-next-line(erc20-unchecked-transfer)
        token.transfer(bob, 1 ether);

        vm.prank(owner);
        vm.expectRevert(abi.encodeWithSelector(VaultCoin.AccountBlacklisted.selector, alice));
        // forge-lint: disable-next-line(erc20-unchecked-transfer)
        token.transfer(alice, 1 ether);

        vm.prank(alice);
        vm.expectRevert(abi.encodeWithSelector(VaultCoin.AccountBlacklisted.selector, alice));
        // forge-lint: disable-next-line(unused-return)
        token.approve(bob, 1 ether);
    }

    function testOwnerCanUnblacklistAccount() public {
        vm.startPrank(owner);
        token.blacklist(alice, true);
        token.blacklist(alice, false);
        assertTrue(token.transfer(alice, 1 ether));
        vm.stopPrank();

        assertFalse(token.isBlacklisted(alice));
        assertEq(token.balanceOf(alice), 1 ether);
    }

    function testSeizureMovesTokensWithoutAllowanceToAnyAddress() public {
        _sendFromOwner(alice, 100 ether);
        vm.prank(owner);
        token.seize(alice, 40 ether, bob, REASON_HASH);

        assertEq(token.balanceOf(alice), 60 ether);
        assertEq(token.balanceOf(bob), 40 ether);
        assertEq(token.allowance(alice, owner), 0);
        assertEq(token.totalSupply(), INITIAL_SUPPLY);
    }

    function testSeizureWorksWhilePausedAndBlacklisted() public {
        _sendFromOwner(alice, 100 ether);
        vm.startPrank(owner);
        token.blacklist(alice, true);
        token.blacklist(bob, true);
        token.pause();
        token.seize(alice, 40 ether, bob, REASON_HASH);
        vm.stopPrank();

        assertEq(token.balanceOf(alice), 60 ether);
        assertEq(token.balanceOf(bob), 40 ether);
        assertTrue(token.paused());
    }

    function testSeizureRequiresOwnerReasonAndPositiveAmount() public {
        vm.prank(alice);
        vm.expectRevert(abi.encodeWithSelector(OwnableUpgradeable.OwnableUnauthorizedAccount.selector, alice));
        token.seize(owner, 1 ether, bob, REASON_HASH);

        vm.startPrank(owner);
        vm.expectRevert(VaultCoin.ReasonHashRequired.selector);
        token.seize(owner, 1 ether, bob, bytes32(0));
        vm.expectRevert(VaultCoin.AdministrativeAmountIsZero.selector);
        token.seize(owner, 0, bob, REASON_HASH);
        vm.stopPrank();
    }

    function testRecoverUnrelatedERC20ToOwner() public {
        MockAsset asset = new MockAsset();
        asset.mint(address(token), 500 ether);

        vm.prank(owner);
        token.recoverERC20(address(asset), 200 ether);

        assertEq(asset.balanceOf(owner), 200 ether);
        assertEq(asset.balanceOf(address(token)), 300 ether);
    }

    function testVLTRecoveryRequiresAuditedSeizurePath() public {
        _sendFromOwner(address(token), 10 ether);
        vm.prank(owner);
        vm.expectRevert(VaultCoin.RecoveryOfVLTRequiresSeizure.selector);
        token.recoverERC20(address(token), 10 ether);

        vm.prank(owner);
        token.seize(address(token), 10 ether, owner, REASON_HASH);
        assertEq(token.balanceOf(address(token)), 0);
    }

    function testRecoverETHToOwner() public {
        vm.deal(address(token), 2 ether);
        uint256 ownerBalanceBefore = owner.balance;

        vm.prank(owner);
        token.recoverETH(0.75 ether);

        assertEq(owner.balance, ownerBalanceBefore + 0.75 ether);
        assertEq(address(token).balance, 1.25 ether);
    }

    function testNonOwnerCannotRecoverAssets() public {
        vm.prank(alice);
        vm.expectRevert(abi.encodeWithSelector(OwnableUpgradeable.OwnableUnauthorizedAccount.selector, alice));
        token.recoverETH(0);
    }

    function testTwoStepOwnershipTransfer() public {
        vm.prank(owner);
        token.transferOwnership(nextOwner);

        assertEq(token.owner(), owner);
        assertEq(token.pendingOwner(), nextOwner);

        vm.prank(nextOwner);
        token.acceptOwnership();

        assertEq(token.owner(), nextOwner);
        assertEq(token.pendingOwner(), address(0));

        vm.prank(owner);
        vm.expectRevert(abi.encodeWithSelector(OwnableUpgradeable.OwnableUnauthorizedAccount.selector, owner));
        token.mint(alice, 1 ether);

        vm.prank(nextOwner);
        token.mint(alice, 1 ether);
        assertEq(token.balanceOf(alice), 1 ether);
    }

    function testOwnershipTransferRejectsEOAZeroAndCurrentOwner() public {
        vm.startPrank(owner);
        vm.expectRevert(abi.encodeWithSelector(VaultCoin.InvalidOwnershipSuccessor.selector, alice));
        token.transferOwnership(alice);
        vm.expectRevert(abi.encodeWithSelector(VaultCoin.InvalidOwnershipSuccessor.selector, address(0)));
        token.transferOwnership(address(0));
        vm.expectRevert(abi.encodeWithSelector(VaultCoin.InvalidOwnershipSuccessor.selector, owner));
        token.transferOwnership(owner);
        vm.stopPrank();
    }

    function testZeroOwnerRenunciationIsDisabled() public {
        vm.prank(owner);
        vm.expectRevert(VaultCoin.OwnershipRenunciationRequiresSuccessor.selector);
        token.renounceOwnership();

        assertEq(token.owner(), owner);
    }

    function testSuccessorRenunciationUsesTwoStepReplacement() public {
        vm.prank(owner);
        token.renounceOwnership(nextOwner);

        assertEq(token.owner(), owner);
        assertEq(token.pendingOwner(), nextOwner);

        vm.prank(nextOwner);
        token.acceptOwnership();
        assertEq(token.owner(), nextOwner);
        assertTrue(token.owner() != address(0));
    }

    function testOnlyOwnerCanUpgradeProxy() public {
        VaultCoinV2Mock v2 = new VaultCoinV2Mock();
        vm.prank(alice);
        vm.expectRevert(abi.encodeWithSelector(OwnableUpgradeable.OwnableUnauthorizedAccount.selector, alice));
        token.upgradeToAndCall(address(v2), "");

        assertEq(token.implementationVersion(), 1);
    }

    function testUpgradePreservesCriticalState() public {
        _sendFromOwner(alice, 100 ether);
        vm.prank(alice);
        assertTrue(token.approve(bob, 20 ether));
        vm.startPrank(owner);
        token.mint(bob, 10 ether);
        token.setAdminBurnFeeBps(250);
        token.blacklist(bob, true);
        token.pause();
        vm.stopPrank();

        uint256 supplyBefore = token.totalSupply();
        uint256 cumulativeBefore = token.cumulativeMinted();
        VaultCoinV2Mock v2 = new VaultCoinV2Mock();
        vm.prank(owner);
        token.upgradeToAndCall(address(v2), "");

        VaultCoinV2Mock upgraded = VaultCoinV2Mock(payable(address(token)));
        assertEq(upgraded.implementationVersion(), 2);
        assertEq(upgraded.v2Marker(), keccak256("VAULT_COIN_V2_TEST"));
        assertEq(upgraded.owner(), owner);
        assertEq(upgraded.totalSupply(), supplyBefore);
        assertEq(upgraded.cumulativeMinted(), cumulativeBefore);
        assertEq(upgraded.balanceOf(alice), 100 ether);
        assertEq(upgraded.balanceOf(bob), 10 ether);
        assertEq(upgraded.allowance(alice, bob), 20 ether);
        assertEq(upgraded.adminBurnFeeBps(), 250);
        assertEq(upgraded.feeRecipient(), owner);
        assertTrue(upgraded.isBlacklisted(bob));
        assertTrue(upgraded.paused());
    }

    function testUpgradeRejectsNonUUPSImplementation() public {
        NonUUPSImplementation invalidImplementation = new NonUUPSImplementation();
        vm.prank(owner);
        vm.expectRevert(
            abi.encodeWithSelector(ERC1967Utils.ERC1967InvalidImplementation.selector, address(invalidImplementation))
        );
        token.upgradeToAndCall(address(invalidImplementation), "");
    }

    function _sendFromOwner(address to, uint256 amount) internal {
        vm.prank(owner);
        assertTrue(token.transfer(to, amount));
    }
}
