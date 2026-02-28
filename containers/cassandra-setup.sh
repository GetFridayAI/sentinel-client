#!/bin/bash
# check for cassandra docker container and create/start accordingly

CONTAINER_NAME="cassandra"
IMAGE="cassandra:latest"

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
    echo "Container not found. Setting up new Cassandra container..."
    read -p "Cassandra keyspace/db name [mykeyspace]: " CASS_KEYSPACE
    CASS_KEYSPACE=${CASS_KEYSPACE:-mykeyspace}
    read -p "Cassandra username [cassandra]: " CASS_USER
    CASS_USER=${CASS_USER:-cassandra}
    read -s -p "Cassandra password [cassandra]: " CASS_PASS
    echo
    CASS_PASS=${CASS_PASS:-cassandra}
    read -p "Host port to map to container 9042 [9042]: " HOST_PORT
    HOST_PORT=${HOST_PORT:-9042}

    # build environment args
    ENV_ARGS="-e CASSANDRA_KEYSPACE=${CASS_KEYSPACE} -e CASSANDRA_USER=${CASS_USER} -e CASSANDRA_PASSWORD=${CASS_PASS}"
    PORT_ARGS="-p ${HOST_PORT}:9042"

    echo "Creating and starting container ${CONTAINER_NAME}..."
    docker run -d --name "${CONTAINER_NAME}" ${ENV_ARGS} ${PORT_ARGS} "${IMAGE}"
    
    # save configuration to env file only if container creation was successful
    if [ $? -eq 0 ]; then
        ENV_FILE="./env/.cassandra-env"
        mkdir -p ./env
        echo "# Cassandra Configuration" > "$ENV_FILE"
        echo "CASSANDRA_KEYSPACE=${CASS_KEYSPACE}" >> "$ENV_FILE"
        echo "CASSANDRA_USER=${CASS_USER}" >> "$ENV_FILE"
        echo "CASSANDRA_PASSWORD=${CASS_PASS}" >> "$ENV_FILE"
        echo "CASSANDRA_HOST_PORT=${HOST_PORT}" >> "$ENV_FILE"
        echo "Configuration saved to $ENV_FILE"
    else
        echo "Failed to create container. Configuration not saved."
    fi
fi