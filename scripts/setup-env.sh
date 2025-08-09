#!/bin/bash

# Setup script for QuillArbiter development environment

echo "Setting up QuillArbiter development environment..."

# Check Node.js version
NODE_VERSION=$(node -v | cut -d'v' -f 2 | cut -d'.' -f 1)
if [ "$NODE_VERSION" -lt 16 ]; then
    echo "Error: Node.js version 16 or higher required"
    exit 1
fi

# Copy environment file
if [ ! -f .env ]; then
    cp .env.example .env
    echo "Created .env file - please configure it"
fi

# Install dependencies
echo "Installing dependencies..."
npm install

# Compile contracts
echo "Compiling contracts..."
npm run compile

echo "Setup complete! Run 'npm test' to verify installation."

