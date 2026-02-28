#!/bin/bash
# Script to create and populate db_config table in Cassandra with configurations from .env files

# Wait for Cassandra to be ready (give it some time to fully start)
echo "Waiting for Cassandra to be ready..."
sleep 10

# Cassandra connection details (from cassandra-env if available)
CASS_HOST="localhost"
CASS_PORT="9042"
CASS_USER="cassandra"
CASS_PASS="cassandra"

# Load cassandra env if it exists
if [ -f ../env/.cassandra-env ]; then
    source ../env/.cassandra-env
    CASS_PORT="${CASSANDRA_HOST_PORT:-9042}"
    CASS_USER="${CASSANDRA_USER:-cassandra}"
    CASS_PASS="${CASSANDRA_PASSWORD:-cassandra}"
fi

echo "Connecting to Cassandra at ${CASS_HOST}:${CASS_PORT}..."

# Create keyspace and table
echo "Creating keyspace and table..."
docker exec -i cassandra cqlsh -u "${CASS_USER}" -p "${CASS_PASS}" <<EOF
CREATE KEYSPACE IF NOT EXISTS env WITH replication = {'class': 'SimpleStrategy', 'replication_factor': 1};

CREATE TABLE IF NOT EXISTS env.db_config (
    db_type text PRIMARY KEY,
    database_name text,
    username text,
    password text,
    host_port int,
    http_port int,
    bolt_port int
);
EOF

if [ $? -eq 0 ]; then
    echo "Keyspace and table created successfully."
else
    echo "Failed to create keyspace and table."
    exit 1
fi

# Function to insert data into Cassandra
insert_config() {
    local db_type="$1"
    local database_name="$2"
    local username="$3"
    local password="$4"
    local host_port="$5"
    local http_port="$6"
    local bolt_port="$7"
    
    echo "Inserting configuration for ${db_type}..."
    docker exec -i cassandra cqlsh -u "${CASS_USER}" -p "${CASS_PASS}" <<EOF
INSERT INTO env.db_config (db_type, database_name, username, password, host_port, http_port, bolt_port)
VALUES ('${db_type}', ${database_name}, ${username}, ${password}, ${host_port}, ${http_port}, ${bolt_port});
EOF
}

# Parse and insert Redis configuration
if [ -f ./env/.redis-env ]; then
    echo "Processing Redis configuration..."
    source ./env/.redis-env
    insert_config "redis" "null" "null" "'${REDIS_PASSWORD}'" "${REDIS_HOST_PORT}" "null" "null"
fi

# Parse and insert Kafka configuration
if [ -f ./env/.kafka-env ]; then
    echo "Processing Kafka configuration..."
    source ./env/.kafka-env
    insert_config "kafka" "null" "null" "null" "${KAFKA_HOST_PORT}" "null" "null"
fi

# Parse and insert MongoDB configuration
if [ -f ./env/.mongo-env ]; then
    echo "Processing MongoDB configuration..."
    source ./env/.mongo-env
    insert_config "mongo" "'${MONGO_DATABASE}'" "'${MONGO_USER}'" "'${MONGO_PASSWORD}'" "${MONGO_HOST_PORT}" "null" "null"
fi

# Parse and insert Neo4j configuration
if [ -f ./env/.neo4j-env ]; then
    echo "Processing Neo4j configuration..."
    source ./env/.neo4j-env
    insert_config "neo4j" "null" "'${NEO4J_USER}'" "'${NEO4J_PASSWORD}'" "null" "${NEO4J_HTTP_PORT}" "${NEO4J_BOLT_PORT}"
fi

# Parse and insert PostgreSQL configuration
if [ -f ./env/.postgres-env ]; then
    echo "Processing PostgreSQL configuration..."
    source ./env/.postgres-env
    insert_config "postgres" "'${POSTGRES_DATABASE}'" "'${POSTGRES_USER}'" "'${POSTGRES_PASSWORD}'" "${POSTGRES_HOST_PORT}" "null" "null"
fi

echo "Database configuration seeding complete!"
echo "You can verify the data with: docker exec -it cassandra cqlsh -u ${CASS_USER} -p ${CASS_PASS} -e 'SELECT * FROM env.db_config;'"
