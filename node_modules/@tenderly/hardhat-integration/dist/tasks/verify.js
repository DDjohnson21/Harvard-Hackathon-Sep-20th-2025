"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
const config_1 = require("hardhat/config");
const plugins_1 = require("hardhat/plugins");
const logger_1 = require("../utils/logger");
const constants_1 = require("../constants");
(0, config_1.task)("tenderly:verify", "Verifies contracts on Tenderly based on the configuration in hardhat.config.js.")
    .addVariadicPositionalParam("contracts", "Addresses and names of contracts that will be verified formatted like `ContractName1=0x... ContractName2=0x...`")
    .addOptionalParam("libraries", "Libraries that contracts will use formatted like `ContractName1=LibraryName1:0x...,LibraryName2:0x...#ContractName2=LibraryName3:0x...,LibraryName4:0x...`")
    .setAction(verifyContract);
async function verifyContract({ contracts, libraries }, hre) {
    logger_1.logger.info("Verification via tenderly:verify hardhat task is invoked.");
    if (contracts === undefined) {
        throw new plugins_1.HardhatPluginError(constants_1.PLUGIN_NAME, `At least one contract must be provided (ContractName=Address)`);
    }
    const formattedContracts = [];
    let librariesMap = {};
    if (libraries !== undefined) {
        librariesMap = extractLibraries(libraries);
    }
    for (const contract of contracts) {
        const [name, address] = contract.split("=");
        formattedContracts.push({
            name,
            address,
            libraries: librariesMap[name] || {},
        });
    }
    await hre.tenderly.verify(...formattedContracts);
}
function extractLibraries(librariesParameter) {
    const libraries = {};
    for (const library of librariesParameter.split("#")) {
        const [contractName, contractLibraries] = library.split("=");
        libraries[contractName] = {};
        for (const contractLibrary of contractLibraries.split(",")) {
            const [libraryName, libraryAddress] = contractLibrary.split(":");
            libraries[contractName][libraryName] = libraryAddress;
        }
    }
    return libraries;
}
//# sourceMappingURL=verify.js.map