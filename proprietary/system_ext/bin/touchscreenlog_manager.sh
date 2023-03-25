#! /system/bin/sh


config="$1"

function logOn() {
    # set log on command
    echo "touchscreen log on"
}

function logOff() {
    # set log off command
    echo "touchscreen log off"
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
