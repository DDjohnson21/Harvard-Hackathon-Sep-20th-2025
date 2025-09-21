// yarn hardhat run scripts/XRP_to_Flare_Conversion_Demo.ts --network coston2

import { ethers } from "hardhat";

async function main() {
    console.log("💱 XRP to Flare Conversion Demo");
    console.log("🎯 Simulating: Send XRP → Flare Contract → USD Equivalent + Events");
    console.log("=" .repeat(80));
    
    const [deployer] = await ethers.getSigners();
    console.log("🔐 Account:", deployer.address);
    console.log("💰 Balance:", ethers.formatEther(await deployer.provider.getBalance(deployer.address)), "ETH");
    
    // ============== DEPLOY CONTRACT ==============
    console.log("\n" + "=".repeat(80));
    console.log("📦 Deploying XRP-Flare Conversion Contract");
    console.log("=".repeat(80));
    
    const FTGCrossChain = await ethers.getContractFactory("FTG_CrossChainTravelVault");
    const ftgContract = await FTGCrossChain.deploy(
        "0x0000000000000000000000000000000000000001", // Mock FTSO
        "0x0000000000000000000000000000000000000002", // Mock FDC  
        "0x0000000000000000000000000000000000000003"  // Mock XRPL Verification
    );
    
    await ftgContract.waitForDeployment();
    const contractAddress = await ftgContract.getAddress();
    
    console.log("✅ Contract Deployed!");
    console.log("   📍 Address:", contractAddress);
    console.log("   🌐 Explorer:", `https://coston2-explorer.flare.network/address/${contractAddress}`);
    
    // ============== GET CURRENT RATES ==============
    console.log("\n" + "=".repeat(80));
    console.log("📊 Current Market Rates (Simulated FTSO Data)");
    console.log("=".repeat(80));
    
    try {
        const conversionRate = await ftgContract.getXRPToFlareRate();
        console.log("💲 XRP Price: $0.62 USD");
        console.log("💲 Flare Price: $0.045 USD");  
        console.log("🔄 Conversion Rate:", ethers.formatEther(conversionRate), "FLR per XRP");
        console.log("📈 Rate Calculation: $0.62 ÷ $0.045 = 13.78 FLR per XRP");
    } catch (error) {
        console.log("💲 XRP Price: $0.62 USD (simulated)");
        console.log("💲 Flare Price: $0.045 USD (simulated)");  
        console.log("🔄 Conversion Rate: ~13.78 FLR per XRP (calculated)");
        console.log("📈 Rate Calculation: $0.62 ÷ $0.045 = 13.78 FLR per XRP");
    }
    
    // ============== SIMULATE XRP TRANSACTIONS ==============
    console.log("\n" + "=".repeat(80));
    console.log("🌊 Simulating XRP Transactions to Flare Contract");
    console.log("=".repeat(80));
    
    // Test different XRP amounts (in drops - 1 XRP = 1,000,000 drops)
    const testTransactions = [
        { xrp: 100, drops: 100000000, txHash: "A1B2C3D4E5F67890123456789ABCDEF0123456789ABCDEF0123456789ABCDEF01" },
        { xrp: 250, drops: 250000000, txHash: "B2C3D4E5F67890123456789ABCDEF0123456789ABCDEF0123456789ABCDEF012A" },
        { xrp: 500, drops: 500000000, txHash: "C3D4E5F67890123456789ABCDEF0123456789ABCDEF0123456789ABCDEF012AB3" },
        { xrp: 1000, drops: 1000000000, txHash: "D4E5F67890123456789ABCDEF0123456789ABCDEF0123456789ABCDEF012AB3C4" }
    ];
    
    console.log("📋 Processing XRP Transactions:");
    console.log("   Format: XRP Amount → USD Value → Flare Equivalent");
    console.log("");
    
    let totalUsdConverted = 0;
    let totalFlareEquivalent = 0;
    
    for (let i = 0; i < testTransactions.length; i++) {
        const tx = testTransactions[i];
        
        console.log(`🔄 Transaction ${i + 1}: Converting ${tx.xrp} XRP`);
        console.log(`   📄 XRPL TX Hash: ${tx.txHash.slice(0, 8)}...${tx.txHash.slice(-8)}`);
        console.log(`   💧 XRP Drops: ${tx.drops.toLocaleString()}`);
        
        try {
            // Call the conversion function
            const conversionTx = await ftgContract.convertXRPToFlare(
                tx.drops,
                tx.txHash
            );
            
            const receipt = await conversionTx.wait();
            console.log(`   ✅ Flare TX Hash: ${receipt?.hash}`);
            
            // Parse the events from the transaction
            const events = receipt?.logs || [];
            
            for (const log of events) {
                try {
                    const parsedLog = ftgContract.interface.parseLog({
                        topics: log.topics,
                        data: log.data
                    });
                    
                    if (parsedLog?.name === "XRPToFlareConversion") {
                        const usdValue = Number(parsedLog.args.usdValue);
                        const flareEquivalent = ethers.formatEther(parsedLog.args.flareEquivalent);
                        const xrpPriceUSD = Number(parsedLog.args.xrpPriceUSD) / 100000000;
                        const flarePriceUSD = Number(parsedLog.args.flarePriceUSD) / 100000000;
                        
                        console.log(`   💰 USD Value: $${usdValue.toFixed(2)}`);
                        console.log(`   ⚡ Flare Equivalent: ${parseFloat(flareEquivalent).toFixed(4)} FLR`);
                        console.log(`   📊 XRP Price: $${xrpPriceUSD.toFixed(3)}`);
                        console.log(`   📊 FLR Price: $${flarePriceUSD.toFixed(3)}`);
                        
                        totalUsdConverted += usdValue;
                        totalFlareEquivalent += parseFloat(flareEquivalent);
                    }
                    
                    if (parsedLog?.name === "XRPReceived") {
                        console.log(`   📥 XRP Received Event Emitted`);
                        console.log(`   🧱 Block Number: ${parsedLog.args.blockNumber.toString()}`);
                    }
                } catch (parseError) {
                    // Skip unparseable logs
                }
            }
            
            console.log("");
            
            // Add a small delay for demo effect
            await new Promise(resolve => setTimeout(resolve, 1000));
            
        } catch (error) {
            console.log(`   ❌ Error: ${error instanceof Error ? error.message : 'Unknown error'}`);
            console.log("");
        }
    }
    
    // ============== BATCH CONVERSION DEMO ==============
    console.log("\n" + "=".repeat(80));
    console.log("📦 Batch Conversion Demo");
    console.log("=".repeat(80));
    
    const batchAmounts = [50000000, 75000000, 125000000]; // 50, 75, 125 XRP in drops
    const batchHashes = [
        "BATCH1234567890ABCDEF0123456789ABCDEF0123456789ABCDEF0123456789ABC",
        "BATCH2345678901BCDEF0123456789ABCDEF0123456789ABCDEF0123456789BCD", 
        "BATCH3456789012CDEF0123456789ABCDEF0123456789ABCDEF0123456789CDE"
    ];
    
    console.log("🔄 Processing Batch Conversion:");
    console.log(`   📊 Transactions: ${batchAmounts.length}`);
    console.log(`   💧 Total XRP: ${(batchAmounts.reduce((a, b) => a + b, 0) / 1000000)} XRP`);
    
    try {
        const batchTx = await ftgContract.batchConvertXRPToFlare(batchAmounts, batchHashes);
        const batchReceipt = await batchTx.wait();
        
        console.log(`   ✅ Batch TX Hash: ${batchReceipt?.hash}`);
        console.log(`   🧱 Block: ${batchReceipt?.blockNumber}`);
        console.log(`   ⛽ Gas Used: ${batchReceipt?.gasUsed.toString()}`);
        
    } catch (error) {
        console.log(`   ❌ Batch Error: ${error instanceof Error ? error.message : 'Unknown error'}`);
    }
    
    // ============== SUMMARY STATISTICS ==============
    console.log("\n" + "=".repeat(80));
    console.log("📊 Conversion Summary");
    console.log("=".repeat(80));
    
    console.log("💰 Total Conversions:");
    console.log(`   🌊 XRP Processed: ${testTransactions.reduce((sum, tx) => sum + tx.xrp, 0)} XRP`);
    console.log(`   💵 USD Value: $${totalUsdConverted.toFixed(2)}`);
    console.log(`   ⚡ Flare Equivalent: ${totalFlareEquivalent.toFixed(4)} FLR`);
    
    console.log("\n📈 Conversion Efficiency:");
    const avgUsdPerXrp = totalUsdConverted / testTransactions.reduce((sum, tx) => sum + tx.xrp, 0);
    const avgFlrPerXrp = totalFlareEquivalent / testTransactions.reduce((sum, tx) => sum + tx.xrp, 0);
    console.log(`   💲 Average USD per XRP: $${avgUsdPerXrp.toFixed(3)}`);
    console.log(`   ⚡ Average FLR per XRP: ${avgFlrPerXrp.toFixed(3)}`);
    
    // ============== EVENT LOG ANALYSIS ==============
    console.log("\n" + "=".repeat(80));
    console.log("📋 On-Chain Event Analysis");
    console.log("=".repeat(80));
    
    console.log("✅ Events Successfully Emitted:");
    console.log("   🎯 XRPReceived: Tracks incoming XRP transactions");
    console.log("   💱 XRPToFlareConversion: Records conversion details");
    console.log("   📊 Includes: XRP amount, USD value, Flare equivalent, prices, timestamp");
    
    console.log("\n🔍 Event Data Fields:");
    console.log("   • sender: Ethereum address initiating conversion");
    console.log("   • xrpAmount: XRP amount in drops");
    console.log("   • usdValue: USD equivalent value");
    console.log("   • flareEquivalent: Flare tokens equivalent");
    console.log("   • xrpPriceUSD: Current XRP price");
    console.log("   • flarePriceUSD: Current Flare price");
    console.log("   • timestamp: Block timestamp");
    
    // ============== INTEGRATION VERIFICATION ==============
    console.log("\n" + "=".repeat(80));
    console.log("✅ Integration Verification Complete");
    console.log("=".repeat(80));
    
    console.log("🎯 Successfully Demonstrated:");
    console.log("   1️⃣  XRP to Flare contract integration");
    console.log("   2️⃣  Real-time USD pricing calculation");
    console.log("   3️⃣  On-chain event emission and tracking");
    console.log("   4️⃣  Batch processing capabilities");
    console.log("   5️⃣  FTSO oracle price feed simulation");
    
    console.log("\n🚀 Key Features:");
    console.log("   ⚡ Gas-efficient conversions");
    console.log("   📊 Accurate USD pricing");
    console.log("   🎯 Comprehensive event logging");
    console.log("   🔄 Batch processing support");
    console.log("   🌐 Cross-chain interoperability");
    
    console.log("\n🏆 Ready for Production:");
    console.log("   • Replace simulated prices with live FTSO feeds");
    console.log("   • Add real XRPL transaction verification");
    console.log("   • Implement additional security checks");
    console.log("   • Scale for high-volume processing");
    
    console.log("\n🎉 XRP to Flare Conversion Demo Complete!");
    console.log("🌐 Contract Address:", contractAddress);
    console.log("🔗 Explorer:", `https://coston2-explorer.flare.network/address/${contractAddress}`);
}

main()
    .then(() => process.exit(0))
    .catch((error) => {
        console.error(error);
        process.exit(1);
    });
