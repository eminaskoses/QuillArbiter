const hre = require("hardhat");

/**
 * Helper utility functions for scripts
 */

/**
 * Sleep for specified milliseconds
 */
async function sleep(ms) {
  return new Promise((resolve) => setTimeout(resolve, ms));
}

/**
 * Format address for display
 */
function formatAddress(address) {
  return `${address.substring(0, 6)}...${address.substring(38)}`;
}

/**
 * Get current timestamp
 */
async function getCurrentTimestamp() {
  const block = await hre.ethers.provider.getBlock("latest");
  return block.timestamp;
}

/**
 * Check if address is contract
 */
async function isContract(address) {
  const code = await hre.ethers.provider.getCode(address);
  return code !== "0x";
}

/**
 * Wait for transaction confirmations
 */
async function waitForConfirmations(tx, confirmations = 2) {
  console.log(`Waiting for ${confirmations} confirmations...`);
  const receipt = await tx.wait(confirmations);
  console.log(`Transaction confirmed in block ${receipt.blockNumber}`);
  return receipt;
}

/**
 * Get gas price
 */
async function getGasPrice() {
  const feeData = await hre.ethers.provider.getFeeData();
  return feeData.gasPrice;
}

/**
 * Estimate transaction cost
 */
async function estimateTxCost(contract, method, args) {
  const gasEstimate = await contract[method].estimateGas(...args);
  const gasPrice = await getGasPrice();
  const cost = gasEstimate * gasPrice;
  return {
    gasEstimate,
    gasPrice,
    cost,
    costInEth: hre.ethers.formatEther(cost),
  };
}

/**
 * Parse events from receipt
 */
function parseEvents(receipt, contractInterface) {
  const events = [];
  for (const log of receipt.logs) {
    try {
      const parsed = contractInterface.parseLog(log);
      if (parsed) {
        events.push({
          name: parsed.name,
          args: parsed.args,
        });
      }
    } catch (e) {
      // Not an event from this contract
    }
  }
  return events;
}

/**
 * Generate random bytes32
 */
function randomBytes32() {
  return hre.ethers.hexlify(hre.ethers.randomBytes(32));
}

/**
 * Calculate vote hash for commit-reveal
 */
function calculateVoteHash(verdict, salt) {
  return hre.ethers.keccak256(
    hre.ethers.AbiCoder.defaultAbiCoder().encode(
      ["uint256", "bytes32"],
      [verdict, salt]
    )
  );
}

module.exports = {
  sleep,
  formatAddress,
  getCurrentTimestamp,
  isContract,
  waitForConfirmations,
  getGasPrice,
  estimateTxCost,
  parseEvents,
  randomBytes32,
  calculateVoteHash,
};

