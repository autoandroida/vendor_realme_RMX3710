#! /system/bin/sh

LOG_DEV="/dev/block/by-name/opporeserve3"
SHD_LOG_DIR="/mnt/oplus/op2/media/log/shutdown"
SHD_LOG_FILE_PATTERN="shutdown_log"
ANR_TRACE_DIR="/data/anr"
SYSTEM_SERVER_OFFSET=60
MAX_SHD_LOG_COUNT=8

TMP_DIR="/data/oplusbootstats/shutdown_$(date +"%Y%m%d%H%M%S_%N")"
TMP_DIR_FOR_OLC="/data/oplusbootstats/shutdown_olc"
TIME_BEGIN_TO_COLLECT_LOG=$(date +%s)

ERROR_FUNC_MAP_KEY=("GET_ANDROID_LOG"
                       "SHUTDOWN_LOG_BACK"
                       "SHUTDOWN_LOG_BACK_FOR_OLC"
                      )

ERROR_FUNC_MAP_VAL=("collect_android_log"
                       "back_shutdown_log"
                       "back_shutdown_log_for_olc"
                      )

function kernel_version_check()
{
    MAJOR_VERSION=$(uname -r | awk -F '.' '{print $1}')
    MINOR_VERSION=$(uname -r | awk -F '.' '{print $2}')

    if [ $MAJOR_VERSION -ge 5 ] && [ $MINOR_VERSION -ge 10 ] || [ $MAJOR_VERSION -ge 6 ] ; then
        return 1
    else
	return 0
    fi
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

function search_latest_file()
{
    search_dir=$1
    file=$(ls -t ${search_dir} | sed -n "1p")
    echo ${file}
}

function collect_system_server_trace_log()
{
    system_server_pid=$(pidof system_server)
    if [ "${system_server_pid}" != "" ]; then
        kill -3 ${system_server_pid}
        sleep 10
        system_server_trace_file=$(search_latest_file ${ANR_TRACE_DIR})
        if [ -e /dev/block/by-name/oplusreserve3 ]; then
            LOG_DEV="/dev/block/by-name/oplusreserve3"
        #liuchanghong@BSP.Kernel.Driver, 2021/10/18 add for op8 reserve
        elif [ -e /dev/block/by-name/reserve3 ]; then
            SYSTEM_SERVER_OFFSET=10
            LOG_DEV="/dev/block/by-name/reserve3"
        else
            LOG_DEV="/dev/block/by-name/opporeserve3"
        fi
        dd if=${ANR_TRACE_DIR}/${system_server_trace_file} of=${LOG_DEV} bs=1m seek=${SYSTEM_SERVER_OFFSET}
    fi
}

function collect_android_log()
{
    echo w > /proc/sysrq-trigger
    echo l > /proc/sysrq-trigger
    dd if=dev/zero of=sdcard/zero4 bs=1m count=4
    dd if=dev/zero of=sdcard/zero15 bs=1m count=15
    if [ -e /dev/block/by-name/oplusreserve3 ]; then
        dd if=sdcard/zero15 of=dev/block/by-name/oplusreserve3
        dd if=sdcard/zero4 of=dev/block/by-name/oplusreserve3 bs=1m seek=${SYSTEM_SERVER_OFFSET}
        LOG_DEV="/dev/block/by-name/oplusreserve3"
    #liuchanghong@BSP.Kernel.Driver, 2021/10/18 add for op8 reserve
    elif [ -e /dev/block/by-name/reserve3 ]; then
        SYSTEM_SERVER_OFFSET=10
        dd if=sdcard/zero15 of=dev/block/by-name/reserve3 bs=1m count=9
        dd if=sdcard/zero4 of=dev/block/by-name/reserve3 bs=1m seek=${SYSTEM_SERVER_OFFSET}
        LOG_DEV="/dev/block/by-name/reserve3"
        logcat --buffer-size=3M
    else
        dd if=sdcard/zero15 of=dev/block/by-name/opporeserve3
        dd if=sdcard/zero4 of=dev/block/by-name/opporeserve3 bs=1m seek=${SYSTEM_SERVER_OFFSET}
        LOG_DEV="/dev/block/by-name/opporeserve3"
    fi

    rm -rf sdcard/zero15
    rm -rf sdcard/zero4
    logcat -b crash -b main -b system -d > ${LOG_DEV}

    kernel_version_check
    version_check=$?
    if [ $version_check == "1" ]; then
        # Handle Shutdown magic number
        dd if=dev/zero of=${LOG_DEV} bs=1 count=16
        echo "ShutDown" > /data/persist_log/oplusreserve/media/log/shutdown/shutdown_magic
        dd if=/data/persist_log/oplusreserve/media/log/shutdown/shutdown_magic of=${LOG_DEV} bs=8
        echo -n -e '\x9B' > /data/persist_log/oplusreserve/media/log/shutdown/ShutdownTo
        dd if=/data/persist_log/oplusreserve/media/log/shutdown/ShutdownTo of=${LOG_DEV} bs=4 seek=2
        rm -rf /data/persist_log/oplusreserve/media/log/shutdown/shutdown_magic
        rm -rf /data/persist_log/oplusreserve/media/log/shutdown/ShutdownTo

        # Handle kmsg dump
        dmesg > /data/persist_log/oplusreserve/media/log/shutdown/temp_dmesg
        dd if=/data/persist_log/oplusreserve/media/log/shutdown/temp_dmesg of=${LOG_DEV} bs=1m seek=61
        rm -rf /data/persist_log/oplusreserve/media/log/shutdown/temp_dmesg
    fi

    #collect_system_server_trace_log
}

function back_shutdown_log()
{
    echo "TIME_BEGIN_TO_COLLECT_LOG=${TIME_BEGIN_TO_COLLECT_LOG}"
    collect_tmp_dir=${TMP_DIR}
    #if [ ! -d ${SHD_LOG_DIR} ];
    #then
    #    mkdir -p ${SHD_LOG_DIR}
    #fi
    rm -rf ${collect_tmp_dir}
    mkdir -m 0770 ${collect_tmp_dir}

    if [ -e /dev/block/by-name/oplusreserve3 ]; then
        LOG_DEV="/dev/block/by-name/oplusreserve3"
    #liuchanghong@BSP.Kernel.Driver, 2021/10/18 add for op8 reserve
    elif [ -e /dev/block/by-name/reserve3 ]; then
        LOG_DEV="/dev/block/by-name/reserve3"
    else
        LOG_DEV="/dev/block/by-name/opporeserve3"
    fi

    dd if=${LOG_DEV} of=${collect_tmp_dir}/opporeserve3

    file_count=$(ls -A ${collect_tmp_dir} | wc -w)
    if [ ${file_count} -gt 0 ] ;
    then
        remove_the_older_file_if_need ${SHD_LOG_DIR} ${SHD_LOG_FILE_PATTERN} ${MAX_SHD_LOG_COUNT}
        tar -czvf ${SHD_LOG_DIR}/${SHD_LOG_FILE_PATTERN}_$(date +%F-%H-%M-%S).tz  ${collect_tmp_dir}/*
              rm -rf ${collect_tmp_dir}
    fi
}

function back_shutdown_log_for_olc()
{
    echo "TIME_BEGIN_TO_COLLECT_LOG=${TIME_BEGIN_TO_COLLECT_LOG}"
    collect_tmp_dir=${TMP_DIR_FOR_OLC}

    rm -rf ${collect_tmp_dir}
    mkdir -m 0770 ${collect_tmp_dir}

    if [ -e /dev/block/by-name/oplusreserve3 ]; then
        LOG_DEV="/dev/block/by-name/oplusreserve3"
    #liuchanghong@BSP.Kernel.Driver, 2021/10/18 add for op8 reserve
    elif [ -e /dev/block/by-name/reserve3 ]; then
        LOG_DEV="/dev/block/by-name/reserve3"
    else
        LOG_DEV="/dev/block/by-name/opporeserve3"
    fi

    dd if=${LOG_DEV} of=${collect_tmp_dir}/opporeserve3

}

function shd_log_native_helper_main()
{
    argv=$1
    echo "argument $argv"
    for i in $(seq 1 ${#ERROR_FUNC_MAP_KEY[@]})
    do
        if [ ${argv} == ${ERROR_FUNC_MAP_KEY[(($i-1))]} ] ;
        then
            echo "matched will run ${ERROR_FUNC_MAP_VAL[(($i-1))]}"
            ${ERROR_FUNC_MAP_VAL[(($i-1))]}
        fi
    done
}

shd_log_native_helper_main $1
