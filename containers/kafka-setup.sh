#!/bin/bash
# check for kafka docker container and create/start accordingly

CONTAINER_NAME="kafka"
IMAGE="apache/kafka:latest"

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
    echo "Container not found. Setting up new Kafka container..."
    read -p "Host port to map to Kafka [9092]: " HOST_PORT
    HOST_PORT=${HOST_PORT:-9092}

    # build environment args for Kafka
    ENV_ARGS="-e KAFKA_CFG_NODE_ID=0 -e KAFKA_CFG_PROCESS_ROLES=controller,broker -e KAFKA_CFG_LISTENERS=PLAINTEXT://:9092,CONTROLLER://:9093 -e KAFKA_CFG_LISTENER_SECURITY_PROTOCOL_MAP=CONTROLLER:PLAINTEXT,PLAINTEXT:PLAINTEXT -e KAFKA_CFG_CONTROLLER_QUORUM_VOTERS=0@localhost:9093 -e KAFKA_CFG_CONTROLLER_LISTENER_NAMES=CONTROLLER"
    PORT_ARGS="-p ${HOST_PORT}:9092"

    echo "Creating and starting container ${CONTAINER_NAME}..."
    docker run -d --name "${CONTAINER_NAME}" ${ENV_ARGS} ${PORT_ARGS} "${IMAGE}"
    
    # save configuration to env file only if container creation was successful
    if [ $? -eq 0 ]; then
        ENV_FILE="./env/.kafka-env"
        mkdir -p ./env
        echo "# Kafka Configuration" > "$ENV_FILE"
        echo "KAFKA_HOST_PORT=${HOST_PORT}" >> "$ENV_FILE"
        echo "Configuration saved to $ENV_FILE"
    else
        echo "Failed to create container. Configuration not saved."
    fi
fi
