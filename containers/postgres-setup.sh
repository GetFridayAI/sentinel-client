#!/bin/bash
# check for postgres docker container and create/start accordingly

CONTAINER_NAME="postgres"
IMAGE="postgres:latest"

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
    echo "Container not found. Setting up new PostgreSQL container..."
    read -p "PostgreSQL database name [mydb]: " PG_DB
    PG_DB=${PG_DB:-mydb}
    read -p "PostgreSQL username [postgres]: " PG_USER
    PG_USER=${PG_USER:-postgres}
    read -s -p "PostgreSQL password: " PG_PASS
    echo
    read -p "Host port to map to container 5432 [5432]: " HOST_PORT
    HOST_PORT=${HOST_PORT:-5432}

    # build environment args
    ENV_ARGS="-e POSTGRES_DB=${PG_DB} -e POSTGRES_USER=${PG_USER} -e POSTGRES_PASSWORD=${PG_PASS}"
    PORT_ARGS="-p ${HOST_PORT}:5432"

    echo "Creating and starting container ${CONTAINER_NAME}..."
    docker run -d --name "${CONTAINER_NAME}" ${ENV_ARGS} ${PORT_ARGS} "${IMAGE}"
    
    # save configuration to env file only if container creation was successful
    if [ $? -eq 0 ]; then
        ENV_FILE="./env/.postgres-env"
        mkdir -p ./env
        echo "# PostgreSQL Configuration" > "$ENV_FILE"
        echo "POSTGRES_DATABASE=${PG_DB}" >> "$ENV_FILE"
        echo "POSTGRES_USER=${PG_USER}" >> "$ENV_FILE"
        echo "POSTGRES_PASSWORD=${PG_PASS}" >> "$ENV_FILE"
        echo "POSTGRES_HOST_PORT=${HOST_PORT}" >> "$ENV_FILE"
        echo "Configuration saved to $ENV_FILE"
    else
        echo "Failed to create container. Configuration not saved."
    fi
fi
