// SPDX-License-Identifier: MIT
pragma solidity 0.8.24;

import {VaultCoin} from "../src/VaultCoin.sol";

contract TokenActor {
    function transfer(VaultCoin token, address to, uint256 amount) external returns (bool) {
        return token.transfer(to, amount);
    }

    function pause(VaultCoin token) external {
        token.pause();
    }

    function renounce(VaultCoin token) external {
        token.renounceOwnership();
    }

    function acceptOwnership(VaultCoin token) external {
        token.acceptOwnership();
    }
}

contract VaultCoinTest {
    VaultCoin internal token;
    TokenActor internal holder;
    TokenActor internal recipient;

    function setUp() public {
        holder = new TokenActor();
        recipient = new TokenActor();
        token = new VaultCoin(address(this), address(holder));
    }

    function testMetadataAndFixedSupply() public view {
        require(keccak256(bytes(token.name())) == keccak256("Vault Coin"), "name");
        require(keccak256(bytes(token.symbol())) == keccak256("VLT"), "symbol");
        require(token.decimals() == 18, "decimals");
        require(token.totalSupply() == 100_000_000 ether, "supply");
        require(token.balanceOf(address(holder)) == token.totalSupply(), "recipient");
    }

    function testOwnerCanPauseAndUnpause() public {
        token.pause();
        require(token.paused(), "not paused");

        bool reverted;
        try holder.transfer(token, address(recipient), 1 ether) {
            reverted = false;
        } catch {
            reverted = true;
        }
        require(reverted, "transfer succeeded while paused");

        token.unpause();
        require(holder.transfer(token, address(recipient), 1 ether), "transfer failed");
        require(token.balanceOf(address(recipient)) == 1 ether, "wrong balance");
    }

    function testNonOwnerCannotPause() public {
        bool reverted;
        try holder.pause(token) {
            reverted = false;
        } catch {
            reverted = true;
        }
        require(reverted, "non-owner paused");
    }

    function testOwnershipCanBeTransferred() public {
        token.transferOwnership(address(holder));
        require(token.owner() == address(this), "owner changed before acceptance");
        require(token.pendingOwner() == address(holder), "pending owner not set");
        holder.acceptOwnership(token);
        require(token.owner() == address(holder), "owner not transferred");
    }

    function testOwnershipCannotBeTransferredToEOA() public {
        bool reverted;
        try token.transferOwnership(address(0xBEEF)) {
            reverted = false;
        } catch {
            reverted = true;
        }
        require(reverted, "EOA accepted as owner");
    }

    function testOwnershipCannotBeRenounced() public {
        bool reverted;
        try token.renounceOwnership() {
            reverted = false;
        } catch {
            reverted = true;
        }
        require(reverted, "ownership renounced");
        require(token.owner() == address(this), "owner changed");
    }

    function testZeroRecipientReverts() public {
        bool reverted;
        try new VaultCoin(address(this), address(0)) {
            reverted = false;
        } catch {
            reverted = true;
        }
        require(reverted, "zero recipient accepted");
    }

    function testEOAOwnerReverts() public {
        bool reverted;
        try new VaultCoin(address(0xBEEF), address(holder)) {
            reverted = false;
        } catch {
            reverted = true;
        }
        require(reverted, "EOA accepted as owner");
    }

    function testEOATreasuryReverts() public {
        bool reverted;
        try new VaultCoin(address(this), address(0xBEEF)) {
            reverted = false;
        } catch {
            reverted = true;
        }
        require(reverted, "EOA accepted as treasury");
    }
}
