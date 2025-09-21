# XRP to USD Currency Converter ⚡💱🎯

## Harvard Hackathon - September 20th, 2025

A powerful **cross-chain currency conversion platform** that connects **XRPL** with **Flare Network**, enabling real-time XRP to USD conversion through **Flare Oracles**, **FAssets**, and **Smart Contracts**.

---

## 🎯 **What Does This Project Do?**

This system allows users to:

1. **💱 Real-Time XRP to USD Conversion** - Convert XRP to USD using live oracle pricing from Flare Network
2. **🌊 Cross-Chain Bridge** - Seamlessly bridge XRP payments to Flare Network with USD equivalent calculations
3. **⚡ Oracle-Powered Pricing** - Get accurate, real-time exchange rates via Flare's FTSO price feeds
4. **📊 Batch Processing** - Convert multiple XRP transactions efficiently in single operations
5. **🏦 FAssets Integration** - Convert XRP to FXRP tokens for enhanced DeFi liquidity
6. **🔍 Transaction Tracking** - Complete on-chain verification and event logging for all conversions

---

## 🏗️ **How It Works**

### **Core Architecture**

```
XRPL Network  ←→  Flare Network  ←→  USD Conversion
     ↓                  ↓                  ↓
  XRP Payments    Smart Contracts    USD Equivalent
     ↓                  ↓                  ↓
  Verification    Oracle Pricing     Real-Time Rates
```

### **Key Components**

1. **XRPToFlareConverter.sol** - Main contract handling XRP to USD conversion
2. **FTG_CrossChainTravelVault.sol** - Advanced conversion features and batch processing
3. **Demo Scripts** - Live conversion examples and testing scenarios

---

## 🚀 **Step-by-Step Conversion Process**

### **1. Single XRP to USD Conversion**

```solidity
convertXRPToFlare(
    100000000,    // 100 XRP in drops (1 XRP = 1,000,000 drops)
    "xrpl_tx_hash"
)
// Returns: USD value + Flare equivalent
```

### **2. Batch XRP Conversions**

```solidity
batchConvertXRPToFlare(
    [100000000, 250000000, 500000000],  // Multiple XRP amounts
    ["hash1", "hash2", "hash3"]         // Corresponding XRPL tx hashes
)
// Returns: Total USD value + Total Flare equivalent
```

### **3. XRP to USD Conversion Logic**

```
Step 1: XRP Amount (drops) ÷ 1,000,000 = XRP Tokens
Step 2: XRP Tokens × XRP Price (USD) = USD Value
Step 3: USD Value ÷ Flare Price (USD) = Flare Equivalent (optional)
```

### **4. Real-Time Price Feeds**

Oracle-powered pricing via Flare FTSO:

- 📊 **XRP/USD Feed** - Current market price of XRP
- 📊 **FLR/USD Feed** - Current market price of Flare
- ⚡ **Live Updates** - Real-time price synchronization

### **5. Conversion Preview**

Check conversion rates before executing:

```solidity
previewConversion(100000000)  // Preview 100 XRP conversion
// Returns: Estimated USD value and Flare equivalent
```

---

## 💻 **Usage Examples**

### **Deploy and Test**

```bash
# Install dependencies
yarn install

# Compile contracts
npx hardhat compile

# Run XRP conversion demo
yarn hardhat run scripts/XRP_Conversion_Demo.ts --network coston2

# Run full cross-chain demo
yarn hardhat run scripts/XRP_to_Flare_Conversion_Demo.ts --network coston2
```

### **Sample XRP to USD Conversion**

```typescript
// Convert 100 XRP to USD equivalent
const [usdValue, flareEquivalent] = await converter.convertXRPToFlare(
  100000000, // 100 XRP in drops
  "xrpl_transaction_hash"
);

console.log(`100 XRP = $${usdValue} USD`);
console.log(`Flare Equivalent: ${ethers.formatEther(flareEquivalent)} FLR`);
```

**Example Output**:

```
💰 100 XRP × $0.62 = $62.00 USD
⚡ Optional: $62.00 ÷ $0.045 = 1,377.78 FLR
📊 Exchange Rate: 1 XRP = $0.62 USD
```

---

## 🔧 **Technical Features**

### **Oracle Integration**

- **FTSO V2 Feeds** for real-time XRP/USD and FLR/USD pricing
- **Price Triggers** for automated fund releases
- **Cross-chain price verification**

### **FAssets Support**

- **FXRP Minting** from XRP collateral
- **Redemption** back to XRP on XRPL
- **Lot-based** fractional ownership

### **Cross-Chain Verification**

- **FDC (Flare Data Connector)** for XRPL transaction verification
- **XRPL Payment Verification** interface
- **Transaction hash tracking** to prevent double-spending

### **Smart Account Automation**

- **Delegated management** for vault operations
- **Automated rebalancing** based on price conditions
- **Scheduled releases** and maintenance

---

## 📊 **Contract Functions**

### **Core Conversion Operations**

| Function                   | Purpose                              |
| -------------------------- | ------------------------------------ |
| `convertXRPToFlare()`      | Convert single XRP amount to USD     |
| `batchConvertXRPToFlare()` | Convert multiple XRP transactions    |
| `previewConversion()`      | Preview conversion without executing |
| `getXRPToFlareRate()`      | Get current XRP to USD exchange rate |
| `getConversionStats()`     | View total conversion statistics     |

### **Price & Analytics Functions**

| Function                       | Purpose                                |
| ------------------------------ | -------------------------------------- |
| `getXRPPriceUSD()`             | Get current XRP price in USD           |
| `getFlarePriceUSD()`           | Get current Flare price in USD         |
| `getUserConversions()`         | Get user's conversion history          |
| `isXRPLTransactionProcessed()` | Check if transaction already processed |

### **Utility Functions**

| Function               | Purpose                     |
| ---------------------- | --------------------------- |
| `dropsToXRP()`         | Convert XRP drops to tokens |
| `xrpToDrops()`         | Convert XRP tokens to drops |
| `getConversionStats()` | Get platform statistics     |

---

## 🎯 **Demo Scenarios**

### **Scenario 1: Single XRP Conversion**

```
💱 User wants to convert 500 XRP to USD
📡 Calls convertXRPToFlare(500000000, "xrpl_hash")
📊 Oracle fetches: XRP = $0.62, Flare = $0.045
💰 Calculation: 500 × $0.62 = $310 USD
⚡ Optional: $310 ÷ $0.045 = 6,888.89 FLR
📋 Events emitted for tracking and verification
```

### **Scenario 2: Batch Currency Conversion**

```
🔄 User converts multiple XRP transactions
📊 Amounts: [100 XRP, 250 XRP, 500 XRP]
💱 Total: 850 XRP × $0.62 = $527 USD
⚡ Batch processing for gas efficiency
📈 Statistics updated: total conversions, volume
```

### **Scenario 3: Real-Time Price Monitoring**

```
📊 Get current exchange rates
💲 XRP Price: $0.62 USD (via Flare FTSO)
📈 Conversion Rate: 1 XRP = $0.62 USD
🔍 Preview conversion before executing
📱 Live price feed updates every block
```

---

## 🏆 **Key Innovation Points**

### **1. Cross-Chain Currency Bridge**

- First XRP to USD converter leveraging Flare Network oracles
- Real-time oracle-based pricing for accurate conversions
- Seamless XRPL to Flare Network integration

### **2. Oracle-Powered Pricing**

- FTSO V2 integration for live XRP/USD price feeds
- Real-time market data for accurate exchange rates
- Decentralized price verification and transparency

### **3. Efficient Batch Processing**

- Convert multiple XRP transactions in single operation
- Gas-optimized batch conversion functionality
- Comprehensive transaction tracking and analytics

### **4. Comprehensive Analytics**

- Complete conversion history and statistics
- User-specific conversion tracking
- Platform-wide volume and performance metrics

---
## ⚠️ Limitations & Considerations

While our system demonstrates effective cross-chain currency conversion, it’s important to acknowledge current limitations:

- Oracle Dependency Our solution relies on Flare’s FTSO oracles for real-time XRP/USD and FLR/USD pricing. This introduces potential latency if oracle updates are delayed, and full availability depends on the health of the oracle network.
- Network Costs On the Flare Network, transaction fees (gas costs) may increase under heavy network load. While typically lower than Ethereum mainnet fees, this variability could impact large-scale or high-frequency conversions.
---

## 🌐 **Network Support**

| Network             | Purpose                     | Status         |
| ------------------- | --------------------------- | -------------- |
| **Flare Mainnet**   | Production deployment       | ✅ Ready       |
| **Coston2 Testnet** | Development & testing       | ✅ Active      |
| **Songbird**        | Canary network testing      | ✅ Ready       |
| **XRPL Mainnet**    | XRP payments & verification | 🔄 Integration |
| **XRPL Testnet**    | Development testing         | 🔄 Integration |

---

## 📋 **Contract Addresses**

### **Coston2 Testnet** (Development)

- Deploy contracts using provided scripts
- Addresses generated at deployment time
- View on [Coston2 Explorer](https://coston2-explorer.flare.network)

### **Production Deployment**

```bash
# Deploy to Flare Mainnet
yarn hardhat run scripts/deploy.ts --network flare

# Verify contracts
yarn hardhat verify --network flare <CONTRACT_ADDRESS> <CONSTRUCTOR_ARGS>
```

---

## 🔐 **Security Features**

- **ReentrancyGuard** protection on fund operations
- **Access Control** with member-only functions
- **Governance Voting** for group vault decisions
- **Transaction Verification** to prevent double-spending
- **Oracle Price Validation** for accurate conversions
- **Smart Account Delegation** with proper authorization

---

## 🎉 **Why This Matters for Currency Conversion**

### **Traditional Problems**

❌ Centralized exchanges with high fees and custody risks  
❌ No real-time cross-chain price verification  
❌ Limited transparency in exchange rate calculations  
❌ Manual conversion processes with delays  
❌ No comprehensive transaction tracking

### **Our Solution**

✅ **Decentralized XRP to USD conversion** via Flare oracles  
✅ **Real-time price feeds** with transparent calculations  
✅ **Cross-chain verification** through XRPL integration  
✅ **Automated conversion processes** with instant execution  
✅ **Complete transaction tracking** and analytics dashboard

---

## 🛠️ **Development Setup**

### **Prerequisites**

```bash
node >= 18.0.0
yarn >= 1.22.0
```

### **Installation**

```bash
git clone <repository-url>
cd Harvard-Hackathon-Sep-20th-2025
yarn install
```

### **Environment Setup**

```bash
# Create .env file
PRIVATE_KEY=your_private_key_here
```

### **Testing**

```bash
# Compile contracts
npx hardhat compile

# Run tests
npx hardhat test

# Run specific demo
yarn hardhat run scripts/XRP_Conversion_Demo.ts --network coston2
```

---

## 🎯 **Future Roadmap**

### **Phase 1: MVP** ✅

- Cross-chain vault creation
- XRP to Flare conversion
- Basic oracle integration
- Demo implementation

### **Phase 2: Enhanced Features** 🔄

- Live FTSO price feed integration
- Real XRPL transaction verification
- Advanced Smart Account automation
- Production security audits

### **Phase 3: Ecosystem Expansion** 🔮

- Multi-asset support (Bitcoin, Ethereum, etc.)
- Travel booking integration
- Loyalty token rewards
- Mobile app interface

### **Phase 4: DeFi Integration** 🚀

- Yield farming on deposited assets
- Travel insurance smart contracts
- Decentralized travel marketplace
- Cross-chain liquidity pools

---

## 🏆 **Harvard Hackathon Submission**

**Category**: Cross-Chain Infrastructure  
**Track**: Flare Network Integration  
**Team**: FTG (Flare Travel Group)  
**Demo**: Live on Coston2 Testnet

### **Judging Criteria Addressed**

- ✅ **Innovation**: First cross-chain travel savings platform
- ✅ **Technical Excellence**: Full Flare ecosystem integration
- ✅ **Real-World Impact**: Solving actual travel payment problems
- ✅ **Code Quality**: Production-ready smart contracts
- ✅ **Demo Completeness**: Working end-to-end demonstration

---

## 🎬 **Demo Video**

Watch our live demonstration of the FTG Cross-Chain Travel Vault in action:

<!-- Replace this URL with your actual GitHub video URL after uploading -->

https://github.com/user-attachments/assets/your-video-id-here

<!-- Alternative: If you prefer to use the local file -->
<!-- ![Demo Video](./Screen%20Recording%202025-09-21%20at%2010.48.11%20AM.mov) -->

_Note: The demo shows real-time XRP to USD conversion, batch processing, and oracle-powered pricing on Coston2 testnet._

### **Demo Highlights**

- ⚡ **Live XRP Conversion**: 100 XRP → $62 USD (with optional FLR equivalent)
- 💱 **Currency Exchange**: Real-time XRP to USD conversion rates
- 📊 **Oracle Pricing**: Live FTSO price feed integration
- 🎯 **Event Logging**: Comprehensive on-chain transaction tracking
- 🔄 **Batch Processing**: Efficient multiple XRP transaction handling

---

## 📞 **Contact & Links**

---

**Built for Harvard Hackathon 2025**  
**Real-time XRP to USD conversion powered by Flare Network** ⚡💱🎯
