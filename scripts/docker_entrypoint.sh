#!/bin/bash

function print() {
    echo "[Entrypoint] $@"
}

function quit() {
    ./seafile-server-latest/seahub.sh stop
    ./seafile-server-latest/seafile.sh stop
    exit
}

function timezoneAdjustement() {
    if [ "$TZ" ]
    then
        if [ ! -f "/usr/share/zoneinfo/$TZ" ]
        then
            print "Invalid timezone $TZ"
        else
            ln -sfn "/usr/share/zoneinfo/$TZ" /etc/localtime
            echo "$TIME_ZONE" > /etc/timezone
            print "Local time set to $TZ"
        fi
    fi
}

function rightsManagement() {
    print "Checking permissions"
    if [ -z "$PUID" ]; then
        PUID=$(id -u seafile)
    else
        usermod -u $PUID seafile
    fi

    if [ -z "$PGID" ]; then
        PGID=$(id -g seafile)
    else
        groupmod -g $PGID seafile
    fi

    print "Changing owner of /shared"
    mkdir -p /shared
    chown -R seafile:seafile /shared
}

# Quit when receiving some signals
trap quit SIGTERM
trap quit SIGINT
trap quit SIGKILL

timezoneAdjustement
rightsManagement

if [ ! -f "/shared/conf/ccnet.conf" ]
then
    print "No config found. Running init script"
    su seafile -pPc "/scripts/init.sh"

    if [ $? != 0 ]
    then
        print "Init failed"
        exit 1
    fi
fi

print "Running launch script"
su seafile -pc "/scripts/launch.sh"

print "Waiting for termination"
tail -f /dev/null & wait
