#! /system/bin/sh

CURTIME=`date +%F_%H-%M-%S`
CURTIME_FORMAT=`date "+%Y-%m-%d %H:%M:%S"`

BASE_PATH=/sdcard/Android/data/com.oplus.olc
SDCARD_LOG_BASE_PATH=${BASE_PATH}/files/Log
DATA_DEBUGGING_PATH=/data/debugging
MTK_DATA_DEBUGGING_PATH=/data/debuglogger
DATA_OPLUS_LOG_PATH=/data/persist_log

config="$1"

#------# collect method #--------------------------------------------------------------------------#
function logcatMain(){
    panicenable=`getprop persist.sys.assert.panic`
    camerapanic=`getprop persist.sys.assert.panic.camera`
    DATA_LOG_APPS_PATH=`getprop sys.oplus.logkit.appslog`
    traceTransferState "logcat main:path=${DATA_LOG_APPS_PATH}, size=${androidSize}, Nums=${androidCount}"
    if [ "${panicenable}" = "true" ] || [ x"${camerapanic}" = x"true" ] && [ "${tmpMain}" != "" ]; then
        logdsize=`getprop persist.logd.size`
        if [ "${logdsize}" = "" ]; then
            /system/bin/logcat -G 5M
        fi

        /system/bin/logcat -f ${DATA_LOG_APPS_PATH}/android.txt -r ${androidSize} -n ${androidCount} -v threadtime -A
    else
        setprop ctl.stop logcat_main
    fi
}

function logcatRadio(){
    panicenable=`getprop persist.sys.assert.panic`
    DATA_LOG_APPS_PATH=`getprop sys.oplus.logkit.appslog`
    echo "logcat radio: radioSize=${radioSize}, radioCount=${radioCount}"
    if [ "${panicenable}" = "true" ] && [ "${tmpRadio}" != "" ]; then
        /system/bin/logcat -b radio -f ${DATA_LOG_APPS_PATH}/radio.txt -r ${radioSize} -n ${radioCount} -v threadtime -A
    else
        setprop ctl.stop logcat_radio
    fi
}

function logcatEvent(){
    panicenable=`getprop persist.sys.assert.panic`
    camerapanic=`getprop persist.sys.assert.panic.camera`
    DATA_LOG_APPS_PATH=`getprop sys.oplus.logkit.appslog`
    echo "logcat event: eventSize=${eventSize}, eventCount=${eventCount}"
    if [ "${panicenable}" = "true" ] || [ x"${camerapanic}" = x"true" ] && [ "${tmpEvent}" != "" ]; then
        /system/bin/logcat -b events -f ${DATA_LOG_APPS_PATH}/events.txt -r ${eventSize} -n ${eventCount} -v threadtime -A
    else
        setprop ctl.stop logcatevent
    fi
}

function logcatKernel(){
    panicenable=`getprop persist.sys.assert.panic`
    camerapanic=`getprop persist.sys.assert.panic.camera`
    DATA_LOG_KERNEL_PATH=`getprop sys.oplus.logkit.kernellog`
    echo "logcat kernel: panicenable=${panicenable} tmpKernel=${tmpKernel}"
    if [ "${panicenable}" = "true" ] || [ x"${camerapanic}" = x"true" ] && [ "${tmpKernel}" != "" ]; then
        /system/system_ext/xbin/klogd -f - -n -x -l 7 | tee - ${DATA_LOG_KERNEL_PATH}/kernel.txt | awk 'NR%400==0'
    fi
}

function dump_bugreport() {
    traceTransferState "bugreport start..."
    bugreportz
}

#------# transfer method #-------------------------------------------------------------------------#
function transferDataVendor(){
    stoptime=`getprop sys.oplus.log.stoptime`
    newpath="${SDCARD_LOG_BASE_PATH}/log@stop@${stoptime}"
    DATA_VENDOR_LOG=/data/persist_log/TMP/vendor
    TARGET_DATA_VENDOR_LOG=${newpath}/data_vendor

    if [ -d  ${DATA_VENDOR_LOG} ]; then
        chmod 777 ${DATA_VENDOR_LOG}/ -R
        ALL_SUB_DIR=`ls ${DATA_VENDOR_LOG}`
        for SUB_DIR in ${ALL_SUB_DIR};do
            if [ -d ${DATA_VENDOR_LOG}/${SUB_DIR} ] || [ -f ${DATA_VENDOR_LOG}/${SUB_DIR} ]; then
                checkNumberSizeAndMove "${DATA_VENDOR_LOG}/${SUB_DIR}" "${TARGET_DATA_VENDOR_LOG}/${SUB_DIR}"
            fi
        done
    fi
}

function transferBugreportLog(){
    DATA_BUGREPORT_PATH=/data/user_de/0/com.android.shell/files/bugreports
    traceTransferState "TRANSFERBUGREORTLOG:mv ${DATA_BUGREPORT_PATH} start"
    if [ -d "${DATA_BUGREPORT_PATH}" ];then
       mkdir -p ${SDCARD_LOG_BASE_PATH}/bugreports
       mv ${DATA_BUGREPORT_PATH}/* ${SDCARD_LOG_BASE_PATH}/bugreports
       traceTransferState "TRANSFERBUGREORTLOG:mv ${DATA_BUGREPORT_PATH} done"
    fi
}

#------# utils method #----------------------------------------------------------------------------#
function initLogSizeAndNums() {
    FreeSize=`df /data | grep /data | awk '{print $4}'`
    GSIZE=`echo | awk '{printf("%d",2*1024*1024)}'`
    traceTransferState "init:data FreeSize:${FreeSize} and GSIZE:${GSIZE}"

    # TODO modified prop to config file
    tmpMain=`getprop persist.sys.log.main`
    tmpRadio=`getprop persist.sys.log.radio`
    tmpEvent=`getprop persist.sys.log.event`
    tmpKernel=`getprop persist.sys.log.kernel`
    tmpTcpdump=`getprop persist.sys.log.tcpdump`
    traceTransferState "init:main=${tmpMain}, radio=${tmpRadio}, event=${tmpEvent}, kernel=${tmpKernel}, tcpdump=${tmpTcpdump}"

    if [ ${FreeSize} -ge ${GSIZE} ]; then
        if [ "${tmpMain}" != "" ]; then
            #get the config size main
            tmpAndroidSize=`set -f;array=(${tmpMain//|/ });echo "${array[0]}"`
            tmpAdnroidCount=`set -f;array=(${tmpMain//|/ });echo "${array[1]}"`
            androidSize=`echo ${tmpAndroidSize} | awk '{printf("%d",$1*1024)}'`
            androidCount=`echo ${FreeSize} 30 50 ${androidSize} | awk '{printf("%d",$1*$2/$3/$4)}'`
            traceTransferState "init:tmpAndroidSize=${tmpAndroidSize}, tmpAdnroidCount=${tmpAdnroidCount}, androidSize=${androidSize}, androidCount=${androidCount}"
            if [ ${androidCount} -ge ${tmpAdnroidCount} ]; then
                androidCount=${tmpAdnroidCount}
            fi
            traceTransferState "init:last androidCount=${androidCount}"
        fi

        if [ "${tmpRadio}" != "" ]; then
            #get the config size radio
            tmpRadioSize=`set -f;array=(${tmpRadio//|/ });echo "${array[0]}"`
            tmpRadioCount=`set -f;array=(${tmpRadio//|/ });echo "${array[1]}"`
            radioSize=`echo ${tmpRadioSize} | awk '{printf("%d",$1*1024)}'`
            radioCount=`echo ${FreeSize} 1 50 ${radioSize} | awk '{printf("%d",$1*$2/$3/$4)}'`
            echo "tmpRadioSize=${tmpRadioSize}; tmpRadioCount=${tmpRadioCount} radioSize=${radioSize} radioCount=${radioCount}"
            if [ ${radioCount} -ge ${tmpRadioCount} ]; then
                radioCount=${tmpRadioCount}
            fi
            echo "last radioCount=${radioCount}"
        fi

        if [ "${tmpEvent}" != "" ]; then
            #get the config size event
            tmpEventSize=`set -f;array=(${tmpEvent//|/ });echo "${array[0]}"`
            tmpEventCount=`set -f;array=(${tmpEvent//|/ });echo "${array[1]}"`
            eventSize=`echo ${tmpEventSize} | awk '{printf("%d",$1*1024)}'`
            eventCount=`echo ${FreeSize} 1 50 ${eventSize} | awk '{printf("%d",$1*$2/$3/$4)}'`
            echo "tmpEventSize=${tmpEventSize}; tmpEventCount=${tmpEventCount} eventSize=${eventSize} eventCount=${eventCount}"
            if [ ${eventCount} -ge ${tmpEventCount} ]; then
                eventCount=${tmpEventCount}
            fi
            echo "last eventCount=${eventCount}"
        fi

        if [ "${tmpTcpdump}" != "" ]; then
            tmpTcpdumpSize=`set -f;array=(${tmpTcpdump//|/ });echo "${array[0]}"`
            tmpTcpdumpCount=`set -f;array=(${tmpTcpdump//|/ });echo "${array[1]}"`
            tcpdumpSize=`echo ${tmpTcpdumpSize} | awk '{printf("%d",$1*1024)}'`
            tcpdumpCount=`echo ${FreeSize} 10 50 ${tcpdumpSize} | awk '{printf("%d",$1*$2/$3/$4)}'`
            echo "tmpTcpdumpSize=${tmpTcpdumpCount}; tmpEventCount=${tmpEventCount} tcpdumpSize=${tcpdumpSize} tcpdumpCount=${tcpdumpCount}"
            ##tcpdump use MB in the order
            tcpdumpSize=${tmpTcpdumpSize}
            if [ ${tcpdumpCount} -ge ${tmpTcpdumpCount} ]; then
                tcpdumpCount=${tmpTcpdumpCount}
            fi
            echo "last tcpdumpCount=${tcpdumpCount}"
        else
            echo "tmpTcpdump is empty"
        fi
    else
        echo "free size is less than 2G"
        androidSize=20480
        androidCount=`echo ${FreeSize} 30 50 ${androidSize} | awk '{printf("%d",$1*$2*1024/$3/$4)}'`
        if [ ${androidCount} -ge 10 ]; then
            androidCount=10
        fi
        radioSize=10240
        radioCount=`echo ${FreeSize} 1 50 ${radioSize} | awk '{printf("%d",$1*$2*1024/$3/$4)}'`
        if [ ${radioCount} -ge 4 ]; then
            radioCount=4
        fi
        eventSize=10240
        eventCount=`echo ${FreeSize} 1 50 ${eventSize} | awk '{printf("%d",$1*$2*1024/$3/$4)}'`
        if [ ${eventCount} -ge 4 ]; then
            eventCount=4
        fi
        tcpdumpSize=50
        tcpdumpCount=`echo ${FreeSize} 10 50 ${tcpdumpSize} | awk '{printf("%d",$1*$2/$3/$4)}'`
        if [ ${tcpdumpCount} -ge 2 ]; then
            tcpdumpCount=2
        fi
    fi

    #LiuHaipeng@NETWORK.DATA.2959182, modify for limit the tcpdump size to 300M and packet size 100 byte for power log type and other log type
    LOG_TYPE=`getprop persist.sys.debuglog.config`
    if [ "${LOG_TYPE}" == "call" ]; then
        tcpdumpPacketSize=0
    elif [ "${LOG_TYPE}" == "network" ];then
        tcpdumpPacketSize=0
    elif [ "${LOG_TYPE}" == "wifi" ];then
        tcpdumpPacketSize=0
    else
        tcpdumpPacketSize=100
        tcpdumpSizeTotal=300
        tcpdumpCount=`echo ${tcpdumpSizeTotal} ${tcpdumpSize} 1 | awk '{printf("%d",$1/$2)}'`
    fi
}

function testTransferSystem(){
    setprop sys.oplus.log.stoptime ${CURTIME}
    stoptime=`getprop sys.oplus.log.stoptime`
    newpath="${SDCARD_LOG_BASE_PATH}/log@stop@${stoptime}"
    mkdir -p ${newpath}
    traceTransferState "${newpath}"

}

function testTransferRoot(){
    setprop sys.oplus.log.stoptime ${CURTIME}
    stoptime=`getprop sys.oplus.log.stoptime`
    newpath="${SDCARD_LOG_BASE_PATH}/log@stop@${stoptime}"
    mkdir -p ${newpath}
    traceTransferState "${newpath}"

}

function logObserver() {
    # 1, data free size
    boot_completed=`getprop sys.boot_completed`
    while [ x${boot_completed} != x"1" ];do
        traceTransferState "log observer:device don't boot completed"
        sleep 10
        boot_completed=`getprop sys.boot_completed`
    done

    FreeSize=`df /data | grep -v Mounted | awk '{print $4}'`
    traceTransferState "LOGOBSERVER:free size ${FreeSize}"

    # 2, count log size
    LOG_CONFIG_FILE="${DATA_OPLUS_LOG_PATH}/config/log_config.log"
    LOG_COUNT_SIZE=0
    if [ -f "${LOG_CONFIG_FILE}" ]; then
        while read -r ITEM_CONFIG
        do
            if [ "" != "${ITEM_CONFIG}" ];then
                #echo "${CURTIME_FORMAT} transfer log config: ${ITEM_CONFIG}"
                SOURCE_PATH=`echo ${ITEM_CONFIG} | awk '{print $2}'`
                if [ -d ${SOURCE_PATH} ];then
                    TEMP_SIZE=`du -s ${SOURCE_PATH} | awk '{print $1}'`
                    if [ "" != "${TEMP_SIZE}" ]; then
                        LOG_COUNT_SIZE=`expr ${LOG_COUNT_SIZE} + ${TEMP_SIZE}`
                    fi
                    traceTransferState "path: ${SOURCE_PATH}, ${TEMP_SIZE}/${LOG_COUNT_SIZE}"
                else
                    echo "${CURTIME_FORMAT} PATH: ${SOURCE_PATH}, No such file or directory"
                fi
            fi
        done < ${LOG_CONFIG_FILE}
    fi

    settings put global logkit_observer_size "${FreeSize}|${LOG_COUNT_SIZE}"
    # settings get global logkit_observer_size
    traceTransferState "LOGOBSERVER:data free and log size: ${FreeSize}|${LOG_COUNT_SIZE}"
}

function traceTransferState() {
    content=$1

    if [[ -d ${BASE_PATH} ]]; then
        if [[ ! -d ${SDCARD_LOG_BASE_PATH} ]]; then
            mkdir -p ${SDCARD_LOG_BASE_PATH}
            chmod 2770 ${BASE_PATH} -R
            echo "${CURTIME_FORMAT} TRACETRANSFERSTATE:${SDCARD_LOG_BASE_PATH} " >> ${SDCARD_LOG_BASE_PATH}/logkit_transfer.log
        fi

        currentTime=`date "+%Y-%m-%d %H:%M:%S"`
        echo "${currentTime} ${content} " >> ${SDCARD_LOG_BASE_PATH}/logkit_transfer.log
    fi

    LOG_LEVEL=$2
    if [[ "${LOG_LEVEL}" == "" ]]; then
        LOG_LEVEL=d
    fi
    log -p ${LOG_LEVEL} -t Debuglog ${content}
}

function clearDebuggingLog() {
    ALWAYSON_ENABLE=`getprop persist.sys.alwayson.enable`
    #/data/debuglogger
    if [ -d ${MTK_DATA_DEBUGGING_PATH} ]; then
        chmod 777 ${MTK_DATA_DEBUGGING_PATH} -R
        if [ "${ALWAYSON_ENABLE}" = "true" ]; then
            ALL_SUB_DIR=`ls ${MTK_DATA_DEBUGGING_PATH} | grep -v mobilelog`
            for SUB_DIR in ${ALL_SUB_DIR};do
                rm -rf ${MTK_DATA_DEBUGGING_PATH}/${SUB_DIR}
                traceTransferState "rm: ${SUB_DIR} done" "v"
            done
        else
            rm -rf ${MTK_DATA_DEBUGGING_PATH}/*
            traceTransferState "rm: ${MTK_DATA_DEBUGGING_PATH}/* done" "v"
        fi
    fi

    #/data/debugging
    if [ -d ${DATA_DEBUGGING_PATH} ]; then
        chmod 777 ${DATA_DEBUGGING_PATH} -R
        if [ "${ALWAYSON_ENABLE}" = "true" ]; then
            ALL_SUB_DIR=`ls ${DATA_DEBUGGING_PATH} | grep -v minilog`
            for SUB_DIR in ${ALL_SUB_DIR};do
                rm -rf ${DATA_DEBUGGING_PATH}/${SUB_DIR}
                traceTransferState "rm: ${SUB_DIR} done" "v"
            done
        else
            rm -rf ${DATA_DEBUGGING_PATH}/*
            traceTransferState "rm: ${DATA_DEBUGGING_PATH}/* done" "v"
        fi
    fi

    #/data/local/traces
    #/data/persist_log/TMP
    #/data/persist_log/hprofdump
    #/sdcard/Android/data/com.oplus.logkit/files/Log/trigger
    DELETE_ELEMENT_PATH=("/data/local/traces"
            "${DATA_OPLUS_LOG_PATH}/TMP"
            "${DATA_OPLUS_LOG_PATH}/hprofdump"
            "${SDCARD_LOG_BASE_PATH}/trigger")
    for ELEMENT in ${DELETE_ELEMENT_PATH[@]}
    do
        if [ -d ${ELEMENT} ]; then
            chmod 777 ${ELEMENT} -R
            rm -rf ${ELEMENT}/*
            traceTransferState "rm: ${ELEMENT}/* done" "v"
        else
            traceTransferState "${ELEMENT} not exist" "w"
        fi
    done

    #recovery
    state=`getprop ro.build.ab_update`
    if [ "${state}" != "true" ] ;then
        rm -rf /cache/recovery/*
    fi

    setprop sys.clear.finished 1
}

function cleanLog(){
    #MTK
    if [[ -d ${MTK_DATA_DEBUGGING_PATH} ]]; then
        chmod 777 ${MTK_DATA_DEBUGGING_PATH} -R
        rm -rf ${MTK_DATA_DEBUGGING_PATH}/*
    fi

    #QCOM
    if [[ -d ${DATA_DEBUGGING_PATH} ]]; then
        chmod 777 ${DATA_DEBUGGING_PATH} -R
        rm -rf ${DATA_DEBUGGING_PATH}/*
    fi

    chmod 777 ${DATA_OPLUS_LOG_PATH}/TMP -R
    rm -rf ${DATA_OPLUS_LOG_PATH}/TMP/*

    rm -rf /cache/admin/*
    rm -rf /data/core/*
    rm -rf /data/anr/*
    rm -rf /data/tombstones/*
    rm -rf /data/system/dropbox/*
    rm -rf /data/misc/bluetooth/logs/*

    setprop sys.clear.finished 1
}

#find ${SDCARD_LOG_BASE_PATH} -name "*${stoptime}*" -maxdepth 1 -exec mv {} ${TARGET_PATH} \;
function moveLog() {
    TARGET_PATH=`getprop persist.sys.olc.target_path`
    PARENT_PATH=$(dirname $(dirname ${TARGET_PATH}))
    if [ ! -d ${TARGET_PATH} ]; then
        mkdir -p ${TARGET_PATH}
        traceTransferState "mkdir ${TARGET_PATH}"
    fi
    chown -R system ${TARGET_PATH}
    chmod 777 ${TARGET_PATH} -R
    mod=`ls -l ${TARGET_PATH}`
    traceTransferState "mod: ${mod}"
    stoptime=`getprop sys.oplus.log.stoptime`
    traceTransferState "get stoptime: ${stoptime}"
    LOG_FILE=$(find ${SDCARD_LOG_BASE_PATH} -maxdepth 1 | grep -E ${stoptime})
    mv ${LOG_FILE} ${TARGET_PATH}
    chown -R system ${PARENT_PATH}
    chmod 777 ${PARENT_PATH} -R
    traceTransferState "move ${LOG_FILE} to ${TARGET_PATH} end"
    if [ -d ${LOG_FILE}]; then
        cp ${LOG_FILE} ${TARGET_PATH}
        traceTransferState "cp again ${LOG_FILE} to ${TARGET_PATH} end"
        rm -rf ${LOG_FILE}
    fi
}

case "$config" in
    "logcat_main")
        initLogSizeAndNums
        logcatMain
        ;;
    "logcat_radio")
        initLogSizeAndNums
        logcatRadio
        ;;
    "test_transfer_system")
        testTransferSystem
    ;;
	"test_transfer_root")
        testTransferRoot
        ;;
    "logcat_event")
        initLogSizeAndNums
        logcatEvent
        ;;
    "logcat_kernel")
        initLogSizeAndNums
        logcatKernel
        ;;
    "transfer_data_vendor")
        transferDataVendor
    ;;
    "dump_bugreport")
        dump_bugreport
    ;;
    "transfer_bugreport")
        transferBugreportLog
        ;;
    "log_observer")
        logObserver
        ;;
    "delete_log")
        clearDebuggingLog
        ;;
    "clean_log")
        cleanLog
        ;;
    "moveLog")
        moveLog
        ;;
    *)
        ;;
esac