#!/bin/bash
# check for mongo docker container and create/start accordingly

CONTAINER_NAME="mongo"
IMAGE="mongo:latest"

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
    echo "Container not found. Setting up new MongoDB container..."
    read -p "MongoDB database name [mydb]: " MONGO_DB
    MONGO_DB=${MONGO_DB:-mydb}
    read -p "MongoDB username [admin]: " MONGO_USER
    MONGO_USER=${MONGO_USER:-admin}
    read -s -p "MongoDB password: " MONGO_PASS
    echo
    read -p "Host port to map to container 27017 [27017]: " HOST_PORT
    HOST_PORT=${HOST_PORT:-27017}

    # build environment args
    ENV_ARGS="-e MONGO_INITDB_ROOT_USERNAME=${MONGO_USER} -e MONGO_INITDB_ROOT_PASSWORD=${MONGO_PASS} -e MONGO_INITDB_DATABASE=${MONGO_DB}"
    PORT_ARGS="-p ${HOST_PORT}:27017"

    echo "Creating and starting container ${CONTAINER_NAME}..."
    docker run -d --name "${CONTAINER_NAME}" ${ENV_ARGS} ${PORT_ARGS} "${IMAGE}"
    
    # save configuration to env file only if container creation was successful
    if [ $? -eq 0 ]; then
        ENV_FILE="./env/.mongo-env"
        mkdir -p ./env
        echo "# MongoDB Configuration" > "$ENV_FILE"
        echo "MONGO_DATABASE=${MONGO_DB}" >> "$ENV_FILE"
        echo "MONGO_USER=${MONGO_USER}" >> "$ENV_FILE"
        echo "MONGO_PASSWORD=${MONGO_PASS}" >> "$ENV_FILE"
        echo "MONGO_HOST_PORT=${HOST_PORT}" >> "$ENV_FILE"
        echo "Configuration saved to $ENV_FILE"
    else
        echo "Failed to create container. Configuration not saved."
    fi
fi
