#!/bin/sh

while getopts e:t:k:a:d:i:h:s:m:u:p:b:w: flag
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

sudo npm install

if [[ $pwd == "" ]]; then
    pwd=$(pwd)
fi

MONITOR_TUNNELS_JOB="sudo sh $pwd/tunnels/monitor.sh -e $ENV -k $API_KEY -a $APP_ID -d $DB_URL -i $PROJECT_ID -h f$AUTH_DOMAIN -s $STORAGE_BUCKET -m $MSG_SENDER_ID -u $EMAIL -p $PASSWORD -b $DB_BASE_PATH -w $pwd"

removeCronJob () {
    crontab -l | grep -v '$1'  | crontab -
}

removeCronJob $MONITOR_TUNNELS_JOB

crontab -l > cronjobs
echo "*/2 * * * * $MONITOR_TUNNELS_JOB >/tmp/stdout.log 2>/tmp/stderr.log" >> newfilecron
crontab newfilecron
rm newfilecron

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

