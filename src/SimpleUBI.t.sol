// SPDX-License-Identifier: MIT
pragma solidity =0.8.28;

import {Test} from "forge-std/Test.sol";
import {SimpleUBI} from "./SimpleUBI.sol";
import {ERC20Impl} from "./ERC20.sol";

contract SimpleUBITest is Test {
    SimpleUBI ubi;
    ERC20Impl token;

    function setUp() public {
        // SimpleUBI constructor: (name, symbol, dailyClaimAmount, initialOwner)
        ubi = new SimpleUBI("UBI Token", "UBI", 1 ether, address(this));
        token = new ERC20Impl("Test Token", "TST", address(this));
    }

    function test_Ownership() public view {
        assertEq(address(ubi.owner()), address(this));
    }
}
