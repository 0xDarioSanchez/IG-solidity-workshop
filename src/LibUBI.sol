// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

struct UBIStorage {
    uint256 claimAmount; // Amount of tokens to mint per day
    uint256 initialClaimValue; // Initial claim value for backward compatibility
    address token; // Address of the ERC20 token (if using external token)
    mapping(address => bool) isVerified; // Verification status
    mapping(address user => uint256 lastClaimDay) lastClaim; // Last day user claimed (0 = never claimed, 1 = day 0, 2 = day 1, etc.)
}

library LibUBI {
    /// @notice Storage slot for the diamond storage pattern using ERC-7201
    bytes32 private constant UBIStorageLocation =
        keccak256(abi.encode(uint256(keccak256("Simple.UBI.storage")) - 1)) &
            ~bytes32(uint256(0xff));

    /// @notice Get current day number (days since Unix epoch)
    function getCurrentDay() internal view returns (uint256) {
        return block.timestamp / 1 days;
    }

    function getStorage() internal pure returns (UBIStorage storage s) {
        bytes32 position = UBIStorageLocation;
        assembly {
            s.slot := position
        }
    }

    function isVerified(UBIStorage storage s, address _address) internal view returns (bool) {
        return s.isVerified[_address];
    }

    function isAuthorizedToClaim(UBIStorage storage s, address user) internal view returns (bool) {
        // User must be verified
        if (!s.isVerified[user]) return false;
        
        // Check if user can claim today (hasn't claimed yet today)
        uint256 today = getCurrentDay();
        // lastClaim stores day+1 (0 means never claimed)
        // So we check if lastClaim is 0 (never claimed) or lastClaim-1 < today (claimed on previous day)
        return s.lastClaim[user] == 0 || (s.lastClaim[user] - 1) < today;
    }

    function processClaim(UBIStorage storage s, address user) internal returns (uint256) {
        require(s.isVerified[user], "User not verified");
        
        uint256 today = getCurrentDay();
        require(s.lastClaim[user] == 0 || (s.lastClaim[user] - 1) < today, "Already claimed today");
        
        // Store day+1 to distinguish between "never claimed" (0) and "claimed on day 0" (1)
        s.lastClaim[user] = today + 1;
        return s.claimAmount > 0 ? s.claimAmount : s.initialClaimValue;
    }

    function setVerified(UBIStorage storage s, address user, bool status) internal {
        s.isVerified[user] = status;
    }
}
