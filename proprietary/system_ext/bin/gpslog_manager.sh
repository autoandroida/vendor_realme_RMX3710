#! /system/bin/sh


config="$1"

function logOn() {
    # set log on command
    echo "gps log on"
}

function logOff() {
    # set log off command
    echo "gps log off"
}

case "$config" in
    "logon")
        logOn
        ;;
    "logoff")
        logOff
        ;;
    *)
        ;;
esac
