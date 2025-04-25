const hre = require("hardhat");

/**
 * Network utility functions
 */

async function getNetworkInfo() {
  const network = await hre.ethers.provider.getNetwork();
  const blockNumber = await hre.ethers.provider.getBlockNumber();
  const gasPrice = await hre.ethers.provider.getFeeData();

  return {
    name: network.name,
    chainId: network.chainId,
    blockNumber,
    gasPrice: gasPrice.gasPrice,
  };
}

async function isContractDeployed(address) {
  const code = await hre.ethers.provider.getCode(address);
  return code !== "0x";
}

async function waitForBlocks(numBlocks) {
  const startBlock = await hre.ethers.provider.getBlockNumber();
  let currentBlock = startBlock;

  while (currentBlock < startBlock + numBlocks) {
    await new Promise(resolve => setTimeout(resolve, 1000));
    currentBlock = await hre.ethers.provider.getBlockNumber();
  }
}

async function getBalance(address) {
  const balance = await hre.ethers.provider.getBalance(address);
  return hre.ethers.formatEther(balance);
}

module.exports = {
  getNetworkInfo,
  isContractDeployed,
  waitForBlocks,
  getBalance,
};

