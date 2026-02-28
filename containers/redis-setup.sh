#!/bin/bash
# check for redis docker container and create/start accordingly

CONTAINER_NAME="redis"
IMAGE="redis:latest"

# check if container exists (stopped or running)
if docker ps -a --format '{{.Names}}' | grep -q "^${CONTAINER_NAME}$"; then
    echo "Container ${CONTAINER_NAME} already exists."
    # start if not running
    if ! docker ps --format '{{.Names}}' | grep -q "^${CONTAINER_NAME}$"; then
        echo "Starting existing container ${CONTAINER_NAME}..."
        docker start "${CONTAINER_NAME}"
    else
        echo "Container ${CONTAINER_NAME} is already running."
    fi
else
    # container doesn't exist, collect configuration from user
    echo "Container not found. Setting up new Redis container..."
    read -p "Host port to map to container 6379 [6379]: " HOST_PORT
    HOST_PORT=${HOST_PORT:-6379}
    read -s -p "Redis password (leave empty for no auth): " REDIS_PASS
    echo

    # build args
    PORT_ARGS="-p ${HOST_PORT}:6379"
    if [ -n "$REDIS_PASS" ]; then
        CMD_ARGS="redis-server --requirepass ${REDIS_PASS}"
        echo "Creating and starting container ${CONTAINER_NAME} with password protection..."
        docker run -d --name "${CONTAINER_NAME}" ${PORT_ARGS} "${IMAGE}" ${CMD_ARGS}
    else
        echo "Creating and starting container ${CONTAINER_NAME} without password..."
        docker run -d --name "${CONTAINER_NAME}" ${PORT_ARGS} "${IMAGE}"
    fi
    
    # save configuration to env file only if container creation was successful
    if [ $? -eq 0 ]; then
        ENV_FILE="./env/.redis-env"
        mkdir -p ./env
        echo "# Redis Configuration" > "$ENV_FILE"
        echo "REDIS_HOST_PORT=${HOST_PORT}" >> "$ENV_FILE"
        echo "REDIS_PASSWORD=${REDIS_PASS}" >> "$ENV_FILE"
        echo "Configuration saved to $ENV_FILE"
    else
        echo "Failed to create container. Configuration not saved."
    fi
fi
