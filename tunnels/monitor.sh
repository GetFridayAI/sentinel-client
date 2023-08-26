#!/bin/sh

while getopts o:c: flag
do
    case "${flag}" in
        o) HOST_OS=${OPTARG};;
        c) CONFIG_PATH=${OPTARG};;
    esac
done

# ENV=$( jq ".env" $CONFIG_PATH | xargs)
# ENV_TYPE=$( jq ".type" $CONFIG_PATH | xargs)

# echo "$ENV"
