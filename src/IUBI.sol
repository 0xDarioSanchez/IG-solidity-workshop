// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

/// @title IUBI - Universal Basic Income Interface
/// @notice Interface for UBI contract functionality
interface IUBI {
    /// @notice Claim daily UBI tokens
    /// @param to The address to receive the tokens
    function claim(address to) external;

    /// @notice Check if a user is verified
    /// @param user The address to check
    /// @return True if the user is verified
    function isVerified(address user) external view returns (bool);

    /// @notice Check if a user can claim today
    /// @param user The address to check
    /// @return True if the user is authorized to claim
    function canClaim(address user) external view returns (bool);
}
