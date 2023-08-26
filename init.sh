#!/bin/sh

while getopts e:t:k:a:d:i:h:s:m:u:p:b: flag
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
    esac
done

if [[ $ENV == "" || $API_KEY == "" || $APP_ID == "" || $DB_URL == "" || $PROJECT_ID == "" || $AUTH_DOMAIN == "" || $STORAGE_BUCKET == "" || $MSG_SENDER_ID == "" || $EMAIL == "" || $PASSWORD == "" ]]; then
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

sudo npm install

pwd=$(pwd)
sudo node $pwd/fetch_config.js --apiKey=$API_KEY --appId=$APP_ID --dbUrl=$DB_URL --projectId=$PROJECT_ID --authDomain=$AUTH_DOMAIN --storageBucket=$STORAGE_BUCKET --msgSenderId=$MSG_SENDER_ID --env=$ENV --envType=$ENV_TYPE --email=$EMAIL --password=$PASSWORD --dbBasePath=$DB_BASE_PATH --basePath=$pwd
echo "Back to Bash"
# # Get Firmware details

# OSTYPE=$(uname)
# KERNEL_VERSION=$(uname -r)

# # linux specific commands
# CPU_DETAILS=$(lscpu)

# # mac specific commands
# FIRMWARE_DETAILS=$(system_profiler SPSoftwareDataType)

# echo "$OSTYPE"
# echo "$KERNEL_VERSION"
# echo "$FIRMWARE_DETAILS"
# echo "$CPU_DETAILS"

# MONITOR_TUNNELS_JOB="sudo sh /Users/amitrai/Projects/Friday/codebase/sentinel-client/monitor_tunnels.sh"

# removeCronJob () {
#     crontab -l | grep -v '$1'  | crontab -
# }

# crontab -l > cronjobs
# #echo new cron into cron file
# echo "* * * * * $command" >> newfilecron
# #install new cron file
# crontab newfilecron
# rm newfilecron

