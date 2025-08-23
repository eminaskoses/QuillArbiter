const { time } = require("@nomicfoundation/hardhat-network-helpers");

/**
 * Time manipulation helpers for testing
 */

async function increaseTime(seconds) {
  await time.increase(seconds);
}

async function setNextBlockTimestamp(timestamp) {
  await time.setNextBlockTimestamp(timestamp);
}

async function latestTimestamp() {
  return await time.latest();
}

async function advanceDays(days) {
  await time.increase(days * 24 * 60 * 60);
}

async function advanceHours(hours) {
  await time.increase(hours * 60 * 60);
}

module.exports = {
  increaseTime,
  setNextBlockTimestamp,
  latestTimestamp,
  advanceDays,
  advanceHours,
};

