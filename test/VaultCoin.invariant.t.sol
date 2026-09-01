// SPDX-License-Identifier: MIT
pragma solidity 0.8.24;

import {Test} from "forge-std/Test.sol";
import {StdInvariant} from "forge-std/StdInvariant.sol";
import {ERC1967Proxy} from "@openzeppelin/contracts/proxy/ERC1967/ERC1967Proxy.sol";
import {VaultCoin} from "../src/VaultCoin.sol";

contract VaultCoinHandler is Test {
    VaultCoin internal immutable token;
    address internal immutable owner;
    address internal alice;
    address internal bob;

    constructor(VaultCoin token_, address owner_) {
        require(address(token_) != address(0) && owner_ != address(0), "zero address");
        token = token_;
        owner = owner_;
        alice = makeAddr("invariant-alice");
        bob = makeAddr("invariant-bob");
    }

    function mint(uint256 amount) external {
        uint256 remaining = token.MAX_SUPPLY() - token.cumulativeMinted();
        amount = bound(amount, 0, remaining);
        vm.prank(owner);
        token.mint(alice, amount);
    }

    function transfer(uint256 amount) external {
        uint256 balance = token.balanceOf(owner);
        amount = bound(amount, 0, balance);
        vm.prank(owner);
        assertTrue(token.transfer(bob, amount));
    }

    function burn(uint256 amount) external {
        uint256 balance = token.balanceOf(alice);
        amount = bound(amount, 0, balance);
        vm.prank(alice);
        token.burn(amount);
    }
}

contract VaultCoinInvariantTest is StdInvariant, Test {
    VaultCoin internal token;
    address internal owner;

    function setUp() public {
        owner = makeAddr("invariant-owner");
        VaultCoin implementation = new VaultCoin();
        bytes memory initializer = abi.encodeCall(VaultCoin.initialize, (owner, owner, 100));
        ERC1967Proxy proxy = new ERC1967Proxy(address(implementation), initializer);
        token = VaultCoin(payable(address(proxy)));

        VaultCoinHandler handler = new VaultCoinHandler(token, owner);
        targetContract(address(handler));
    }

    function invariantLifetimeMintNeverExceedsMaximum() public view {
        assertLe(token.cumulativeMinted(), token.MAX_SUPPLY());
    }

    function invariantTotalSupplyNeverExceedsLifetimeMint() public view {
        assertLe(token.totalSupply(), token.cumulativeMinted());
    }

    function invariantOwnerCanNeverBeZero() public view {
        assertTrue(token.owner() != address(0));
    }
}
