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

function checkServiceState {
    sudo node $pwd/services/fetch_config.js --apiKey=$API_KEY --appId=$APP_ID --dbUrl=$DB_URL --projectId=$PROJECT_ID --authDomain=$AUTH_DOMAIN --storageBucket=$STORAGE_BUCKET --msgSenderId=$MSG_SENDER_ID --env=$ENV --envType=$ENV_TYPE --email=$EMAIL --password=$PASSWORD --dbBasePath=$DB_BASE_PATH --basePath=$pwd

    sudo node $pwd/services/check_service_status.js --apiKey=$API_KEY --appId=$APP_ID --dbUrl=$DB_URL --projectId=$PROJECT_ID --authDomain=$AUTH_DOMAIN --storageBucket=$STORAGE_BUCKET --msgSenderId=$MSG_SENDER_ID --env=$ENV --envType=$ENV_TYPE --email=$EMAIL --password=$PASSWORD --dbBasePath=$DB_BASE_PATH --basePath=$pwd

    sudo node $pwd/services/update_service_state.js --apiKey=$API_KEY --appId=$APP_ID --dbUrl=$DB_URL --projectId=$PROJECT_ID --authDomain=$AUTH_DOMAIN --storageBucket=$STORAGE_BUCKET --msgSenderId=$MSG_SENDER_ID --env=$ENV --envType=$ENV_TYPE --email=$EMAIL --password=$PASSWORD --dbBasePath=$DB_BASE_PATH --basePath=$pwd
}

fileName=$ENV
if [[ $ENV_TYPE != "" ]]; then
    fileName="$fileName.$ENV_TYPE"
fi
fileName="$fileName.json"

checkServiceState

if [[ -f "$pwd/tunnels/$fileName" ]]; then
    BASE_PATH=${pwd%"sentinel-client"}
    CONFIG_FILE_PATH="$BASE_PATH/BIOS/config.json"
    sudo bash $BASE_PATH/BIOS/init-services.sh -c $CONFIG_FILE_PATH -b $BASE_PATH -o $HOST_OS
    checkServiceState
fi