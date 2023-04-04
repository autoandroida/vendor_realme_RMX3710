#! /system/bin/sh

ATOMIC_LOG_PATH_DEFAULT=/data/persist_log/TMP/atomiclog
ATOMIC_SELF_LOG_FILE=atomic_shell.log

ANR_LOG_PATH=/data/anr
DROPBOX_LOG_PATH=/data/system/dropbox

config="$1"

function atomicLogInit() {
    ATOMIC_LOG_PATH=`getprop persist.sys.log.atomic_path`
    if [ "" == "${ATOMIC_LOG_PATH}" ] || [ ! -d ${ATOMIC_LOG_PATH} ]; then
        ATOMIC_LOG_PATH=${ATOMIC_LOG_PATH_DEFAULT}
        if [ ! -d ${ATOMIC_LOG_PATH} ]; then
            mkdir -p ${ATOMIC_LOG_PATH}
        fi
        setprop persist.sys.log.atomic_path ${ATOMIC_LOG_PATH}
    fi
    #traceTransferState "atomicLogInit done ${ATOMIC_LOG_PATH}"
}

function atomicLogMain(){
    atomicLogInit

    /system/bin/logcat -f ${ATOMIC_LOG_PATH}/android.txt -r 10240 -n 5 -v threadtime *:V
}

function atomicLogEvent(){
    atomicLogInit

    /system/bin/logcat -f ${ATOMIC_LOG_PATH}/event.txt -r 10240 -n 5 -v threadtime *:V
}

function atomicLogRadio(){
    atomicLogInit

    /system/bin/logcat -f ${ATOMIC_LOG_PATH}/radio.txt -r 10240 -n 5 -v threadtime *:V
}

function atomicLogKernel(){
    atomicLogInit

    /system/system_ext/xbin/klogd -f - -n -x -l 7 | tee - ${ATOMIC_LOG_PATH}/kernel.txt | awk 'NR%400==0'
}

function atomicLogAnr() {
    atomicLogInit

    if [ -d ${ANR_LOG_PATH} ]; then
        cp -r ${ANR_LOG_PATH} ${ATOMIC_LOG_PATH}
    else
        traceTransferState "${ANR_LOG_PATH} does not exist"
    fi
}

function atomicLogDropbox() {
    atomicLogInit

    #allow debuglog dropbox_data_file:dir { open read search getattr };
    #allow debuglog dropbox_data_file:file { open read };
    if [ -d ${DROPBOX_LOG_PATH} ]; then
        cp -r ${DROPBOX_LOG_PATH} ${ATOMIC_LOG_PATH}
        log -p i -t debuglog "transfer ${DROPBOX_LOG_PATH} done"
    else
        log -p e -t debuglog "${DROPBOX_LOG_PATH} does not exist"
    fi
}

function atomicLogBootloader() {
    atomicLogInit

    QSEE_LOG_DEBUG_NODE=/proc/boot_dmesg
    if [ -f ${QSEE_LOG_DEBUG_NODE} ]; then
        echo ${QSEE_LOG_DEBUG_NODE}
        ATOMIC_QSEE_LOG_PATH=${ATOMIC_LOG_PATH}/bootloader
        if [ ! -d  ${ATOMIC_QSEE_LOG_PATH} ]; then
            mkdir -p ${ATOMIC_QSEE_LOG_PATH}
        fi
        dmesg > ${ATOMIC_QSEE_LOG_PATH}/dmesg.txt
        cat ${QSEE_LOG_DEBUG_NODE} > ${ATOMIC_QSEE_LOG_PATH}/bootloader.txt
    else
        echo "${QSEE_LOG_DEBUG_NODE} does not exist"
    fi
}

function atomicLogRecovery() {
    atomicLogInit

    #allow mvrecoverylog debuglog_data_file:dir { add_name create getattr search write };
    #allow mvrecoverylog debuglog_data_file:file { create };
    #allow mvrecoverylog debug_data_file:dir { getattr search write add_name };
    #allow mvrecoverylog debug_data_file:file { append create open add_name };
    RECOVERY_LOG_PATH=/cache/recovery
    if [[ -d ${RECOVERY_LOG_PATH} ]]; then
        ATOMIC_RECOVERY_LOG_PATH=${ATOMIC_LOG_PATH}/recovery
        traceTransferState "transfer 1-1 ${ATOMIC_RECOVERY_LOG_PATH}"
        if [[ ! -d ${ATOMIC_RECOVERY_LOG_PATH} ]]; then
            mkdir -p ${ATOMIC_RECOVERY_LOG_PATH}
            traceTransferState "transfer 1-2 mkdir ${ATOMIC_RECOVERY_LOG_PATH}"
        fi

        mv ${RECOVERY_LOG_PATH}/* ${ATOMIC_RECOVERY_LOG_PATH}
        traceTransferState "transfer 1-3 ${RECOVERY_LOG_PATH} done"
    else
        traceTransferState "${RECOVERY_LOG_PATH} does not exit"
    fi
}

# ring buffer start && stop
function atomicLogQsee() {
    atomicLogInit

    QSEE_LOG_DEBUG_NODE=/sys/kernel/debug/tzdbg/qsee_log
    QSEE_LOG_NODE=/proc/tzdbg/qsee_log
    if [ -f ${QSEE_LOG_DEBUG_NODE} ] || [ -f ${QSEE_LOG_NODE} ] ; then
        ATOMIC_QSEE_LOG_PATH=${ATOMIC_LOG_PATH}/qsee
        if [ ! -d  ${ATOMIC_QSEE_LOG_PATH} ]; then
            mkdir -p ${ATOMIC_QSEE_LOG_PATH}
        fi

        if [ -f ${QSEE_LOG_DEBUG_NODE} ]; then
            cat ${QSEE_LOG_DEBUG_NODE} > ${ATOMIC_QSEE_LOG_PATH}/qsee_debug.txt
        fi
        if [ -f ${QSEE_LOG_NODE} ]; then
            cat ${QSEE_LOG_NODE} > ${ATOMIC_QSEE_LOG_PATH}/qsee.txt
        fi
    else
        echo "${QSEE_LOG_DEBUG_NODE} or ${QSEE_LOG_NODE} does not exit"
    fi
}

function transferMtkLog() {
    atomicLogInit

    MTK_LOG_PATH=/data/debuglogger/mobilelog
    if [[ -d ${MTK_LOG_PATH} ]]; then
        mv ${MTK_LOG_PATH} ${ATOMIC_LOG_PATH}
        traceTransferState "transferMtkLog 1-1 ${MTK_LOG_PATH} done"
    else
        traceTransferState "transferMtkLog 1-2 ${MTK_LOG_PATH} does not exit"
    fi
}

function clearAtomicLog() {
    MTK_LOG_PATH=/data/debuglogger/mobilelog
    if [[ -d ${MTK_LOG_PATH} ]]; then
        rm -rf ${MTK_LOG_PATH}
    fi

    CLEAR_LOG_PATH=`getprop persist.sys.log.atomic_path`
    if [[ -d ${CLEAR_LOG_PATH} ]]; then
        rm -rf ${CLEAR_LOG_PATH}
    fi
}

function traceTransferState() {
    if [[ ! -d ${ATOMIC_LOG_PATH_DEFAULT} ]]; then
        mkdir ${ATOMIC_LOG_PATH_DEFAULT}
        echo "${CURTIME_FORMAT} TRACETRANSFERSTATE:${ATOMIC_LOG_PATH_DEFAULT} " >> ${ATOMIC_LOG_PATH_DEFAULT}/${ATOMIC_SELF_LOG_FILE}
    fi

    content=$1
    currentTime=`date "+%Y-%m-%d %H:%M:%S"`
    echo "${currentTime} ${content} " >> ${ATOMIC_LOG_PATH_DEFAULT}/${ATOMIC_SELF_LOG_FILE}
}

case "$config" in
    "atomic_log_main")
        atomicLogMain
        ;;
    "atomic_log_event")
        atomicLogEvent
        ;;
    "atomic_log_radio")
        atomicLogRadio
        ;;
	"atomic_log_kernel")
        atomicLogKernel
        ;;
	"atomic_log_anr")
        atomicLogAnr
        ;;
	"atomic_log_dropbox")
        atomicLogDropbox
        ;;
    "atomic_log_bootloader")
        atomicLogBootloader
        ;;
    "atomic_log_recovery")
        atomicLogRecovery
        ;;
    "atomic_log_qsee")
        atomicLogQsee
        ;;
    "transfer_mtk_log")
        transferMtkLog
        ;;
    "clear_atomic_log")
        clearAtomicLog
        ;;
    *)
        ;;
esac