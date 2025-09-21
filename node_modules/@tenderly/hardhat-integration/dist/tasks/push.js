"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
const config_1 = require("hardhat/config");
(0, config_1.task)("tenderly:push", "Verifies contracts on Tenderly based on the configuration in hardhat.config.js.")
    .addOptionalVariadicPositionalParam("contracts", "Addresses and names of contracts that will be verified formatted ContractName=Address")
    .setAction(pushContracts);
async function pushContracts({ contracts }, hre) {
    new ColorLog("THIS TASK IS DEPRECATED. PLEASE USE 'tenderly:verify' TASK.")
        // .prependColor(ColorLog.BG.RED)
        .prependColor(ColorLog.TEXT.RED)
        .appendCommand(ColorLog.RESET_COLOR_CMD)
        .log();
    hre.config.tenderly.privateVerification = true;
    await hre.run("tenderly:verify", { contracts });
}
// This is just nice behavior instead of hard-coding.
// If we ever need to use colorful logs, look up Chalk.js or Colors.js.
// I didn't want to add a dependency because this is the only use case.
class ColorLog {
    constructor(_msg) {
        this.msg = _msg;
    }
    prependColor(color) {
        this.msg = color + this.msg;
        return this;
    }
    appendCommand(cmd) {
        this.msg += cmd;
        return this;
    }
    log() {
        console.log(this.msg);
    }
}
ColorLog.BG = {
    YELLOW: "\x1b[43m",
    RED: "\x1b[41m",
};
ColorLog.TEXT = {
    RED: "\x1b[31m",
    BLACK: "\x1b[30m",
    YELLOW: "\x1b[33m",
};
ColorLog.RESET_COLOR_CMD = "\x1b[0m";
//# sourceMappingURL=push.js.map