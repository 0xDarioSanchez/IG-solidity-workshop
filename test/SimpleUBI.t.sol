// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import {Test, console} from "forge-std/Test.sol";
import {SimpleUBI} from "../src/SimpleUBI.sol";

contract SimpleUBITest is Test {
    SimpleUBI public ubi;
    address public owner = address(1);
    address public user1 = address(2);
    address public user2 = address(3);
    uint256 public constant DAILY_AMOUNT = 100 * 10**18; // 100 tokens with 18 decimals

    function setUp() public {
        vm.prank(owner);
        ubi = new SimpleUBI("Universal Basic Income", "UBI", DAILY_AMOUNT, owner);
    }

    function test_Deployment() public view {
        assertEq(ubi.name(), "Universal Basic Income");
        assertEq(ubi.symbol(), "UBI");
        assertEq(ubi.dailyClaimAmount(), DAILY_AMOUNT);
        assertEq(ubi.owner(), owner);
    }

    function test_VerifyUser() public {
        vm.prank(owner);
        ubi.verifyUser(user1);
        assertTrue(ubi.isVerified(user1));
    }

    function test_UnverifyUser() public {
        vm.startPrank(owner);
        ubi.verifyUser(user1);
        assertTrue(ubi.isVerified(user1));
        
        ubi.unverifyUser(user1);
        assertFalse(ubi.isVerified(user1));
        vm.stopPrank();
    }

    function test_CannotVerifyAsNonOwner() public {
        vm.prank(user1);
        vm.expectRevert();
        ubi.verifyUser(user2);
    }

    function test_ClaimTokens() public {
        // Verify user first
        vm.prank(owner);
        ubi.verifyUser(user1);

        // User claims tokens
        vm.prank(user1);
        ubi.claim(user1);

        // Check balance
        assertEq(ubi.balanceOf(user1), DAILY_AMOUNT);
    }

    function test_CannotClaimWithoutVerification() public {
        vm.prank(user1);
        vm.expectRevert("User not verified");
        ubi.claim(user1);
    }

    function test_CannotClaimTwiceInSameDay() public {
        vm.prank(owner);
        ubi.verifyUser(user1);

        vm.startPrank(user1);
        ubi.claim(user1);
        
        // Try to claim again
        vm.expectRevert("Already claimed today");
        ubi.claim(user1);
        vm.stopPrank();
    }

    function test_CanClaimNextDay() public {
        vm.prank(owner);
        ubi.verifyUser(user1);

        // Claim on day 1
        vm.prank(user1);
        ubi.claim(user1);
        assertEq(ubi.balanceOf(user1), DAILY_AMOUNT);

        // Fast forward 1 day
        vm.warp(block.timestamp + 1 days);

        // Claim on day 2
        vm.prank(user1);
        ubi.claim(user1);
        assertEq(ubi.balanceOf(user1), DAILY_AMOUNT * 2);
    }

    function test_MultipleUsersClaim() public {
        // Verify both users
        vm.startPrank(owner);
        ubi.verifyUser(user1);
        ubi.verifyUser(user2);
        vm.stopPrank();

        // Both users claim
        vm.prank(user1);
        ubi.claim(user1);

        vm.prank(user2);
        ubi.claim(user2);

        // Check balances
        assertEq(ubi.balanceOf(user1), DAILY_AMOUNT);
        assertEq(ubi.balanceOf(user2), DAILY_AMOUNT);
    }

    function test_CanClaimToDifferentAddress() public {
        vm.prank(owner);
        ubi.verifyUser(user1);

        // User1 claims but sends tokens to user2
        vm.prank(user1);
        ubi.claim(user2);

        assertEq(ubi.balanceOf(user1), 0);
        assertEq(ubi.balanceOf(user2), DAILY_AMOUNT);
    }

    function test_GetLastClaimDay() public {
        vm.prank(owner);
        ubi.verifyUser(user1);

        uint256 currentDay = ubi.getCurrentDay();
        
        vm.prank(user1);
        ubi.claim(user1);

        assertEq(ubi.getLastClaimDay(user1), currentDay);
    }

    function test_CanClaim() public {
        vm.prank(owner);
        ubi.verifyUser(user1);

        // Should be able to claim initially
        assertTrue(ubi.canClaim(user1));

        // Claim tokens
        vm.prank(user1);
        ubi.claim(user1);

        // Should not be able to claim same day
        assertFalse(ubi.canClaim(user1));

        // Fast forward 1 day
        vm.warp(block.timestamp + 1 days);

        // Should be able to claim again
        assertTrue(ubi.canClaim(user1));
    }

    function test_UpdateDailyClaimAmount() public {
        uint256 newAmount = 200 * 10**18;
        
        vm.prank(owner);
        ubi.setDailyClaimAmount(newAmount);

        assertEq(ubi.dailyClaimAmount(), newAmount);

        // Verify new claims use new amount
        vm.prank(owner);
        ubi.verifyUser(user1);

        vm.prank(user1);
        ubi.claim(user1);

        assertEq(ubi.balanceOf(user1), newAmount);
    }

    function test_CannotUpdateDailyClaimAmountAsNonOwner() public {
        vm.prank(user1);
        vm.expectRevert();
        ubi.setDailyClaimAmount(200 * 10**18);
    }

    function test_EmitsClaimedEvent() public {
        vm.prank(owner);
        ubi.verifyUser(user1);

        uint256 currentDay = ubi.getCurrentDay();

        vm.expectEmit(true, true, true, true);
        emit SimpleUBI.Claimed(user1, DAILY_AMOUNT, currentDay);

        vm.prank(user1);
        ubi.claim(user1);
    }

    function test_EmitsVerificationEvent() public {
        vm.expectEmit(true, true, true, true);
        emit SimpleUBI.VerificationStatusChanged(user1, true);

        vm.prank(owner);
        ubi.verifyUser(user1);
    }
}
