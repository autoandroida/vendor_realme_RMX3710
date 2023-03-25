#! /system/bin/sh

PHOENIX_DRIVER="/proc/phoenix"
DROPBOX_DIR="/data/system/dropbox"
TOMBSTONE_DIR="/data/tombstones"
ANR_TRACE_DIR="/data/anr"
MINIDUMP_DIR="/data/persist_log/DCS/de/minidump"
AEE_DB_DIR="/data/persist_log/DCS/de/AEE_DB"
TIME_BEGIN_TO_COLLECT_LOG=$(date +%s)
SYSTEM_SERVER_CRASH_FILE_PATTERN="system_server_crash"
SYSTEM_SERVER_WATCHDOG_FILE_PATTERN="system_server_watchdog"
PHX_LOG_DIR="/mnt/oplus/op2/media/log/hang_oplus"
BOOT_LOG_DIR="/mnt/oplus/op2/media/log/boot_log"
RBR_LOG_DIR="/mnt/oplus/op2/rbr_log"
OPLUSRESERVE2_MOUNT_POINT="/mnt/oplus/op2"
PHX_LOG_FILE_PATTERN="hang_oplus_log"
BOOT_LOG_FILE_PATTERN="boot_log"
KE_FILE_PATTERN="SYSTEM_LAST_KMSG"
MTK_LAST_KMSG_PROC="/proc/last_kmsg"
MTK_PSTORE_DIR="/sys/fs/pstore"
KE_TAG="KERNEL EXCEPTION HAPPEND"
TIME_NOW_IN_LOCALTIME=$(date +"%Y-%m-%d %T")
TMP_DIR="phoenix_$(date +"%Y%m%d%H%M%S_%N")"
TMP_DIR_FOR_OLC="/data/oplusbootstats/olc_phoenix"
TMP_DIR_nodata="/mnt/oplus/op2/${TMP_DIR}"
TMP_DIR_data="/data/oplusbootstats/${TMP_DIR}"
FILE_LAST_KE_INFO="/mnt/vendor/oplusreserve/phoenix/ERROR_KERNEL_EXCEPTION"
FILE_LAST_KMSG="/mnt/vendor/oplusreserve/phoenix/kmsg"
FILE_FS_MGR_LOG="/mnt/oplus/op2/fs_mgr_log"
PLATFORM=$(getprop ro.board.platform)
HARDWARE=$(getprop ro.hardware)
BOOTTIME="0.0"
OTAFILEPATH="/cache/recovery/intent"
OTA_UPDATE_OK="0"
RECOVER_UPDATE_OK="2"
OPLUSRESERVE2_PARTITION_AVAILABLE=0
MAX_PHX_LOG_COUNT=5
PHX_TIME_INTERVAL=60
DELTA_SPACE=15

ERROR_FUNC_MAP_KEY=("ERROR_HANG_OPLUS"
                    "ERROR_CRITICAL_SERVICE_CRASHED_4_TIMES"
                    "ERROR_REBOOT_FROM_KE_SUCCESS"
                    "ERROR_SYSTEM_SERVER_WATCHDOG"
                    "ERROR_NATIVE_REBOOT_INTO_RECOVERY"
                    "ERROR_GATEKEEPER_ERROR_OPLUS"
                    "ERROR_LAST_BOOT_HANG_BOOTLOADER"
                    "ERROR_LAST_BOOT_COMPLETED_FAIL"
                    )

ERROR_FUNC_MAP_VAL=("collect_hang_oplus_log"
                    "collect_critical_service_crash_4_times_log"
                    "collect_reboot_from_ke_success_log"
                    "collect_system_server_watchdog_log"
                    "collect_native_reboot_into_recovery_log"
                    "collect_gatekeeper_error_oplus_log"
                    "collect_last_boot_hang_bootloader_log"
                    "collect_last_boot_completed_fail_log"
                    )



function phx_native_generate_keyfinfo()
{
    key_info_file=$1
    echo "happen_time: ${TIME_NOW_IN_LOCALTIME}" > ${key_info_file}
    boot_stage=$(cat /proc/phoenix | grep "STAGE" | sed -n '$p')
    echo "boot_stage: ${boot_stage}" >> ${key_info_file}
    echo "boot_time: ${BOOT_TIME:1}" >> ${key_info_file}
    if [ -f ${OTAFILEPATH} ]; then
        ota_result=$(cat ${OTAFILEPATH})
        if [ "${ota_result:0:1}" == "${OTA_UPDATE_OK}" -o "${ota_result:0:1}" == "${RECOVER_UPDATE_OK}" ]; then
            is_boot_from_ota=1
        else
            is_boot_from_ota=0
        fi
    else
        is_boot_from_ota=0
    fi
    echo "is_boot_from_ota: ${is_boot_from_ota}" >> ${key_info_file}
    data_capcity=$(df -h | grep "/data$" | sed 's/[ ][ ]*/,/g' | cut -d "," -f2)
    data_usage=$(df -h | grep "/data$" | sed 's/[ ][ ]*/,/g' | cut -d "," -f3)
    data_left=$(df -h | grep "/data$" | sed 's/[ ][ ]*/,/g' | cut -d "," -f4)
    data_usage_ratio=$(df -h | grep "/data$" | sed 's/[ ][ ]*/,/g' | cut -d "," -f5)
    echo "data_capcity: ${data_capcity}" >> ${key_info_file}
    echo "data_usage: ${data_usage}" >> ${key_info_file}
    echo "data_left: ${data_left}" >> ${key_info_file}
    echo "data_usage_ratio: ${data_usage_ratio}" >> ${key_info_file}
    echo "platform: $PLATFORM" >> ${key_info_file}

    if [ -f "/proc/devinfo/ufs" ]; then
        flash_type="UFS"
    else
        flash_type="EMMC"
    fi
    if [ "${flash_type}" == "UFS" ]; then
        flash_info_file="/proc/devinfo/ufs"
    else
        flash_info_file="/proc/devinfo/emmc"
    fi
    flash_manufacture=$(cat ${flash_info_file} | grep manufacture | cut -d ":" -f2 | sed 's/\t//g')
    flash_version=$(cat ${flash_info_file} | grep version | cut -d ":" -f2 | sed 's/\t//g')
    echo "flash_type: ${flash_type}" >> ${key_info_file}
    echo "flash_manufacture: ${flash_manufacture}" >> ${key_info_file}
    echo "flash_version: ${flash_version}" >> ${key_info_file}
    oplusreserve2_capcity=$(df -h | grep "${OPLUSRESERVE2_MOUNT_POINT}" | sed 's/[ ][ ]*/,/g' | cut -d "," -f2)
    oplusreserve2_usage=$(df -h | grep "${OPLUSRESERVE2_MOUNT_POINT}" | sed 's/[ ][ ]*/,/g' | cut -d "," -f3)
    oplusreserve2_left=$(df -h | grep "${OPLUSRESERVE2_MOUNT_POINT}" | sed 's/[ ][ ]*/,/g' | cut -d "," -f4)
    echo "oplusreserve2_capcity: ${oplusreserve2_capcity}" >> ${key_info_file}
    echo "oplusreserve2_usage: ${oplusreserve2_usage}" >> ${key_info_file}
    echo "oplusreserve2_left: ${oplusreserve2_left}" >> ${key_info_file}
}


function print_dir_filelist()
{
    dir=$1
    list=$2
    echo "dir filelist count ${#list[@]}"
    for val in ${list[*]}
    do
        echo "${val} modiy time: $(stat -c %Y ${dir}/${val})"
    done
}

function check_oplusreserve2_is_available()
{
    log_collect_dir=$1
    #echo $log_collect_dir
    log_pack_size=$(du -sk $log_collect_dir | sed 's/[[:space:]]/,/g' | cut -d "," -f1)
    oplusreserve2_remainsize=$(df -ak | grep "${OPLUSRESERVE2_MOUNT_POINT}" | sed 's/[ ][ ]*/,/g' | cut -d "," -f4)
    echo "check_oplusreserve2_is_available log_pack_size $log_pack_size" > /dev/kmsg
    echo "check_oplusreserve2_is_available oplusreserve2_remainsize $oplusreserve2_remainsize" > /dev/kmsg
    if [ "x$log_pack_size" == "x" -o "x$oplusreserve2_remainsize" == "x" ]; then
        OPLUSRESERVE2_PARTITION_AVAILABLE=0
        return 0
    fi
    log_pack_size=$[$log_pack_size + $DELTA_SPACE]
    #the true left space is less than idol left space,so need remove extra 30M space
    while [ "$oplusreserve2_remainsize" -lt "$log_pack_size" ];
    do
        oldest_file=$(ls -rt ${PHX_LOG_DIR} | sed -n "1p")
        if [ "x$oldest_file" != "x" ] ;
        then
            rm -rf ${PHX_LOG_DIR}/$oldest_file
            #echo "remove ${PHX_LOG_DIR}/$oldest_file"
        else
            OPLUSRESERVE2_PARTITION_AVAILABLE=0
            return 0
        fi
        oplusreserve2_remainsize=$(df -k | grep "/mnt/vendor/oplusreserve" | sed 's/[ ][ ]*/,/g' | cut -d "," -f4)
        echo "check_oplusreserve2_is_available oplusreserve2_remainsize $oplusreserve2_remainsize" > /dev/kmsg
    done
    OPLUSRESERVE2_PARTITION_AVAILABLE=1
}

function remove_the_older_file_if_need()
{
    dir=$1
    file_pattern=$2
    max_file_count=$3
    i=0
    for file in $(ls -rt ${dir}/ | grep ${file_pattern})
    do
        echo "${file}"
        file_list[$i]="${file}"
        ((i++))
    done
    echo "file list count ${#file_list[@]} max_file_count $max_file_count"
    print_dir_filelist ${dir} "${file_list[*]}"
    file_count=${#file_list[@]}
    if [ ${file_count} -lt ${max_file_count} ]; then
        return 0
    else
        ((file_need_remove_count=${file_count} - ${max_file_count} + 1))
        echo "file_need_remove_count=${file_need_remove_count}"
        for j in $(seq 1 ${file_need_remove_count})
        do
            echo "will remove ${file_list[(($j-1))]}"
            rm -f ${dir}/${file_list[(($j-1))]}
        done
    fi
    return 0
}

function is_file_modify_in_the_past_interval()
{
    file=$1
    base_time=$2
    interval=$3
    file_modify_time=$(stat -c %Y ${file})
    echo "latest_file=${file} modify_time=${file_modify_time}" > /dev/zero
    ((time_past=${base_time} - ${file_modify_time}))
    echo "time_past = $time_past" > /dev/zero
    if [ ${time_past} -lt ${interval} ];
    then
        return 1
    fi
    return 0
}

function search_latest_file_with_pattern()
{
    search_dir=$1
    search_pattern=$2
    file=$(ls -t ${search_dir} | grep ${search_pattern}| sed -n "1p")
    echo ${file}

}

function search_latest_file()
{
    search_dir=$1
    file=$(ls -t ${search_dir} | sed -n "1p")
    echo ${file}
}

function collect_atrace_log()
{
    cat /proc/interrupts > ${1}/interrupts_before_ftrace.txt
	atrace irq sched -b 32768 -t 30 | head -n 600000 > ${1}/ftrace.txt &
    sleep 30

    tar -czvf ${1}/ftrace.tz ${1}/ftrace.txt
    rm -f ${1}/ftrace.txt
    cat /proc/interrupts > ${1}/interrupts_after_ftrace.txt
}

function is_euex_product() {
  #region="`getprop ro.oplus.image.my_heytap.type`"
  region="`getprop ro.oplus.pipeline.region`"
  if [ "${region}" == "EUEX" ]; then
    echo "BE CAREFUL ... EUEX Enter !"
    return 1
  else
    return 0
  fi
}

function collect_basic_log()
{
    echo w > /proc/sysrq-trigger
    echo l > /proc/sysrq-trigger
    dmesg > ${1}/dmesg.txt
    BOOT_TIME=$(cat ${1}/dmesg.txt | sed -n '$p' | cut -d "]" -f1 | sed 's/ //g')
    # in some case, logcat will hang, so we collect android log to backgroud
    logcat -b crash -b main -b system -d -v threadtime > ${1}/android.txt &
    is_euex_product
    if [ "$?" == "0" ]; then
        logcat -b radio -d -v threadtime > ${1}/radio.txt &
    fi
    logcat -b events -d -v threadtime > ${1}/events.txt &
    if [ -f ${FILE_FS_MGR_LOG} ]; then
        cp ${FILE_FS_MGR_LOG} ${1}
    fi
    sleep 3
}


function collect_binder_transition_log()
{
    cat /d/binder/transactions > ${1}/binder_transaction.txt
    cat /d/binder/state > ${1}/binder_state.txt
}

function collect_auxiliary_log()
{
    ps -AT > ${1}/ps_thread.txt
    mount > ${1}/mount.txt
    cp /data/system/packages.xml ${1}/packages.xml
    cat /proc/meminfo > ${1}/proc_meminfo.txt
    #cat /d/ion/heaps/system > ${1}/iom_system_heaps.txt
    df -k > ${1}/df.txt
    getprop > ${1}/props.txt

}

function collect_native_trace_log()
{
    process_name=$1
    file_save_dir=$2
    pid=$(pidof ${process_name})
    echo "process_name = $process_name pid = $pid"
    if [ "${pid}" == "" ];
    then
        echo "${process_name} not runing"
        return 0
    fi
    debuggerd -b ${pid} > ${file_save_dir}/${process_name}_bt.txt
    for child_tid in $(ls /proc/${pid}/task)
    do
        echo "--------- tid = ${child_tid} ---------" >> ${file_save_dir}/${process_name}_bt.txt
        cat /proc/${pid}/task/${child_tid}/stack >> ${file_save_dir}/${process_name}_bt.txt
        echo >> ${file_save_dir}/${process_name}_bt.txt
    done
}

function collect_system_server_trace_log()
{
    file_save_dir=$1
    #system_server_pid=$(pidof system_server)
    #kill -3 ${system_server_pid}
    sleep 10
    system_server_trace_file=$(search_latest_file ${ANR_TRACE_DIR})
    cp -a ${ANR_TRACE_DIR}/${system_server_trace_file} ${file_save_dir}/system_server_bt.txt
}

function search_latest_file_in_dropbox()
{
    file_pattern=$1
    time_begin=$2
    time_interval=$3
    latest_file=$(search_latest_file_with_pattern ${DROPBOX_DIR} ${file_pattern})
    if [ "${latest_file}" != "" ] ;
    then
        latest_file_full_path=${DROPBOX_DIR}/${latest_file}
        is_file_modify_in_the_past_interval ${latest_file_full_path} ${time_begin} ${time_interval}
        if [ "$?" == "1" ] ;
        then
            echo ${latest_file}
        fi
    fi
    echo ""
}

function collect_system_server_crash_log()
{
    file_save_dir=$1
    system_server_crash_log=$(search_latest_file_in_dropbox ${SYSTEM_SERVER_CRASH_FILE_PATTERN} ${TIME_BEGIN_TO_COLLECT_LOG} ${PHX_TIME_INTERVAL})
    if [ "${system_server_crash_log}" != "" ] ;
    then
        cp -a ${DROPBOX_DIR}/${system_server_crash_log} ${file_save_dir}/${system_server_crash_log}
    fi
}


function collect_critical_service_tombstone_log()
{
    file_save_dir=$1
    critical_service_tombstone_log=$(search_latest_file ${TOMBSTONE_DIR})
    if [ "${critical_service_tombstone_log}" != "" ] ;
    then
        critical_service_tombstone_log_full_path=${TOMBSTONE_DIR}/${critical_service_tombstone_log}
        is_file_modify_in_the_past_interval ${critical_service_tombstone_log_full_path} ${TIME_BEGIN_TO_COLLECT_LOG} PHX_TIME_INTERVAL
        if [ "$?" == "1" ] ;
        then
            cp -a ${TOMBSTONE_DIR}/${critical_service_tombstone_log} ${file_save_dir}/${critical_service_tombstone_log}
        fi
    fi
}


function collect_reboot_from_ke_success_log_for_qcom()
{
    tmp_dir=$1
    ke_log=$(search_latest_file_with_pattern ${MINIDUMP_DIR} ${KE_FILE_PATTERN})
    if [ "x${ke_log}" != "x" ]; then
        cp -a  ${MINIDUMP_DIR}/${ke_log} ${tmp_dir}/${ke_log}
        phx_native_generate_keyfinfo ${tmp_dir}/ERROR_KERNEL_EXCEPTION
    fi
}

function collect_reboot_from_ke_success_log_for_mtk()
{
    tmp_dir=$1
    PROC_LAST_KMSG="/proc/last_kmsg"
    PHX_KE_MARK="PHX_KE_HAPPEND"
    is_boot_from_phx_ke=$(cat ${PROC_LAST_KMSG} | grep ${PHX_KE_MARK})
    PSTORE_LAST_KMSG="/data/persist_log/pstore/pstore_last_kmsg"
    is_boot_from_pstore_ke=$(cat ${PSTORE_LAST_KMSG} | grep ${PHX_KE_MARK})
    if [ "x${is_boot_from_phx_ke}" != "x" ]; then
        cat ${PROC_LAST_KMSG} > ${tmp_dir}/last_kmsg
        #dd if=/dev/block/by-name/expdb of=${tmp_dir}/expdb
        echo ${TIME_NOW_IN_LOCALTIME} > ${tmp_dir}/ERROR_KERNEL_EXCEPTION
    elif [ "x${is_boot_from_pstore_ke}" != "x" ]; then
        cat ${PSTORE_LAST_KMSG} > ${tmp_dir}/last_kmsg
        #dd if=/dev/block/by-name/expdb of=${tmp_dir}/expdb
        echo ${TIME_NOW_IN_LOCALTIME} > ${tmp_dir}/ERROR_KERNEL_EXCEPTION
    fi
}

function collect_reboot_from_ke_success_log()
{
    if [ "x${HARDWARE}" == "xqcom" ]; then
        collect_reboot_from_ke_success_log_for_qcom $1
    else
        collect_reboot_from_ke_success_log_for_mtk $1
    fi
}

function collect_system_server_watchdog_log()
{
    tmp_dir=$1
    #collect_atrace_log ${tmp_dir}
    collect_basic_log ${tmp_dir}
    collect_auxiliary_log ${tmp_dir}
    system_server_watchdog_log=$(search_latest_file_in_dropbox ${SYSTEM_SERVER_WATCHDOG_FILE_PATTERN} ${TIME_BEGIN_TO_COLLECT_LOG} ${PHX_TIME_INTERVAL})
    if [ "${system_server_watchdog_log}" != "" ] ;
    then
        cp -a ${DROPBOX_DIR}/${system_server_watchdog_log} ${tmp_dir}/${system_server_watchdog_log}
    fi
    phx_native_generate_keyfinfo ${tmp_dir}/ERROR_SYSTEM_SERVER_WATCHDOG
}

function collect_critical_service_crash_4_times_log()
{
    tmp_dir=$1
    sleep 3
    collect_basic_log ${tmp_dir}
    collect_auxiliary_log ${tmp_dir}
    collect_system_server_crash_log ${tmp_dir}
    collect_critical_service_tombstone_log ${tmp_dir}
    phx_native_generate_keyfinfo ${tmp_dir}/ERROR_CRITICAL_SERVICE_CRASHED_4_TIMES
}

function collect_native_reboot_into_recovery_log()
{
    tmp_dir=$1
    dmesg > ${RBR_LOG_DIR}/last_init_boot_failed.log
    logcat -b crash -d > ${RBR_LOG_DIR}/last_system_boot_failed.log &
    collect_basic_log ${tmp_dir}
    collect_auxiliary_log ${tmp_dir}
    phx_native_generate_keyfinfo ${tmp_dir}/ERROR_NATIVE_REBOOT_INTO_RECOVERY
}

function collect_last_boot_hang_bootloader_log()
{
    tmp_dir=$1
    PHOENIX2_LOG_DEV="/dev/block/by-name/oplusreserve5"
    dd if=${PHOENIX2_LOG_DEV} of=${tmp_dir}/oplusreserve5
    phx_native_generate_keyfinfo ${tmp_dir}/ERROR_LAST_BOOT_HANG_BOOTLOADER
    phx_native_generate_keyfinfo ${tmp_dir}/uefi_nobootcount_$(getprop sys.oplus.phoenix.uefi_nobootcount)
}

function collect_last_boot_completed_fail_log()
{
    tmp_dir=$1
    PHOENIX2_LOG_DEV="/dev/block/by-name/oplusreserve5"
    dd if=${PHOENIX2_LOG_DEV} of=${tmp_dir}/oplusreserve5
    phx_native_generate_keyfinfo ${tmp_dir}/ERROR_LAST_BOOT_COMPLETED_FAIL
    phx_native_generate_keyfinfo ${tmp_dir}/kernel_nobootcount_$(getprop sys.oplus.phoenix.kernel_nobootcount)
}

function collect_hang_oplus_log()
{
    tmp_dir=$1
	#collect_atrace_log ${tmp_dir}
    collect_basic_log ${tmp_dir}
    collect_auxiliary_log ${tmp_dir}
    #collect_binder_transition_log ${tmp_dir}
    collect_system_server_trace_log ${tmp_dir}
    collect_native_trace_log "surfaceflinger" ${tmp_dir}
    collect_native_trace_log "installd" ${tmp_dir}
    collect_native_trace_log "dex2oat" ${tmp_dir}
    phx_native_generate_keyfinfo ${tmp_dir}/ERROR_HANG_OPLUS
}

function collect_gatekeeper_error_oplus_log()
{
    tmp_dir=$1
    #collect_atrace_log ${tmp_dir}
    collect_basic_log ${tmp_dir}
    phx_native_generate_keyfinfo ${tmp_dir}/ERROR_GATEKEEPER_ERROR_OPLUS
}

function phx_log_native_helper_main()
{
    echo "TIME_BEGIN_TO_COLLECT_LOG=${TIME_BEGIN_TO_COLLECT_LOG}"
    phx_error=$1

    if [ ${phx_error} == "ERROR_NATIVE_REBOOT_INTO_RECOVERY" ];
    then
        collect_tmp_dir=${TMP_DIR_nodata}
    else
        collect_tmp_dir=${TMP_DIR_data}
    fi
    if [ ! -d ${OPLUSRESERVE2_MOUNT_POINT} ] ;
    then
        sleep 5
    fi
    if [ ! -d ${OPLUSRESERVE2_MOUNT_POINT} ] ;
    then
        echo "[PHOENIX] oplusreserve2 not mount!" > /dev/kmsg
        return 0
    fi
    if [ ! -d ${PHX_LOG_DIR} ];
    then
        mkdir -p ${PHX_LOG_DIR}
    fi
    rm -rf ${collect_tmp_dir}
    mkdir -m 0777 ${collect_tmp_dir}
    echo "phx error $phx_error"
    for i in $(seq 1 ${#ERROR_FUNC_MAP_KEY[@]})
    do
        if [ ${phx_error} == ${ERROR_FUNC_MAP_KEY[(($i-1))]} ] ;
        then
            echo "matched will run ${ERROR_FUNC_MAP_VAL[(($i-1))]}"
            ${ERROR_FUNC_MAP_VAL[(($i-1))]} ${collect_tmp_dir}
           if [ "x$(getprop sys.olc.service.on)" == "xtrue" ];then
           rm -rf ${TMP_DIR_FOR_OLC}
           mkdir -m 0770 ${TMP_DIR_FOR_OLC}
           cp -rf ${collect_tmp_dir}/* ${TMP_DIR_FOR_OLC}
           fi
            file_count=$(ls -A ${collect_tmp_dir} | wc -w)
            if [ ${file_count} -gt 0 ] ;
            then
                cp -R ${BOOT_LOG_DIR} ${collect_tmp_dir}/OnBootLog
                remove_the_older_file_if_need ${PHX_LOG_DIR} ${PHX_LOG_FILE_PATTERN} ${MAX_PHX_LOG_COUNT}
                check_oplusreserve2_is_available  ${collect_tmp_dir}
                echo "[PHOENIX]phx_log_native_helper_main OPLUSRESERVE2_PARTITION_AVAILABLE=$OPLUSRESERVE2_PARTITION_AVAILABLE" > /dev/kmsg
                if [ "$OPLUSRESERVE2_PARTITION_AVAILABLE" == "1" ] ;
                then
                    cd ${collect_tmp_dir}/../
                    TAR_DIR="${PHX_LOG_DIR}/${PHX_LOG_FILE_PATTERN}_$(date +%F-%H-%M-%S).tz"
                    echo ${TAR_DIR} > /dev/kmsg
                    tar -czvf ${TAR_DIR}  ${TMP_DIR}
                    cd -
                fi
            else
                rm -rf ${collect_tmp_dir}
                exit 0
            fi
        fi
    done
    if [ "${phx_error}" == "ERROR_REBOOT_FROM_KE_SUCCESS" -a "x${HARDWARE}" == "xqcom" ]; then
        setprop sys.oplus.phoenix.prepare_log "reboot_from_ke_success"
    fi
    rm -rf ${collect_tmp_dir}
    chmod 0777 ${TAR_DIR}
    chgrp -R system ${TAR_DIR}
    chown -R system ${TAR_DIR}
    #chmod -R 0770 ${PHX_LOG_DIR}
    #chgrp -R system ${PHX_LOG_DIR}
    #chown -R system ${PHX_LOG_DIR}
}

if [ -f ${PHOENIX_DRIVER} ]; then
    phx_log_native_helper_main $1
fi
