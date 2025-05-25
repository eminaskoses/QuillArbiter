#!/bin/bash

# Backup deployment information

BACKUP_DIR="deployments-backup"
TIMESTAMP=$(date +"%Y%m%d_%H%M%S")

echo "Creating deployment backup..."

mkdir -p $BACKUP_DIR

if [ -f "deployment-info.json" ]; then
    cp deployment-info.json "$BACKUP_DIR/deployment-$TIMESTAMP.json"
    echo "✅ Backed up deployment-info.json"
else
    echo "⚠️  No deployment-info.json found"
fi

echo "Backup completed at $BACKUP_DIR/deployment-$TIMESTAMP.json"

