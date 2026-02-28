#!/bin/bash
# root setup script for sentinel-client

# run dependencies setup first
# ensure the dependencies script exists and invoke with bash (avoid needing execute permission)
if [ -f ./dependencies/setup.sh ]; then
    echo "Invoking dependencies setup..."
    bash ./dependencies/setup.sh
else
    echo "dependencies/setup.sh not found"
fi

# prompt for Docker username and perform login
read -p "Docker username: " DOCKER_USER
if [ -n "$DOCKER_USER" ]; then
    echo "Logging in to Docker as $DOCKER_USER..."
    docker login -u "$DOCKER_USER"
else
    echo "No Docker username provided, skipping login."
fi

# run containers setup if available
if [ -f ./containers/setup.sh ]; then
    echo "Running containers setup..."
    bash ./containers/setup.sh
else
    echo "containers/setup.sh not found"
fi

# run databases setup if available
if [ -f ./databases/setup.sh ]; then
    echo "Running databases setup..."
    bash ./databases/setup.sh
else
    echo "databases/setup.sh not found"
fi

# Firebase Setup/Startup Script
# App Setup/Startup Script
# Tunnel Setup/Startup Script
# Nginx Setup/Startup Script