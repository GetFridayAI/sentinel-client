#!/bin/bash
# check for neo4j docker container and create/start accordingly

CONTAINER_NAME="neo4j"
IMAGE="neo4j:latest"

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
    echo "Container not found. Setting up new Neo4j container..."
    read -p "Neo4j username [neo4j]: " NEO4J_USER
    NEO4J_USER=${NEO4J_USER:-neo4j}
    read -s -p "Neo4j password: " NEO4J_PASS
    echo
    read -p "Host port for HTTP [7474]: " HTTP_PORT
    HTTP_PORT=${HTTP_PORT:-7474}
    read -p "Host port for Bolt [7687]: " BOLT_PORT
    BOLT_PORT=${BOLT_PORT:-7687}

    # build environment args
    ENV_ARGS="-e NEO4J_AUTH=${NEO4J_USER}/${NEO4J_PASS}"
    PORT_ARGS="-p ${HTTP_PORT}:7474 -p ${BOLT_PORT}:7687"

    echo "Creating and starting container ${CONTAINER_NAME}..."
    docker run -d --name "${CONTAINER_NAME}" ${ENV_ARGS} ${PORT_ARGS} "${IMAGE}"
    
    # save configuration to env file only if container creation was successful
    if [ $? -eq 0 ]; then
        ENV_FILE="./env/.neo4j-env"
        mkdir -p ./env
        echo "# Neo4j Configuration" > "$ENV_FILE"
        echo "NEO4J_USER=${NEO4J_USER}" >> "$ENV_FILE"
        echo "NEO4J_PASSWORD=${NEO4J_PASS}" >> "$ENV_FILE"
        echo "NEO4J_HTTP_PORT=${HTTP_PORT}" >> "$ENV_FILE"
        echo "NEO4J_BOLT_PORT=${BOLT_PORT}" >> "$ENV_FILE"
        echo "Configuration saved to $ENV_FILE"
    else
        echo "Failed to create container. Configuration not saved."
    fi
fi
