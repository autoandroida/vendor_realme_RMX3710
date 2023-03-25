#! /system/bin/sh


config="$1"

function logOn() {
    # set log on command
    echo "power/heat log on"
}

function logOff() {
    # set log off command
    echo "power/heat log off"
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
