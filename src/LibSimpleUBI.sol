// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

/// @title LibSimpleUBI - Utility Library for UBI Calculations
/// @notice Provides helper functions for time-based UBI operations
library LibSimpleUBI {
    /// @notice Convert timestamp to day number
    /// @param timestamp The timestamp to convert
    /// @return The day number since Unix epoch
    function timestampToDay(uint256 timestamp) internal pure returns (uint256) {
        return timestamp / 1 days;
    }

    /// @notice Get the start timestamp of a given day
    /// @param day The day number
    /// @return The timestamp at the start of that day
    function dayToTimestamp(uint256 day) internal pure returns (uint256) {
        return day * 1 days;
    }

    /// @notice Calculate how many days have passed since last claim
    /// @param lastClaimDay The day of the last claim
    /// @param currentDay The current day
    /// @return The number of days since last claim
    function daysSinceLastClaim(uint256 lastClaimDay, uint256 currentDay) internal pure returns (uint256) {
        if (currentDay <= lastClaimDay) return 0;
        return currentDay - lastClaimDay;
    }

    /// @notice Calculate accumulated UBI for missed days
    /// @param lastClaimDay The day of the last claim
    /// @param currentDay The current day
    /// @param dailyAmount The daily claim amount
    /// @return The total accumulated amount
    function calculateAccumulated(
        uint256 lastClaimDay,
        uint256 currentDay,
        uint256 dailyAmount
    ) internal pure returns (uint256) {
        uint256 missedDays = daysSinceLastClaim(lastClaimDay, currentDay);
        if (missedDays == 0) return 0;
        return missedDays * dailyAmount;
    }
}
