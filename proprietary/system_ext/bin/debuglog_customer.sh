#! /system/bin/sh

CUSTOMER_LOG_PATH_DEFAULT=/data/persist_log/TMP/customerlog

config="$1"

function customerMain() {
    initCustomerPath
    /system/bin/logcat -f ${CUSTOMER_LOG_PATH}/android.txt -r 10240 -n 5 -v threadtime *:V
}

function customerEvent() {
    initCustomerPath
    /system/bin/logcat -b events -f ${CUSTOMER_LOG_PATH}/event.txt -r 10240 -n 5 -v threadtime *:V
}

function customerRadio() {
    initCustomerPath
    /system/bin/logcat -b radio -f ${CUSTOMER_LOG_PATH}/radio.txt -r 10240 -n 5 -v threadtime *:V
}

function customerKernel() {
    initCustomerPath
    dmesg > ${CUSTOMER_LOG_PATH}/dmesg.txt
    /system/system_ext/xbin/klogd -f - -n -x -l 7 | tee - ${CUSTOMER_LOG_PATH}/kernel.txt | awk 'NR%400==0'
}

function customerTcpdump() {
    initCustomerPath
    tcpdump -i any -p -s 0 -W 1 -C 50 -w ${CUSTOMER_LOG_PATH}/tcpdump.pcap
}

function initCustomerPath() {
    CUSTOMER_LOG_PATH=${CUSTOMER_LOG_PATH_DEFAULT}
    if [[ ! -d  ${CUSTOMER_LOG_PATH} ]]; then
        mkdir -p ${CUSTOMER_LOG_PATH}
        chmod 775 ${CUSTOMER_LOG_PATH} -R
    fi
}

function chmodCustomerPath() {
    chown system:root ${CUSTOMER_LOG_PATH_DEFAULT} -R
    chmod 777 ${CUSTOMER_LOG_PATH_DEFAULT} -R
}

case "$config" in
    "customer_main")
        customerMain
        ;;
    "customer_event")
        customerEvent
        ;;
    "customer_radio")
        customerRadio
        ;;
    "customer_kernel")
        customerKernel
        ;;
    "customer_tcpdump")
        customerTcpdump
        ;;
   "chmod_customer_path")
        chmodCustomerPath
        ;;
    *)
        ;;
esac
