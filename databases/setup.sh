#!/bin/bash
# setup script for databases directory

echo "Setting up databases..."

# invoke seed-db-config script if available
if [ -f ./seed-db-config.sh ]; then
    echo "Running database configuration seeding..."
    bash ./seed-db-config.sh
else
    echo "seed-db-config.sh not found"
fi

# Setup auth tokens (API TOKEN, Encryption Key, etc.)
