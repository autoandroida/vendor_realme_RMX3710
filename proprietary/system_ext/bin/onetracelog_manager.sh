#! /system/bin/sh


config="$1"

function logOn() {
    # set log on command
    echo "onetrace log on"
}

function logOff() {
    # set log off command
    echo "onetrace log off"
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
