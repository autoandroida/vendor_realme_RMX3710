#! /system/bin/sh


config="$1"

DATA_LOG_TCPDUMPLOG_PATH=/data/debugging/netlog
DATA_LOG_TCPDUMPLOG_SIZE_AND_FILE="100|2"

function logOn() {
    # set log on command
    if [[ `getprop ro.hardware` == mt* ]]; then
        logTrace "mtk wlan log on"
    else
        logTrace "qcom wlan log on"
        setprop ctl.start wifidriverlog_always_on
    fi
    # start tcpdump log
    tcpdumpStatus=`getprop init.svc.tcpdumplog`
    logTrace "tcpdumplog state:${tcpdumpStatus}"
    if [[ "${tcpdumpStatus}" != "running" ]];then
        logTrace "start tcpdumplog"
        if [[ -d ${DATA_LOG_TCPDUMPLOG_PATH} ]]; then
            rm -rf ${DATA_LOG_TCPDUMPLOG_PATH}
        fi
        mkdir -p ${DATA_LOG_TCPDUMPLOG_PATH}
        chmod -R 777 ${DATA_LOG_TCPDUMPLOG_PATH}
        setprop sys.oplus.logkit.netlog ${DATA_LOG_TCPDUMPLOG_PATH}
        setprop persist.sys.log.tcpdump ${DATA_LOG_TCPDUMPLOG_SIZE_AND_FILE}
        setprop ctl.start tcpdumplog
    fi
}

function logOff() {
    # set log off command
    if [[ `getprop ro.hardware` == mt* ]]; then
        logTrace "mtk wlan log off"
    else
        logTrace "qcom wlan log off"
        setprop ctl.stop wifidriverlog_always_on
        chmod 0770 /data/vendor/wifi
    fi
    # stop tcpdump log
    setprop ctl.stop tcpdumplog
}

function logTrace() {
    LOG_LEVEL=d
    #echo $1
    log -p ${LOG_LEVEL} -t Debuglog $1
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
