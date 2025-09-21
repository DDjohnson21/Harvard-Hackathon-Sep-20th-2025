// SPDX-License-Identifier: MIT
pragma solidity ^0.8.25;

/**
 * @title XRP to Flare Converter
 * @dev Simulates XRP to Flare conversion with USD pricing and on-chain events
 * @notice Demonstrates: Send XRP → Flare Contract → USD Equivalent + Events
 */
contract XRPToFlareConverter {
    
    // ============== EVENTS ==============
    event XRPReceived(
        address indexed from,
        uint256 xrpAmount,
        string xrpTxHash,
        uint256 blockNumber
    );
    
    event XRPToFlareConversion(
        address indexed sender,
        uint256 xrpAmount,
        uint256 usdValue,
        uint256 flareEquivalent,
        uint256 xrpPriceUSD,
        uint256 flarePriceUSD,
        uint256 timestamp
    );
    
    event BatchConversion(
        address indexed sender,
        uint256 totalXRP,
        uint256 totalUSD,
        uint256 totalFlare,
        uint256 transactionCount
    );
    
    // ============== STATE VARIABLES ==============
    uint256 public totalXRPProcessed;
    uint256 public totalUSDConverted;
    uint256 public totalFlareGenerated;
    uint256 public conversionCount;
    
    mapping(string => bool) public processedXRPLTxHashes;
    mapping(address => uint256) public userXRPContributions;
    mapping(address => uint256) public userUSDValue;
    mapping(address => uint256) public userFlareEquivalent;
    
    // ============== MAIN CONVERSION FUNCTION ==============
    
    /**
     * @dev Convert XRP to Flare with USD pricing
     * @param xrpAmount Amount of XRP in drops (1 XRP = 1,000,000 drops)
     * @param xrpTxHash XRPL transaction hash for tracking
     * @return usdValue USD value of the XRP
     * @return flareEquivalent Equivalent amount in Flare tokens
     */
    function convertXRPToFlare(
        uint256 xrpAmount,
        string memory xrpTxHash
    ) external returns (uint256 usdValue, uint256 flareEquivalent) {
        require(xrpAmount > 0, "XRP amount must be greater than 0");
        require(!processedXRPLTxHashes[xrpTxHash], "XRPL transaction already processed");
        
        // Mark transaction as processed
        processedXRPLTxHashes[xrpTxHash] = true;
        
        // Get current prices (simulated FTSO data)
        uint256 xrpPriceUSD = getXRPPriceUSD(); // $0.62 with 8 decimals
        uint256 flarePriceUSD = getFlarePriceUSD(); // $0.045 with 8 decimals
        
        // Convert XRP drops to XRP tokens (1 XRP = 1,000,000 drops)
        uint256 xrpInTokens = xrpAmount / 1000000;
        
        // Calculate USD value: XRP amount * XRP price
        usdValue = (xrpInTokens * xrpPriceUSD) / 100000000; // Adjust for 8 decimals
        
        // Calculate Flare equivalent: USD value / Flare price
        flareEquivalent = (usdValue * 100000000) / flarePriceUSD; // Get raw value
        flareEquivalent = flareEquivalent * 1 ether / 100000000; // Convert to 18 decimals
        
        // Update state
        totalXRPProcessed += xrpAmount;
        totalUSDConverted += usdValue;
        totalFlareGenerated += flareEquivalent;
        conversionCount++;
        
        // Update user tracking
        userXRPContributions[msg.sender] += xrpAmount;
        userUSDValue[msg.sender] += usdValue;
        userFlareEquivalent[msg.sender] += flareEquivalent;
        
        // Emit events
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
    
    // ============== BATCH CONVERSION ==============
    
    /**
     * @dev Process multiple XRP transactions in a single call
     * @param xrpAmounts Array of XRP amounts in drops
     * @param xrpTxHashes Array of XRPL transaction hashes
     * @return totalUsdValue Total USD value converted
     * @return totalFlareEquivalent Total Flare equivalent generated
     */
    function batchConvertXRPToFlare(
        uint256[] memory xrpAmounts,
        string[] memory xrpTxHashes
    ) external returns (uint256 totalUsdValue, uint256 totalFlareEquivalent) {
        require(xrpAmounts.length == xrpTxHashes.length, "Arrays length mismatch");
        require(xrpAmounts.length > 0, "No transactions provided");
        require(xrpAmounts.length <= 10, "Maximum 10 transactions per batch");
        
        uint256 totalXRP = 0;
        
        for (uint256 i = 0; i < xrpAmounts.length; i++) {
            // Process each transaction in the batch
            uint256 xrpAmount = xrpAmounts[i];
            string memory xrpTxHash = xrpTxHashes[i];
            
            require(xrpAmount > 0, "XRP amount must be greater than 0");
            require(!processedXRPLTxHashes[xrpTxHash], "XRPL transaction already processed");
            
            // Mark transaction as processed
            processedXRPLTxHashes[xrpTxHash] = true;
            
            // Get current prices
            uint256 xrpPriceUSD = getXRPPriceUSD();
            uint256 flarePriceUSD = getFlarePriceUSD();
            
            // Calculate conversions
            uint256 xrpInTokens = xrpAmount / 1000000;
            uint256 usdValue = (xrpInTokens * xrpPriceUSD) / 100000000;
            uint256 flareEquivalent = (usdValue * 100000000) / flarePriceUSD;
            flareEquivalent = flareEquivalent * 1 ether / 100000000;
            
            // Update totals
            totalUsdValue += usdValue;
            totalFlareEquivalent += flareEquivalent;
            totalXRP += xrpAmount;
            
            // Update state
            totalXRPProcessed += xrpAmount;
            totalUSDConverted += usdValue;
            totalFlareGenerated += flareEquivalent;
            conversionCount++;
            
            // Update user tracking
            userXRPContributions[msg.sender] += xrpAmount;
            userUSDValue[msg.sender] += usdValue;
            userFlareEquivalent[msg.sender] += flareEquivalent;
            
            // Emit events for each transaction
            emit XRPReceived(msg.sender, xrpAmount, xrpTxHash, block.number);
            emit XRPToFlareConversion(msg.sender, xrpAmount, usdValue, flareEquivalent, xrpPriceUSD, flarePriceUSD, block.timestamp);
        }
        
        emit BatchConversion(
            msg.sender,
            totalXRP,
            totalUsdValue,
            totalFlareEquivalent,
            xrpAmounts.length
        );
        
        return (totalUsdValue, totalFlareEquivalent);
    }
    
    // ============== PRICE FUNCTIONS ==============
    
    /**
     * @dev Get current XRP price in USD (simulated FTSO)
     * @return price XRP price with 8 decimals (62000000 = $0.62)
     */
    function getXRPPriceUSD() public pure returns (uint256) {
        return 62000000; // $0.62 USD with 8 decimals
    }
    
    /**
     * @dev Get current Flare price in USD (simulated FTSO)
     * @return price Flare price with 8 decimals (4500000 = $0.045)
     */
    function getFlarePriceUSD() public pure returns (uint256) {
        return 4500000; // $0.045 USD with 8 decimals
    }
    
    /**
     * @dev Get conversion rate from XRP to Flare
     * @return rate How many Flare tokens per XRP (18 decimals)
     */
    function getXRPToFlareRate() external pure returns (uint256 rate) {
        uint256 xrpPrice = 62000000; // $0.62
        uint256 flarePrice = 4500000; // $0.045
        
        // Rate = XRP price / Flare price, scaled to 18 decimals
        rate = (xrpPrice * 1 ether) / flarePrice;
        return rate;
    }
    
    // ============== VIEW FUNCTIONS ==============
    
    /**
     * @dev Get conversion statistics
     * @return _totalXRP Total XRP processed
     * @return _totalUSD Total USD value converted
     * @return _totalFlare Total Flare equivalent generated
     * @return _conversionCount Number of conversions processed
     */
    function getConversionStats() external view returns (
        uint256 _totalXRP,
        uint256 _totalUSD,
        uint256 _totalFlare,
        uint256 _conversionCount
    ) {
        return (
            totalXRPProcessed,
            totalUSDConverted,
            totalFlareGenerated,
            conversionCount
        );
    }
    
    /**
     * @dev Get user-specific conversion data
     * @param user User address
     * @return xrpContributed XRP contributed by user
     * @return usdValue USD value of user's XRP
     * @return flareEquivalent Flare equivalent for user
     */
    function getUserConversions(address user) external view returns (
        uint256 xrpContributed,
        uint256 usdValue,
        uint256 flareEquivalent
    ) {
        return (
            userXRPContributions[user],
            userUSDValue[user],
            userFlareEquivalent[user]
        );
    }
    
    /**
     * @dev Check if XRPL transaction hash has been processed
     * @param xrpTxHash XRPL transaction hash
     * @return processed Whether the transaction has been processed
     */
    function isXRPLTransactionProcessed(string memory xrpTxHash) external view returns (bool processed) {
        return processedXRPLTxHashes[xrpTxHash];
    }
    
    /**
     * @dev Calculate conversion preview without executing
     * @param xrpAmount XRP amount in drops
     * @return usdValue Estimated USD value
     * @return flareEquivalent Estimated Flare equivalent
     */
    function previewConversion(uint256 xrpAmount) external pure returns (
        uint256 usdValue,
        uint256 flareEquivalent
    ) {
        require(xrpAmount > 0, "XRP amount must be greater than 0");
        
        uint256 xrpPriceUSD = 62000000; // $0.62
        uint256 flarePriceUSD = 4500000; // $0.045
        
        uint256 xrpInTokens = xrpAmount / 1000000;
        usdValue = (xrpInTokens * xrpPriceUSD) / 100000000;
        flareEquivalent = (usdValue * 100000000) / flarePriceUSD;
        flareEquivalent = flareEquivalent * 1 ether / 100000000;
        
        return (usdValue, flareEquivalent);
    }
    
    // ============== UTILITY FUNCTIONS ==============
    
    /**
     * @dev Convert XRP drops to XRP tokens
     * @param drops XRP amount in drops
     * @return tokens XRP amount in tokens
     */
    function dropsToXRP(uint256 drops) external pure returns (uint256 tokens) {
        return drops / 1000000;
    }
    
    /**
     * @dev Convert XRP tokens to drops
     * @param tokens XRP amount in tokens
     * @return drops XRP amount in drops
     */
    function xrpToDrops(uint256 tokens) external pure returns (uint256 drops) {
        return tokens * 1000000;
    }
}
