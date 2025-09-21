// SPDX-License-Identifier: MIT
pragma solidity ^0.8.25;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import {ContractRegistry} from "@flarenetwork/flare-periphery-contracts/coston2/ContractRegistry.sol";
import {IAssetManager} from "@flarenetwork/flare-periphery-contracts/coston2/IAssetManager.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
// Interface for FTSO V2 Feed Consumer  
interface IFtsoV2FeedConsumer {
    function getFeedById(bytes21 feedId) external view returns (uint256 value, uint64 timestamp, uint8 decimals);
}

// Interface for FDC Verification (simplified for demo)
interface IFdcVerification {
    function verifyProof(bytes calldata proof) external view returns (bool);
}

// Interface for XRPL Payment Verification (simplified for demo)
interface IXRPLPaymentVerification {
    function verifyPayment(
        bytes32 transactionId,
        address sourceAddress,
        address destinationAddress,
        uint256 amount,
        bytes32 paymentReference
    ) external view returns (bool);
}

/**
 * @title FTG Cross-Chain Travel Vault
 * @dev Enhanced travel savings with XRPL integration, FAssets, Smart Accounts, and Flare Oracles
 * @notice Connects XRPL payments with Flare smart contracts for programmable travel liquidity
 */
contract FTG_CrossChainTravelVault is ReentrancyGuard {
    
    // ============== EVENTS ==============
    event VaultCreated(uint256 indexed vaultId, address creator, string destination, uint256 targetAmount);
    event MemberJoined(uint256 indexed vaultId, address member, address xrplAddress);
    event FlareContribution(uint256 indexed vaultId, address contributor, uint256 amount);
    event XRPLContribution(uint256 indexed vaultId, address contributor, uint256 xrpAmount, bytes32 txHash);
    event FAssetsMinted(uint256 indexed vaultId, uint256 fxrpAmount, uint256 lots);
    event FAssetsRedeemed(uint256 indexed vaultId, uint256 fxrpAmount, string xrplDestination);
    event CrossChainTransfer(uint256 indexed vaultId, address recipient, uint256 amount, string xrplAddress);
    event FundsReleased(uint256 indexed vaultId, uint256 flareAmount, uint256 fxrpAmount, string reason);
    event SmartAccountAction(uint256 indexed vaultId, address smartAccount, string action);
    event PriceTriggerSet(uint256 indexed vaultId, bytes21 feedId, uint256 triggerPrice, bool isLowerBound);
    
    // ============== NEW XRP CONVERSION EVENTS ==============
    event XRPToFlareConversion(
        address indexed sender,
        uint256 xrpAmount,
        uint256 usdValue,
        uint256 flareEquivalent,
        uint256 xrpPriceUSD,
        uint256 flarePriceUSD,
        uint256 timestamp
    );
    event XRPReceived(
        address indexed from,
        uint256 xrpAmount,
        string xrpTxHash,
        uint256 blockNumber
    );
    
    // ============== STRUCTS ==============
    struct CrossChainTravelVault {
        string destination;
        uint256 targetAmountFlare;  // Target in FLR/ETH
        uint256 targetAmountXRP;    // Target in XRP
        uint256 currentAmountFlare; // Current FLR/ETH balance
        uint256 currentAmountFXRP;  // Current FXRP balance
        uint256 deadline;
        address creator;
        address[] members;
        address[] xrplAddresses;    // Corresponding XRPL addresses for members
        mapping(address => uint256) flareContributions;
        mapping(address => uint256) xrpContributions;
        mapping(address => bool) isMember;
        mapping(address => address) memberToXRPL; // Member -> XRPL address mapping
        bool isActive;
        bool fundsReleased;
        
        // FAssets Integration
        bool fAssetsEnabled;
        uint256 fxrpLots;           // FXRP lots for FAssets
        
        // Smart Account Integration
        address smartAccount;       // Delegated smart account for automation
        bool smartAccountEnabled;
        
        // Price trigger settings (Flare Oracles)
        bytes21 priceFeedId;        // FTSO feed ID (e.g., XRP/USD, ETH/USD)
        uint256 triggerPrice;       // Price that triggers release
        bool isLowerBound;          // true = release when price goes below, false = above
        bool priceTriggersEnabled;
        
        // Cross-chain verification
        bytes32[] xrplTransactions; // Verified XRPL transaction hashes
        
        // Governance
        uint256 requiredApprovals;
        mapping(address => bool) hasApproved;
        uint256 currentApprovals;
    }
    
    // ============== STATE VARIABLES ==============
    IFtsoV2FeedConsumer public ftsoConsumer;
    IFdcVerification public fdcVerification;
    IXRPLPaymentVerification public xrplVerification;
    
    mapping(uint256 => CrossChainTravelVault) public vaults;
    uint256 public nextVaultId;
    
    // Flare FTSO Feed IDs
    bytes21 public constant ETH_USD_FEED = 0x014554482f55534400000000000000000000000000;
    bytes21 public constant XRP_USD_FEED = 0x015852502f55534400000000000000000000000000;
    bytes21 public constant FLR_USD_FEED = 0x01464c522f55534400000000000000000000000000;
    
    // FAssets Contract Addresses (for demo - can be zero)
    address public fxrpToken;
    IAssetManager public fxrpAssetManager;
    
    // ============== CONSTRUCTOR ==============
    constructor(
        address _ftsoConsumer,
        address _fdcVerification,
        address _xrplVerification
    ) {
        ftsoConsumer = IFtsoV2FeedConsumer(_ftsoConsumer);
        fdcVerification = IFdcVerification(_fdcVerification);
        xrplVerification = IXRPLPaymentVerification(_xrplVerification);
        nextVaultId = 1;
        
        // Initialize FAssets (simplified for demo compatibility)
        // In production, these would be properly initialized
        fxrpAssetManager = IAssetManager(address(0));
        fxrpToken = address(0);
    }
    
    // ============== MODIFIERS ==============
    modifier onlyVaultMember(uint256 vaultId) {
        require(vaults[vaultId].isMember[msg.sender], "Not a vault member");
        _;
    }
    
    modifier onlyActiveVault(uint256 vaultId) {
        require(vaults[vaultId].isActive, "Vault is not active");
        _;
    }
    
    modifier onlySmartAccount(uint256 vaultId) {
        require(msg.sender == vaults[vaultId].smartAccount, "Only smart account");
        _;
    }
    
    // ============== CORE FUNCTIONS ==============
    
    /**
     * @dev Create a cross-chain travel vault with XRPL and FAssets integration
     * @param destination Travel destination name
     * @param targetAmountFlare Target savings in FLR/ETH (wei)
     * @param targetAmountXRP Target savings in XRP (drops)
     * @param deadline Unix timestamp deadline
     * @param xrplAddress Creator's XRPL address
     * @param enableFAssets Whether to enable FAssets minting/redemption
     * @param priceFeedId FTSO feed ID for price triggers
     * @param triggerPrice Price that triggers fund release
     * @param isLowerBound Whether trigger activates when price goes below (true) or above (false)
     */
    function createCrossChainVault(
        string memory destination,
        uint256 targetAmountFlare,
        uint256 targetAmountXRP,
        uint256 deadline,
        address xrplAddress,
        bool enableFAssets,
        bytes21 priceFeedId,
        uint256 triggerPrice,
        bool isLowerBound
    ) external payable returns (uint256 vaultId) {
        require(targetAmountFlare > 0 || targetAmountXRP > 0, "Must have target amount");
        require(deadline > block.timestamp, "Deadline must be in future");
        require(xrplAddress != address(0), "Invalid XRPL address");
        
        vaultId = nextVaultId++;
        CrossChainTravelVault storage vault = vaults[vaultId];
        
        vault.destination = destination;
        vault.targetAmountFlare = targetAmountFlare;
        vault.targetAmountXRP = targetAmountXRP;
        vault.deadline = deadline;
        vault.creator = msg.sender;
        vault.isActive = true;
        vault.requiredApprovals = 1;
        vault.fAssetsEnabled = enableFAssets;
        
        // Set price trigger if provided
        if (priceFeedId != bytes21(0) && triggerPrice > 0) {
            vault.priceFeedId = priceFeedId;
            vault.triggerPrice = triggerPrice;
            vault.isLowerBound = isLowerBound;
            vault.priceTriggersEnabled = true;
            emit PriceTriggerSet(vaultId, priceFeedId, triggerPrice, isLowerBound);
        }
        
        // Add creator as first member with XRPL address
        vault.members.push(msg.sender);
        vault.xrplAddresses.push(xrplAddress);
        vault.isMember[msg.sender] = true;
        vault.memberToXRPL[msg.sender] = xrplAddress;
        
        // Initial Flare contribution if sent
        if (msg.value > 0) {
            vault.flareContributions[msg.sender] = msg.value;
            vault.currentAmountFlare = msg.value;
            emit FlareContribution(vaultId, msg.sender, msg.value);
        }
        
        emit VaultCreated(vaultId, msg.sender, destination, targetAmountFlare);
        emit MemberJoined(vaultId, msg.sender, xrplAddress);
    }
    
    /**
     * @dev Join a vault with both Flare and XRPL address
     */
    function joinCrossChainVault(
        uint256 vaultId,
        address xrplAddress
    ) external payable onlyActiveVault(vaultId) {
        CrossChainTravelVault storage vault = vaults[vaultId];
        require(!vault.isMember[msg.sender], "Already a member");
        require(block.timestamp < vault.deadline, "Vault deadline passed");
        require(xrplAddress != address(0), "Invalid XRPL address");
        
        vault.members.push(msg.sender);
        vault.xrplAddresses.push(xrplAddress);
        vault.isMember[msg.sender] = true;
        vault.memberToXRPL[msg.sender] = xrplAddress;
        
        // Update required approvals (75% of members)
        vault.requiredApprovals = (vault.members.length * 75) / 100;
        if (vault.requiredApprovals == 0) vault.requiredApprovals = 1;
        
        // Flare contribution if sent
        if (msg.value > 0) {
            vault.flareContributions[msg.sender] += msg.value;
            vault.currentAmountFlare += msg.value;
            emit FlareContribution(vaultId, msg.sender, msg.value);
        }
        
        emit MemberJoined(vaultId, msg.sender, xrplAddress);
    }
    
    /**
     * @dev Contribute Flare-native tokens (FLR/ETH)
     */
    function contributeFlare(uint256 vaultId) external payable onlyVaultMember(vaultId) onlyActiveVault(vaultId) {
        require(msg.value > 0, "Must send tokens");
        require(block.timestamp < vaults[vaultId].deadline, "Vault deadline passed");
        
        CrossChainTravelVault storage vault = vaults[vaultId];
        vault.flareContributions[msg.sender] += msg.value;
        vault.currentAmountFlare += msg.value;
        
        emit FlareContribution(vaultId, msg.sender, msg.value);
        
        // Auto-convert to FAssets if enabled and enough funds
        if (vault.fAssetsEnabled && vault.currentAmountFlare >= _getMinimumForFAssets()) {
            _mintFAssets(vaultId);
        }
        
        _checkAutoRelease(vaultId);
    }
    
    /**
     * @dev Verify and credit XRPL payment using FDC
     * @param vaultId The vault ID
     * @param xrplTxHash XRPL transaction hash
     * @param amount XRP amount in drops
     * @param paymentReference Payment reference for verification
     */
    function verifyXRPLContribution(
        uint256 vaultId,
        bytes32 xrplTxHash,
        uint256 amount,
        bytes32 paymentReference
    ) external onlyVaultMember(vaultId) onlyActiveVault(vaultId) {
        CrossChainTravelVault storage vault = vaults[vaultId];
        require(block.timestamp < vault.deadline, "Vault deadline passed");
        
        // Verify XRPL payment through FDC (simplified for demo)
        address memberXRPL = vault.memberToXRPL[msg.sender];
        bool verified = true; // In production, this would call xrplVerification.verifyPayment()
        
        // For demo: simulate verification logic
        require(memberXRPL != address(0), "Member XRPL address not set");
        require(amount > 0, "Invalid amount");
        
        require(verified, "XRPL payment verification failed");
        
        // Credit the contribution
        vault.xrpContributions[msg.sender] += amount;
        vault.xrplTransactions.push(xrplTxHash);
        
        emit XRPLContribution(vaultId, msg.sender, amount, xrplTxHash);
        
        _checkAutoRelease(vaultId);
    }
    
    /**
     * @dev Mint FAssets (FXRP) from XRP collateral
     * @param vaultId The vault ID
     * @param lots Number of lots to mint
     */
    function mintFAssets(uint256 vaultId, uint256 lots) external onlyVaultMember(vaultId) onlyActiveVault(vaultId) {
        CrossChainTravelVault storage vault = vaults[vaultId];
        require(vault.fAssetsEnabled, "FAssets not enabled for this vault");
        
        // Execute FAssets minting (this would interact with real FAssets system)
        uint256 fxrpAmount = _executeFAssetsMinting(lots);
        
        vault.currentAmountFXRP += fxrpAmount;
        vault.fxrpLots += lots;
        
        emit FAssetsMinted(vaultId, fxrpAmount, lots);
    }
    
    /**
     * @dev Redeem FAssets back to XRP
     * @param vaultId The vault ID
     * @param lots Number of lots to redeem
     * @param xrplDestination XRPL address to receive XRP
     */
    function redeemFAssets(
        uint256 vaultId,
        uint256 lots,
        string memory xrplDestination
    ) external onlyVaultMember(vaultId) {
        CrossChainTravelVault storage vault = vaults[vaultId];
        require(vault.fAssetsEnabled, "FAssets not enabled");
        require(vault.fxrpLots >= lots, "Insufficient FXRP lots");
        
        uint256 fxrpAmount = _executeFAssetsRedemption(lots, xrplDestination);
        
        vault.currentAmountFXRP -= fxrpAmount;
        vault.fxrpLots -= lots;
        
        emit FAssetsRedeemed(vaultId, fxrpAmount, xrplDestination);
    }
    
    /**
     * @dev Set up smart account for automated vault management
     * @param vaultId The vault ID
     * @param smartAccount Address of the smart account
     */
    function setupSmartAccount(uint256 vaultId, address smartAccount) external onlyVaultMember(vaultId) {
        CrossChainTravelVault storage vault = vaults[vaultId];
        require(smartAccount != address(0), "Invalid smart account");
        
        // This would integrate with Flare's smart account system
        vault.smartAccount = smartAccount;
        vault.smartAccountEnabled = true;
        
        emit SmartAccountAction(vaultId, smartAccount, "Setup");
    }
    
    /**
     * @dev Smart account automated action (price-based rebalancing, etc.)
     * @param vaultId The vault ID
     * @param action Action to perform
     */
    function executeSmartAccountAction(
        uint256 vaultId,
        string memory action
    ) external onlySmartAccount(vaultId) {
        CrossChainTravelVault storage vault = vaults[vaultId];
        
        // Smart account can perform automated actions like:
        // - Rebalancing between Flare and XRPL assets
        // - Converting to FAssets when optimal
        // - Price-triggered releases
        
        if (keccak256(bytes(action)) == keccak256(bytes("rebalance"))) {
            _rebalanceAssets(vaultId);
        } else if (keccak256(bytes(action)) == keccak256(bytes("convert_to_fassets"))) {
            _mintFAssets(vaultId);
        }
        
        emit SmartAccountAction(vaultId, vault.smartAccount, action);
    }
    
    /**
     * @dev Check cross-chain price triggers using Flare oracles
     * @param vaultId The vault ID
     */
    function checkCrossChainPriceTrigger(uint256 vaultId) public view returns (bool shouldRelease, uint256 currentPrice) {
        CrossChainTravelVault storage vault = vaults[vaultId];
        
        if (!vault.priceTriggersEnabled || !vault.isActive || vault.fundsReleased) {
            return (false, 0);
        }
        
        // Get current price from FTSO (simulated for demo)
        currentPrice = 600000000000000000; // Simulated $0.60 price
        
        // In production: (currentPrice, , ) = ftsoConsumer.getFeedById(vault.priceFeedId);
        
        if (vault.isLowerBound) {
            shouldRelease = currentPrice <= vault.triggerPrice;
        } else {
            shouldRelease = currentPrice >= vault.triggerPrice;
        }
    }
    
    /**
     * @dev Release funds with cross-chain distribution
     * @param vaultId The vault ID
     * @param reason Reason for release
     */
    function releaseCrossChainFunds(uint256 vaultId, string memory reason) external onlyActiveVault(vaultId) nonReentrant {
        CrossChainTravelVault storage vault = vaults[vaultId];
        require(!vault.fundsReleased, "Funds already released");
        
        // Check if release conditions are met
        bool canRelease = false;
        
        // Check price triggers
        if (vault.priceTriggersEnabled) {
            (bool shouldRelease, ) = checkCrossChainPriceTrigger(vaultId);
            canRelease = shouldRelease;
        }
        
        // Check governance approval
        if (vault.currentApprovals >= vault.requiredApprovals) {
            canRelease = true;
        }
        
        // Check if targets reached
        bool flareTargetReached = vault.currentAmountFlare >= vault.targetAmountFlare;
        bool xrpTargetReached = vault.currentAmountFXRP > 0 || _getTotalXRPContributions(vaultId) >= vault.targetAmountXRP;
        
        if (flareTargetReached && (vault.targetAmountXRP == 0 || xrpTargetReached)) {
            canRelease = true;
        }
        
        require(canRelease, "Release conditions not met");
        
        vault.fundsReleased = true;
        vault.isActive = false;
        
        // Distribute funds proportionally across both chains
        _distributeCrossChainFunds(vaultId);
        
        emit FundsReleased(vaultId, vault.currentAmountFlare, vault.currentAmountFXRP, reason);
    }
    
    // ============== XRP TO FLARE CONVERSION FUNCTIONS ==============
    
    /**
     * @dev Simulate XRP to Flare conversion with USD pricing
     * @param xrpAmount Amount of XRP being converted (in drops - 1 XRP = 1,000,000 drops)
     * @param xrpTxHash XRPL transaction hash for tracking
     * @return usdValue USD value of the XRP
     * @return flareEquivalent Equivalent amount in Flare tokens
     */
    function convertXRPToFlare(
        uint256 xrpAmount,
        string memory xrpTxHash
    ) external payable returns (uint256 usdValue, uint256 flareEquivalent) {
        require(xrpAmount > 0, "XRP amount must be greater than 0");
        
        // Get current prices from simulated FTSO (in production, this would use real oracles)
        uint256 xrpPriceUSD = _getXRPPriceUSD(); // Price in USD with 8 decimals
        uint256 flarePriceUSD = _getFlarePriceUSD(); // Price in USD with 8 decimals
        
        // Convert XRP drops to XRP (1 XRP = 1,000,000 drops)
        uint256 xrpInTokens = xrpAmount / 1000000;
        
        // Calculate USD value: XRP amount * XRP price
        usdValue = (xrpInTokens * xrpPriceUSD) / 100000000; // Adjust for 8 decimals
        
        // Calculate Flare equivalent: USD value / Flare price
        flareEquivalent = (usdValue * 100000000) / flarePriceUSD; // Convert back to wei
        flareEquivalent = flareEquivalent * 1 ether / 100000000; // Adjust to 18 decimals
        
        // Emit events for tracking
        emit XRPReceived(
            msg.sender,
            xrpAmount,
            xrpTxHash,
            block.number
        );
        
        emit XRPToFlareConversion(
            msg.sender,
            xrpAmount,
            usdValue,
            flareEquivalent,
            xrpPriceUSD,
            flarePriceUSD,
            block.timestamp
        );
        
        return (usdValue, flareEquivalent);
    }
    
    /**
     * @dev Batch XRP to Flare conversion for multiple transactions
     * @param xrpAmounts Array of XRP amounts
     * @param xrpTxHashes Array of corresponding XRPL transaction hashes
     */
    function batchConvertXRPToFlare(
        uint256[] memory xrpAmounts,
        string[] memory xrpTxHashes
    ) external returns (uint256 totalUsdValue, uint256 totalFlareEquivalent) {
        require(xrpAmounts.length == xrpTxHashes.length, "Arrays length mismatch");
        require(xrpAmounts.length > 0, "No transactions provided");
        
        for (uint256 i = 0; i < xrpAmounts.length; i++) {
            (uint256 usdValue, uint256 flareEquivalent) = this.convertXRPToFlare(
                xrpAmounts[i],
                xrpTxHashes[i]
            );
            totalUsdValue += usdValue;
            totalFlareEquivalent += flareEquivalent;
        }
        
        return (totalUsdValue, totalFlareEquivalent);
    }
    
    /**
     * @dev Get current XRP price in USD (simulated)
     * @return price XRP price in USD with 8 decimals (e.g., 62000000 = $0.62)
     */
    function _getXRPPriceUSD() internal pure returns (uint256) {
        // Simulated XRP price: $0.62 USD
        return 62000000; // 8 decimals
    }
    
    /**
     * @dev Get current Flare price in USD (simulated)
     * @return price Flare price in USD with 8 decimals (e.g., 4500000 = $0.045)
     */
    function _getFlarePriceUSD() internal pure returns (uint256) {
        // Simulated Flare price: $0.045 USD
        return 4500000; // 8 decimals
    }
    
    /**
     * @dev Get conversion rate from XRP to Flare
     * @return rate How many Flare tokens per XRP
     */
    function getXRPToFlareRate() external pure returns (uint256 rate) {
        uint256 xrpPrice = 62000000; // $0.62
        uint256 flarePrice = 4500000; // $0.045
        
        // Rate = XRP price / Flare price
        rate = (xrpPrice * 1 ether) / flarePrice; // Convert to 18 decimals
        return rate;
    }
    
    // ============== INTERNAL FUNCTIONS ==============
    
    function _mintFAssets(uint256 vaultId) internal {
        // This would interact with the real FAssets system
        // For demo purposes, we'll simulate the process
        CrossChainTravelVault storage vault = vaults[vaultId];
        
        if (vault.currentAmountFlare >= 1 ether) {
            uint256 lots = vault.currentAmountFlare / 1 ether; // Simple calculation
            uint256 fxrpAmount = lots * 1000; // Simulated FXRP amount
            
            vault.currentAmountFXRP += fxrpAmount;
            vault.fxrpLots += lots;
            
            emit FAssetsMinted(vaultId, fxrpAmount, lots);
        }
    }
    
    function _executeFAssetsMinting(uint256 lots) internal returns (uint256) {
        // In real implementation, this would call FAssets minting
        return lots * 1000; // Simulated FXRP amount
    }
    
    function _executeFAssetsRedemption(uint256 lots, string memory xrplDestination) internal returns (uint256) {
        // In real implementation, this would call FAssets redemption
        return lots * 1000; // Simulated FXRP amount
    }
    
    function _rebalanceAssets(uint256 vaultId) internal {
        // Smart contract automated rebalancing logic
        CrossChainTravelVault storage vault = vaults[vaultId];
        
        // Example: Convert excess Flare tokens to FAssets when XRP price is favorable
        (uint256 xrpPrice, , ) = ftsoConsumer.getFeedById(XRP_USD_FEED);
        
        if (xrpPrice > vault.triggerPrice && vault.fAssetsEnabled) {
            _mintFAssets(vaultId);
        }
    }
    
    function _distributeCrossChainFunds(uint256 vaultId) internal {
        CrossChainTravelVault storage vault = vaults[vaultId];
        
        // Distribute Flare tokens
        uint256 totalFlare = vault.currentAmountFlare;
        for (uint256 i = 0; i < vault.members.length; i++) {
            address member = vault.members[i];
            uint256 flareShare = vault.flareContributions[member];
            
            if (flareShare > 0) {
                vault.flareContributions[member] = 0;
                payable(member).transfer(flareShare);
            }
        }
        
        // Distribute FXRP tokens (if available)
        if (vault.currentAmountFXRP > 0 && fxrpToken != address(0)) {
            IERC20(fxrpToken).transfer(vault.creator, vault.currentAmountFXRP);
        }
    }
    
    function _getMinimumForFAssets() internal pure returns (uint256) {
        return 1 ether; // Minimum amount needed for FAssets operations
    }
    
    function _getTotalXRPContributions(uint256 vaultId) internal view returns (uint256) {
        CrossChainTravelVault storage vault = vaults[vaultId];
        uint256 total = 0;
        
        for (uint256 i = 0; i < vault.members.length; i++) {
            total += vault.xrpContributions[vault.members[i]];
        }
        
        return total;
    }
    
    function _checkAutoRelease(uint256 vaultId) internal {
        CrossChainTravelVault storage vault = vaults[vaultId];
        
        // Check if both targets reached
        bool flareTargetReached = vault.currentAmountFlare >= vault.targetAmountFlare;
        bool xrpTargetReached = _getTotalXRPContributions(vaultId) >= vault.targetAmountXRP;
        
        if (flareTargetReached && (vault.targetAmountXRP == 0 || xrpTargetReached)) {
            if (vault.priceTriggersEnabled) {
                (bool shouldRelease, ) = checkCrossChainPriceTrigger(vaultId);
                if (shouldRelease) {
                    vault.fundsReleased = true;
                    vault.isActive = false;
                    _distributeCrossChainFunds(vaultId);
                    emit FundsReleased(vaultId, vault.currentAmountFlare, vault.currentAmountFXRP, "Auto-release: targets + price trigger");
                }
            } else {
                vault.fundsReleased = true;
                vault.isActive = false;
                _distributeCrossChainFunds(vaultId);
                emit FundsReleased(vaultId, vault.currentAmountFlare, vault.currentAmountFXRP, "Auto-release: targets reached");
            }
        }
    }
    
    // ============== VIEW FUNCTIONS ==============
    
    function getCrossChainVaultInfo(uint256 vaultId) external view returns (
        string memory destination,
        uint256 targetAmountFlare,
        uint256 targetAmountXRP,
        uint256 currentAmountFlare,
        uint256 currentAmountFXRP,
        uint256 deadline,
        address creator,
        bool isActive,
        bool fundsReleased,
        uint256 memberCount,
        bool fAssetsEnabled,
        bool smartAccountEnabled
    ) {
        CrossChainTravelVault storage vault = vaults[vaultId];
        return (
            vault.destination,
            vault.targetAmountFlare,
            vault.targetAmountXRP,
            vault.currentAmountFlare,
            vault.currentAmountFXRP,
            vault.deadline,
            vault.creator,
            vault.isActive,
            vault.fundsReleased,
            vault.members.length,
            vault.fAssetsEnabled,
            vault.smartAccountEnabled
        );
    }
    
    function getMemberXRPLAddress(uint256 vaultId, address member) external view returns (address) {
        return vaults[vaultId].memberToXRPL[member];
    }
    
    function getXRPLTransactions(uint256 vaultId) external view returns (bytes32[] memory) {
        return vaults[vaultId].xrplTransactions;
    }
    
    function getFAssetsBalance(uint256 vaultId) external view returns (uint256 fxrpAmount, uint256 lots) {
        CrossChainTravelVault storage vault = vaults[vaultId];
        return (vault.currentAmountFXRP, vault.fxrpLots);
    }
}
