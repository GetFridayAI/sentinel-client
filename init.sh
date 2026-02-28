#!/bin/sh

while getopts e:t:k:a:d:i:h:s:m:u:p:b:w:o: flag
do
    case "${flag}" in
        e) ENV=${OPTARG};;
        t) ENV_TYPE=${OPTARG};;
        k) API_KEY=${OPTARG};;
        a) APP_ID=${OPTARG};;
        d) DB_URL=${OPTARG};;
        i) PROJECT_ID=${OPTARG};;
        h) AUTH_DOMAIN=${OPTARG};;
        s) STORAGE_BUCKET=${OPTARG};;
        m) MSG_SENDER_ID=${OPTARG};;
        u) EMAIL=${OPTARG};;
        p) PASSWORD=${OPTARG};;
        b) DB_BASE_PATH=${OPTARG};;
        w) pwd=${OPTARG};;
        o) HOST_OS=${OPTARG};;
    esac
done

if [[ $ENV == "" || $API_KEY == "" || $APP_ID == "" || $DB_URL == "" || $PROJECT_ID == "" || $AUTH_DOMAIN == "" || $STORAGE_BUCKET == "" || $MSG_SENDER_ID == "" || $EMAIL == "" || $PASSWORD == "" || $pwd == "" ]]; then
    echo "Required arguments missing"
    echo "Cannot proceed with operation. Exiting."
    exit 0
fi

if [[ $ENV != "local" && $ENV_TYPE == "" ]]; then
    echo "Required arguments missing"
    echo "Cannot proceed with operation. Exiting."
    exit 0
fi

timestamp=$(date +%Y%m%d_%H%M%S%Z)

if [[ -f 'nohup.out' ]]; then
    new_file_name="nohup.$timestamp.out"
    sudo mv nohup.out $new_file_name
fi

if [[ $pwd == "" ]]; then
    pwd=$(pwd)
fi

cd $pwd
sudo npm install

# Container Setup - Ensure all Docker containers are running
echo "========================================"
echo "Starting Docker Containers..."
echo "========================================"
echo ""

if [ -f "$pwd/containers/setup-containers.sh" ]; then
    bash "$pwd/containers/setup-containers.sh"
    CONTAINER_SETUP_EXIT=$?
    if [ $CONTAINER_SETUP_EXIT -ne 0 ]; then
        echo "ERROR: Container setup failed. Cannot proceed."
        exit 1
    fi
else
    echo "WARNING: Container setup script not found at containers/setup-containers.sh"
    echo "Skipping container initialization..."
fi

echo ""

# Seed Cassandra Configuration
echo "========================================"
echo "Seeding Configuration into Cassandra..."
echo "========================================"
echo ""

if [ -f "$pwd/containers/seed-config.sh" ]; then
    bash "$pwd/containers/seed-config.sh" "update"
    if [ $? -ne 0 ]; then
        echo "WARNING: Configuration seeding encountered issues. Check logs above."
        echo "Database setup will still attempt to initialize schemas..."
    fi
else
    echo "WARNING: Configuration seed script not found at containers/seed-config.sh"
    echo "Skipping configuration seeding..."
fi

echo ""

# Database Setup - Initialize all databases before starting services
echo "========================================"
echo "Initializing Databases..."
echo "========================================"
echo ""

if [ -f "$pwd/database-setup/setup-databases.sh" ]; then
    bash "$pwd/database-setup/setup-databases.sh"
    if [ $? -ne 0 ]; then
        echo "WARNING: Database setup encountered issues. Check logs above."
        echo "Proceeding with service startup anyway..."
    fi
else
    echo "WARNING: Database setup script not found at database-setup/setup-databases.sh"
    echo "Skipping database initialization..."
fi

echo ""

echo ""
echo "========================================"
echo "Starting Service Monitoring..."
echo "========================================"
echo ""

MONITOR_SERVICES_JOB="sudo bash $pwd/services/monitor.sh -e $ENV -t $ENV_TYPE -k $API_KEY -a $APP_ID -d $DB_URL -i $PROJECT_ID -h $AUTH_DOMAIN -s $STORAGE_BUCKET -m $MSG_SENDER_ID -u $EMAIL -p $PASSWORD -b $DB_BASE_PATH -w $pwd -o $HOST_OS"
MONITOR_TUNNELS_JOB="sudo bash $pwd/tunnels/monitor.sh -e $ENV -t $ENV_TYPE -k $API_KEY -a $APP_ID -d $DB_URL -i $PROJECT_ID -h $AUTH_DOMAIN -s $STORAGE_BUCKET -m $MSG_SENDER_ID -u $EMAIL -p $PASSWORD -b $DB_BASE_PATH -w $pwd -o $HOST_OS"

removeCronJob () {
    crontab -l | grep -v '$1'  | crontab -
}

removeCronJob $MONITOR_SERVICES_JOB
removeCronJob $MONITOR_TUNNELS_JOB

crontab -l > cronjobs
echo "*/2 * * * * $MONITOR_SERVICES_JOB >/tmp/stdout.log 2>/tmp/stderr.log" >> newfilecron
echo "*/2 * * * * $MONITOR_TUNNELS_JOB >/tmp/stdout.log 2>/tmp/stderr.log" >> newfilecron
crontab newfilecron
rm newfilecron

