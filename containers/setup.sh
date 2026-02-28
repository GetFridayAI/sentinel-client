#!/bin/bash
# setup script for containers directory

echo "Setting up containers..."

# invoke cassandra setup
if [ -f ./containers/cassandra-setup.sh ]; then
    echo "Running Cassandra setup..."
    bash ./containers/cassandra-setup.sh
else
    echo "cassandra-setup.sh not found"
fi

# invoke redis setup
if [ -f ./containers/redis-setup.sh ]; then
    echo "Running Redis setup..."
    bash ./containers/redis-setup.sh
else
    echo "redis-setup.sh not found"
fi

# invoke kafka setup
if [ -f ./containers/kafka-setup.sh ]; then
    echo "Running Kafka setup..."
    bash ./containers/kafka-setup.sh
else
    echo "kafka-setup.sh not found"
fi

# invoke neo4j setup
if [ -f ./containers/neo4j-setup.sh ]; then
    echo "Running Neo4j setup..."
    bash ./containers/neo4j-setup.sh
else
    echo "neo4j-setup.sh not found"
fi

# invoke mongo setup
if [ -f ./containers/mongo-setup.sh ]; then
    echo "Running MongoDB setup..."
    bash ./containers/mongo-setup.sh
else
    echo "mongo-setup.sh not found"
fi

# invoke postgres setup
if [ -f ./containers/postgres-setup.sh ]; then
    echo "Running PostgreSQL setup..."
    bash ./containers/postgres-setup.sh
else
    echo "postgres-setup.sh not found"
fi

echo "Container setup complete!"
