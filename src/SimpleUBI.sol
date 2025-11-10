// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;
import {LibUBI, UBIStorage} from "./LibUBI.sol";
import {IUBI} from "./IUBI.sol";
import {Initializable} from "@openzeppelin/contracts/proxy/utils/Initializable.sol";
import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";

/// @title SimpleUBI - Universal Basic Income Token
/// @notice This contract implements a UBI system that mints tokens daily to verified users
/// @dev Users must be verified and can claim once per day
contract SimpleUBI is ERC20, Ownable, IUBI {
    using LibUBI for UBIStorage;

    /// @notice Daily claim amount in tokens (with decimals)
    uint256 public dailyClaimAmount;

    /// @notice Emitted when a user successfully claims their daily UBI
    event Claimed(address indexed user, uint256 amount, uint256 day);
    
    /// @notice Emitted when a user's verification status changes
    event VerificationStatusChanged(address indexed user, bool status);

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor(
        string memory name,
        string memory symbol,
        uint256 _dailyClaimAmount,
        address initialOwner
    ) ERC20(name, symbol) Ownable(initialOwner) {
        require(_dailyClaimAmount > 0, "Daily claim amount must be positive");
        dailyClaimAmount = _dailyClaimAmount;
        
        // Initialize storage
        UBIStorage storage s = LibUBI.getStorage();
        s.claimAmount = _dailyClaimAmount;
    }

    /// @notice Verify a user to allow them to claim UBI
    /// @param user The address to verify
    function verifyUser(address user) external onlyOwner {
        UBIStorage storage s = LibUBI.getStorage();
        LibUBI.setVerified(s, user, true);
        emit VerificationStatusChanged(user, true);
    }

    /// @notice Remove verification from a user
    /// @param user The address to unverify
    function unverifyUser(address user) external onlyOwner {
        UBIStorage storage s = LibUBI.getStorage();
        LibUBI.setVerified(s, user, false);
        emit VerificationStatusChanged(user, false);
    }

    /// @notice Claim daily UBI tokens
    /// @param to The address to receive the tokens
    function claim(address to) external override {
        UBIStorage storage s = LibUBI.getStorage();
        
        // Process the claim (checks verification and daily limit)
        uint256 amount = LibUBI.processClaim(s, msg.sender);
        
        // Mint tokens to the recipient
        _mint(to, amount);
        
        emit Claimed(msg.sender, amount, LibUBI.getCurrentDay());
    }

    /// @notice Check if a user is verified
    /// @param user The address to check
    /// @return True if the user is verified
    function isVerified(address user) external view returns (bool) {
        UBIStorage storage s = LibUBI.getStorage();
        return LibUBI.isVerified(s, user);
    }

    /// @notice Check if a user can claim today
    /// @param user The address to check
    /// @return True if the user is authorized to claim
    function canClaim(address user) external view returns (bool) {
        UBIStorage storage s = LibUBI.getStorage();
        return LibUBI.isAuthorizedToClaim(s, user);
    }

    /// @notice Get the last day a user claimed
    /// @param user The address to check
    /// @return The day number of the last claim (0 if never claimed)
    function getLastClaimDay(address user) external view returns (uint256) {
        UBIStorage storage s = LibUBI.getStorage();
        // lastClaim stores day+1, so subtract 1 to get actual day (0 if never claimed)
        return s.lastClaim[user] > 0 ? s.lastClaim[user] - 1 : 0;
    }

    /// @notice Get the current day number
    /// @return The current day since Unix epoch
    function getCurrentDay() external view returns (uint256) {
        return LibUBI.getCurrentDay();
    }

    /// @notice Update the daily claim amount
    /// @param newAmount The new daily claim amount
    function setDailyClaimAmount(uint256 newAmount) external onlyOwner {
        require(newAmount > 0, "Amount must be positive");
        dailyClaimAmount = newAmount;
        
        UBIStorage storage s = LibUBI.getStorage();
        s.claimAmount = newAmount;
    }
}
