#!/bin/bash

# Clean all build artifacts and dependencies

echo "Cleaning QuillArbiter project..."

# Clean Hardhat artifacts
echo "Removing Hardhat artifacts..."
rm -rf artifacts/
rm -rf cache/
rm -rf typechain-types/

# Clean coverage
echo "Removing coverage data..."
rm -rf coverage/
rm -f coverage.json

# Clean node modules (optional)
read -p "Remove node_modules? (y/n) " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]
then
    echo "Removing node_modules..."
    rm -rf node_modules/
    rm -f package-lock.json
fi

echo "✅ Clean completed!"

