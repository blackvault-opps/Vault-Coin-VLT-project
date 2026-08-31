// SPDX-License-Identifier: MIT
pragma solidity 0.8.24;

import {Test} from "forge-std/Test.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {IERC20Errors} from "@openzeppelin/contracts/interfaces/draft-IERC6093.sol";
import {VaultCoin} from "../src/VaultCoin.sol";

contract VaultCoinTest is Test {
    uint256 internal constant INITIAL_SUPPLY = 100_000_000 ether;
    uint256 internal constant ONE_TOKEN = 1 ether;
    uint256 internal constant MINT_AMOUNT = 25 ether;
    uint256 internal constant TRANSFER_AMOUNT = 10 ether;
    uint256 internal constant APPROVAL_AMOUNT = 20 ether;
    uint256 internal constant SPEND_AMOUNT = 7 ether;

    VaultCoin internal token;

    address internal owner;
    address internal alice;
    address internal bob;

    function setUp() public {
        owner = makeAddr("owner");
        alice = makeAddr("alice");
        bob = makeAddr("bob");

        vm.prank(owner);
        token = new VaultCoin();
    }

    function testMetadataOwnershipAndInitialSupply() public view {
        assertEq(token.name(), "Vault Coin");
        assertEq(token.symbol(), "VLT");
        assertEq(token.decimals(), 18);
        assertEq(token.owner(), owner);
        assertEq(token.INITIAL_SUPPLY(), INITIAL_SUPPLY);
        assertEq(token.totalSupply(), INITIAL_SUPPLY);
        assertEq(token.balanceOf(owner), token.totalSupply());
    }

    function testOwnerCanMint() public {
        vm.prank(owner);
        token.mint(alice, MINT_AMOUNT);

        assertEq(token.balanceOf(alice), MINT_AMOUNT);
        assertEq(token.totalSupply(), INITIAL_SUPPLY + MINT_AMOUNT);
    }

    function testNonOwnerCannotMint() public {
        vm.prank(alice);
        vm.expectRevert(abi.encodeWithSelector(Ownable.OwnableUnauthorizedAccount.selector, alice));
        token.mint(alice, ONE_TOKEN);
    }

    function testMintToZeroAddressReverts() public {
        vm.prank(owner);
        vm.expectRevert(abi.encodeWithSelector(IERC20Errors.ERC20InvalidReceiver.selector, address(0)));
        token.mint(address(0), ONE_TOKEN);
    }

    function testTransfer() public {
        vm.prank(owner);
        assertTrue(token.transfer(alice, TRANSFER_AMOUNT));

        assertEq(token.balanceOf(owner), INITIAL_SUPPLY - TRANSFER_AMOUNT);
        assertEq(token.balanceOf(alice), TRANSFER_AMOUNT);
    }

    function testApproveAndTransferFrom() public {
        vm.prank(owner);
        assertTrue(token.approve(alice, APPROVAL_AMOUNT));

        vm.prank(alice);
        // forge-lint: disable-next-line(arbitrary-send-erc20)
        assertTrue(token.transferFrom(owner, bob, SPEND_AMOUNT));

        assertEq(token.balanceOf(bob), SPEND_AMOUNT);
        assertEq(token.allowance(owner, alice), APPROVAL_AMOUNT - SPEND_AMOUNT);
    }

    function testTransferToZeroAddressReverts() public {
        vm.prank(owner);
        vm.expectRevert(abi.encodeWithSelector(IERC20Errors.ERC20InvalidReceiver.selector, address(0)));
        // forge-lint: disable-next-line(erc20-unchecked-transfer)
        token.transfer(address(0), ONE_TOKEN);
    }

    function testTransferExceedingBalanceReverts() public {
        vm.prank(alice);
        vm.expectRevert(abi.encodeWithSelector(IERC20Errors.ERC20InsufficientBalance.selector, alice, 0, ONE_TOKEN));
        // forge-lint: disable-next-line(erc20-unchecked-transfer)
        token.transfer(bob, ONE_TOKEN);
    }

    function testTransferFromExceedingAllowanceReverts() public {
        vm.prank(alice);
        vm.expectRevert(abi.encodeWithSelector(IERC20Errors.ERC20InsufficientAllowance.selector, alice, 0, ONE_TOKEN));
        // forge-lint: disable-next-line(arbitrary-send-erc20, erc20-unchecked-transfer)
        token.transferFrom(owner, bob, ONE_TOKEN);
    }

    function testOwnerCanTransferOwnership() public {
        vm.prank(owner);
        token.transferOwnership(alice);

        assertEq(token.owner(), alice);
    }

    function testOwnershipTransferMovesMintAuthority() public {
        vm.prank(owner);
        token.transferOwnership(alice);

        vm.prank(owner);
        vm.expectRevert(abi.encodeWithSelector(Ownable.OwnableUnauthorizedAccount.selector, owner));
        token.mint(bob, ONE_TOKEN);

        vm.prank(alice);
        token.mint(bob, ONE_TOKEN);
        assertEq(token.balanceOf(bob), ONE_TOKEN);
    }

    function testRenouncingOwnershipPermanentlyDisablesMintingButNotTransfers() public {
        vm.prank(owner);
        token.renounceOwnership();

        assertEq(token.owner(), address(0));

        vm.prank(owner);
        vm.expectRevert(abi.encodeWithSelector(Ownable.OwnableUnauthorizedAccount.selector, owner));
        token.mint(alice, ONE_TOKEN);

        vm.prank(owner);
        assertTrue(token.transfer(alice, ONE_TOKEN));
        assertEq(token.balanceOf(alice), ONE_TOKEN);
    }
}
