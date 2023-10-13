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

function checkTunnelState {
    sudo node $pwd/tunnels/fetch_tunnels.js --apiKey=$API_KEY --appId=$APP_ID --dbUrl=$DB_URL --projectId=$PROJECT_ID --authDomain=$AUTH_DOMAIN --storageBucket=$STORAGE_BUCKET --msgSenderId=$MSG_SENDER_ID --env=$ENV --envType=$ENV_TYPE --email=$EMAIL --password=$PASSWORD --dbBasePath=$DB_BASE_PATH --basePath=$pwd

    sudo node $pwd/tunnels/check_tunnel_status.js --apiKey=$API_KEY --appId=$APP_ID --dbUrl=$DB_URL --projectId=$PROJECT_ID --authDomain=$AUTH_DOMAIN --storageBucket=$STORAGE_BUCKET --msgSenderId=$MSG_SENDER_ID --env=$ENV --envType=$ENV_TYPE --email=$EMAIL --password=$PASSWORD --dbBasePath=$DB_BASE_PATH --basePath=$pwd

    sudo node $pwd/tunnels/update_tunnel_state.js --apiKey=$API_KEY --appId=$APP_ID --dbUrl=$DB_URL --projectId=$PROJECT_ID --authDomain=$AUTH_DOMAIN --storageBucket=$STORAGE_BUCKET --msgSenderId=$MSG_SENDER_ID --env=$ENV --envType=$ENV_TYPE --email=$EMAIL --password=$PASSWORD --dbBasePath=$DB_BASE_PATH --basePath=$pwd
}

fileName=$ENV
if [[ $ENV_TYPE != "" ]]; then
    fileName="$fileName.$ENV_TYPE"
fi
fileName="$fileName.json"

checkTunnelState

if [[ -f "$pwd/tunnels/$fileName" ]]; then
    BASE_PATH=${pwd%"sentinel-client"}
    CONFIG_FILE_PATH="$BASE_PATH/BIOS/config.json"
    sudo bash $BASE_PATH/BIOS/init-tunnels.sh -c $CONFIG_FILE_PATH -f $BASE_PATH -e $ENV -t $ENV_TYPE -k $API_KEY -a $APP_ID -d $DB_URL -i $PROJECT_ID -h $AUTH_DOMAIN -s $STORAGE_BUCKET -m $MSG_SENDER_ID -u $EMAIL -p $PASSWORD -b $DB_BASE_PATH -o $HOST_OS
    checkTunnelState
fi