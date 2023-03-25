#! /system/bin/sh

CURTIME=`date +%F_%H-%M-%S`
CURTIME_FORMAT=`date "+%Y-%m-%d %H:%M:%S"`

BASE_PATH=/sdcard/Android/data/com.oplus.olc
SDCARD_LOG_BASE_PATH=${BASE_PATH}/files/Log
SDCARD_LOG_TRIGGER_PATH=${BASE_PATH}/trigger

DATA_DEBUGGING_PATH=/data/debugging
DATA_OPLUS_LOG_PATH=/data/persist_log
ANR_BINDER_PATH=${DATA_DEBUGGING_PATH}/anr_binder_info
CACHE_PATH=${DATA_DEBUGGING_PATH}/cache

MTK_DEBUG_PATH=/data/debuglogger

config="$1"

# change defalut permissions of folder created by current user
umask 007

#Linjie.Xu@PSW.AD.Power.PowerMonitor.1104067, 2018/01/17, Add for OplusPowerMonitor get dmesg at O
function kernelcacheforopm(){
  opmlogpath=`getprop sys.opm.logpath`
  dmesg > ${opmlogpath}dmesg.txt
  chown system:system ${opmlogpath}dmesg.txt
}

#Jianfa.Chen@PSW.AD.PowerMonitor,add for powermonitor getting Xlog
function catchWXlogForOpm() {
  currentDateWXlog=$(date "+%Y%m%d")
  newpath=`getprop sys.opm.logpath`

  XLOG_DIR="/sdcard/Android/data/com.tencent.mm/MicroMsg/xlog"
  CRASH_DIR="/sdcard/Android/data/com.tencent.mm/MicroMsg/crash"

  mkdir -p ${newpath}/wxlog
  chmod 777 -R ${newpath}/wxlog
  #wxlog/xlog
  if [ -d "${XLOG_DIR}" ]; then
    mkdir -p ${newpath}/wxlog/xlog
    ALL_FILE=$(find ${XLOG_DIR} | grep -E ${currentDateWXlog} | xargs ls -t)
    for file in $ALL_FILE; do
      cp $file ${newpath}/wxlog/xlog/
    done
  fi

  if [ -d "${CRASH_DIR}" ];then
    mkdir -p ${newpath}/wxlog/crash
    ALL_FILE = $(find ${XLOG_DIR} | grep -E ${currentDateWXlog} | xargs ls -t)
    for file in $ALL_FILE;do
      cp $file ${newpath}/wxlog/crash
    done
  fi
}

# Qiurun.Zhou@ANDROID.DEBUG, 2022/6/17, copy wxlog for EAP
function eapCopyWXlog() {
  currentDateWXlog=$(date "+%Y%m%d")
  newpath=`getprop sys.opm.logpath`

  XLOG_DIR="/sdcard/Android/data/com.tencent.mm/MicroMsg/xlog"
  CRASH_DIR="/sdcard/Android/data/com.tencent.mm/MicroMsg/crash"

  mkdir -p ${newpath}/wxlog
  chmod 777 -R ${newpath}/wxlog
  #wxlog/xlog
  if [ -d "${XLOG_DIR}" ]; then
    mkdir -p ${newpath}/wxlog/xlog
    ALL_FILE=$(find ${XLOG_DIR} | grep -E ${currentDateWXlog} | xargs ls -t)
    for file in $ALL_FILE; do
      cp $file ${newpath}/wxlog/xlog/
    done
  fi

  if [ -d "${CRASH_DIR}" ]; then
    mkdir -p ${newpath}/wxlog/crash
    ALL_FILE=$(find ${CRASH_DIR} | grep -E ${currentDateWXlog} | xargs ls -t)
    for file in $ALL_FILE; do
      cp $file ${newpath}/wxlog/crash/
    done
  fi
  chown -R system:system ${newpath}
}

function catchQQlogForOpm() {
  currentDateQlog=$(date "+%y.%m.%d")
  newpath=`getprop sys.opm.logpath`
  QLOG_DIR="/sdcard/Android/data/com.tencent.mobileqq/files/tencent/msflogs/com/tencent/mobileqq"
  #qlog
  mkdir -p ${newpath}/qlog
  chmod 777 -R ${newpath}/qlog
  if [ -d "${QLOG_DIR}" ]; then
    mkdir -p ${newpath}/qlog/log
    ALL_FILE=$(find ${QLOG_DIR} | grep -E ${currentDateQlog} | xargs ls -t)
    for file in $ALL_FILE; do
      cp $file ${newpath}/qlog
    done
  fi
}


function startSsLogPower() {
    traceTransferState "startSsLogPower"
    powermonitorCustomLogDir=${DATA_DEBUGGING_PATH}/powermonitor_custom_log
    
    if [ ! -d "${powermonitorCustomLogDir}" ];then
        mkdir -p ${powermonitorCustomLogDir}
    fi
    ssLogOutputPath=${powermonitorCustomLogDir}/sslog.txt

    while [ -d "$powermonitorCustomLogDir" ]
    do
       ss -ntp -o state established >> ${ssLogOutputPath}
       sleep 15s #Sleep 15 seconds
    done
    traceTransferState "startSsLogPower_End"
}

function tranferPowerRelated() {
  traceTransferState "tranferPowerRelated"
  powerExtraLogDir="/data/oplus/psw/powermonitor_backup/extra_log";
  powermonitorCustomLogDir=${DATA_DEBUGGING_PATH}/powermonitor_custom_log
  if [ ! -d "${powerExtraLogDir}" ];then
    mkdir -p ${powerExtraLogDir}
  fi
  
  chown system:system ${powerExtraLogDir}
  chmod 777 -R ${powerExtraLogDir}/

  #collect bluetooth log
  buletoothLogSaveDir="${powerExtraLogDir}/buletooth_log";
  if [ ! -d "${buletoothLogSaveDir}" ];then
    mkdir -p ${buletoothLogSaveDir}
  fi

  tar cvzf ${buletoothLogSaveDir}/buletooth_log.tar.gz /data/misc/bluetooth/
  traceTransferState "get bluetooth log"

  #collect sslog
  sslogSourcPath=${powermonitorCustomLogDir}/sslog.txt
  if [ -f "${sslogSourcPath}" ];then
    cp ${sslogSourcPath} ${powerExtraLogDir}/sslog.txt
    traceTransferState "get sslog"
  fi

  chown system:system ${powerExtraLogDir}
  chmod 777 -R ${powerExtraLogDir}/
  
  #clear file
  rm ${sslogSourcPath}
  traceTransferState "tranferPowerRelated_end"
}

#Linjie.Xu@PSW.AD.Power.PowerMonitor.1104067, 2018/01/17, Add for OplusPowerMonitor get Sysinfo at O
function psforopm(){
  opmlogpath=`getprop sys.opm.logpath`
  ps -A -T > ${opmlogpath}psO.txt
  chown system:system ${opmlogpath}psO.txt
}
function cpufreqforopm(){
  opmlogpath=`getprop sys.opm.logpath`
  cat /sys/devices/system/cpu/*/cpufreq/scaling_cur_freq > ${opmlogpath}cpufreq.txt
  chown system:system ${opmlogpath}cpufreq.txt
}


function logcatMainCacheForOpm(){
  opmlogpath=`getprop sys.opm.logpath`
  logcat -v threadtime -d > ${opmlogpath}logcat.txt
  chown system:system ${opmlogpath}logcat.txt
}

function logcatEventCacheForOpm(){
  opmlogpath=`getprop sys.opm.logpath`
  logcat -b events -d > ${opmlogpath}events.txt
  chown system:system ${opmlogpath}events.txt
}

function logcatRadioCacheForOpm(){
  opmlogpath=`getprop sys.opm.logpath`
  logcat -b radio -d > ${opmlogpath}radio.txt
  chown system:system ${opmlogpath}radio.txt
}

function catchBinderInfoForOpm(){
  opmlogpath=`getprop sys.opm.logpath`
  cat /sys/kernel/debug/binder/state > ${opmlogpath}binderinfo.txt
  chown system:system ${opmlogpath}binderinfo.txt
}

function catchBattertFccForOpm(){
  opmlogpath=`getprop sys.opm.logpath`
  cat /sys/class/power_supply/battery/batt_fcc > ${opmlogpath}fcc.txt
  chown system:system ${opmlogpath}fcc.txt
}

function catchTopInfoForOpm(){
  opmlogpath=`getprop sys.opm.logpath`
  opmfilename=`getprop sys.opm.logpath.filename`
  top -H -n 3 > ${opmlogpath}${opmfilename}top.txt
  chown system:system ${opmlogpath}${opmfilename}top.txt
}

function dumpsysHansHistoryForOpm(){
  opmlogpath=`getprop sys.opm.logpath`
  dumpsys activity hans history > ${opmlogpath}hans.txt
  chown system:system ${opmlogpath}hans.txt
  dumpsys activity service com.oplus.battery deepsleepRcd > ${opmlogpath}deepsleepRcd.txt
  chown system:system ${opmlogpath}deepsleepRcd.txt
}

function dumpsysSurfaceFlingerForOpm(){
  opmlogpath=`getprop sys.opm.logpath`
  dumpsys sensorservice > ${opmlogpath}sensorservice.txt
  chown system:system ${opmlogpath}sensorservice.txt
}

function dumpsysSensorserviceForOpm(){
  opmlogpath=`getprop sys.opm.logpath`
  dumpsys sensorservice > ${opmlogpath}sensorservice.txt
  chown system:system ${opmlogpath}sensorservice.txt
}

function dumpsysBatterystatsForOpm(){
  opmlogpath=`getprop sys.opm.logpath`
  dumpsys batterystats > ${opmlogpath}batterystats.txt
  chown system:system ${opmlogpath}batterystats.txt
}

function dumpsysBatterystatsOplusCheckinForOpm(){
  opmlogpath=`getprop sys.opm.logpath`
  dumpsys batterystats --oplusCheckin > ${opmlogpath}batterystats_oplusCheckin.txt
  chown system:system ${opmlogpath}batterystats_oplusCheckin.txt
}

function dumpsysBatterystatsCheckinForOpm(){
  opmlogpath=`getprop sys.opm.logpath`
  dumpsys batterystats -c > ${opmlogpath}batterystats_checkin.txt
  chown system:system ${opmlogpath}batterystats_checkin.txt
}

function dumpsysMediaForOpm(){
  opmlogpath=`getprop sys.opm.logpath`
  dumpsys media.audio_flinger > ${opmlogpath}audio_flinger.txt
  dumpsys media.audio_policy > ${opmlogpath}audio_policy.txt
  dumpsys audio > ${opmlogpath}audio.txt

  chown system:system ${opmlogpath}audio_flinger.txt
  chown system:system ${opmlogpath}audio_policy.txt
  chown system:system ${opmlogpath}audio.txt
}

function getPropForOpm(){
  opmlogpath=`getprop sys.opm.logpath`
  getprop > ${opmlogpath}prop.txt
  chown system:system ${opmlogpath}prop.txt
}

function logcusMainForOpm() {
    opmlogpath=`getprop sys.opm.logpath`
    /system/bin/logcat -f ${opmlogpath}/android.txt -r 10240 -n 5 -v threadtime *:V
}

function logcusEventForOpm() {
    opmlogpath=`getprop sys.opm.logpath`
    /system/bin/logcat -b events -f ${opmlogpath}/event.txt -r 10240 -n 5 -v threadtime *:V
}

function logcusRadioForOpm() {
    opmlogpath=`getprop sys.opm.logpath`
    /system/bin/logcat -b radio -f ${opmlogpath}/radio.txt -r 10240 -n 5 -v threadtime *:V
}

function logcusKernelForOpm() {
    opmlogpath=`getprop sys.opm.logpath`
    /system/system_ext/xbin/klogd -f - -n -x -l 7 | tee - ${opmlogpath}/kernel.txt | awk 'NR%400==0'
}

function logcusTCPForOpm() {
    opmlogpath=`getprop sys.opm.logpath`
    tcpdump -i any -p -s 0 -W 1 -C 50 -w ${opmlogpath}/tcpdump.pcap
}

function customDiaglogForOpm() {
    echo "customdiaglog opm begin"
    opmlogpath=`getprop sys.opm.logpath`
    mv ${DATA_DEBUGGING_PATH}/diag_logs ${opmlogpath}
    chmod 777 -R ${opmlogpath}
    restorecon -RF ${opmlogpath}
    echo "customdiaglog opm end"
}

function clearMtkDebuglogger() {
     rm -rf /data/debuglogger/*
}

function dmaprocsforhealth(){
  opmlogpath=`getprop sys.opm.logpath`
  cat /proc/ion/ion_mm_heap > ${opmlogpath}dmaprocs.txt
  cat /proc/osvelte/dma_buf/bufinfo >> ${opmlogpath}dmaprocs.txt
  cat /proc/osvelte/dma_buf/procinfo >> ${opmlogpath}dmaprocs.txt
  dumpsys meminfo `ps -A | grep graphics.composer | tr -s ' ' | cut -d ' ' -f 2` >> ${opmlogpath}dmaprocs.txt
  chown system:system ${opmlogpath}dmaprocs.txt
}
function slabinfoforhealth(){
  opmlogpath=`getprop sys.opm.logpath`
  cat /proc/slabinfo > ${opmlogpath}slabinfo.txt
  chown system:system ${opmlogpath}slabinfo.txt
}
function svelteforhealth(){
    sveltetracer=`getprop sys.opm.svelte_tracer`
    svelteops=`getprop sys.opm.svelte_ops`
    svelteargs=`getprop sys.opm.svelte_args`
    opmlogpath=`getprop sys.opm.logpath`

    if [ "${sveltetracer}" == "malloc" ]; then
        if [ "${svelteops}" == "enable" ]; then
            osvelte malloc-debug -e ${svelteargs}
        elif [ "${svelteops}" == "disable" ]; then
            osvelte malloc-debug -D ${svelteargs}
        elif [ "${svelteops}" == "dump" ]; then
            osvelte malloc-debug -d ${svelteargs} > ${opmlogpath}malloc_${svelteargs}_svelte.txt
            sleep 12
            chown system:system ${opmlogpath}*svelte.txt
        fi
    elif [ "${sveltetracer}" == "vmalloc" ]; then
        if [ "${svelteops}" == "dump" ]; then
            cat /proc/vmallocinfo > ${svelteargs}
            sleep 12
            chown system:system ${opmlogpath}*svelte.txt
        fi
    elif [ "${sveltetracer}" == "slab" ]; then
        if [ "${svelteops}" == "dump" ]; then
            cat /proc/slabinfo > ${svelteargs}
            sleep 5
            chown system:system ${opmlogpath}*svelte.txt
        fi
    elif [ "${sveltetracer}" == "kernelstack" ]; then
        if [ "${svelteops}" == "dump" ]; then
            ps -A -T > ${svelteargs}
            sleep 5
            chown system:system ${opmlogpath}*svelte.txt
        fi
    elif [ "${sveltetracer}" == "ion" ]; then
        if [ "${svelteops}" == "dump" ]; then
            cat /proc/osvelte/dma_buf/bufinfo > ${svelteargs}
            cat /proc/osvelte/dma_buf/procinfo >> ${svelteargs}
            sleep 5
            chown system:system ${opmlogpath}*svelte.txt
        fi
    fi
}
function meminfoforhealth(){
  opmlogpath=`getprop sys.opm.logpath`
  cat /proc/meminfo > ${opmlogpath}meminfo.txt
  chown system:system ${opmlogpath}meminfo.txt
}

# Add for SurfaceFlinger Layer dump
function layerdump(){
    dumpsys window > /data/log/dumpsys_window.txt
    mkdir -p ${SDCARD_LOG_BASE_PATH}
    LOGTIME=`date +%F-%H-%M-%S`
    ROOT_SDCARD_LAYERDUMP_PATH=${SDCARD_LOG_BASE_PATH}/LayerDump_${LOGTIME}
    cp -R /data/log ${ROOT_SDCARD_LAYERDUMP_PATH}
    rm -rf /data/log
}

#Fei.Mo2017/09/01 ,Add for power monitor top info
function thermalTop(){
   top -m 3 -n 1 > /data/system/dropbox/thermalmonitor/top
   chown system:system /data/system/dropbox/thermalmonitor/top
}

#Deliang.Peng 2017/7/7,add for native watchdog
function nativedump() {
    LOGTIME=`date +%F-%H-%M-%S`
    SWTPID=`getprop debug.swt.pid`
    JUNKLOGSFBACKPATH=/sdcard/persist_log/native/${LOGTIME}
    NATIVEBACKTRACEPATH=${JUNKLOGSFBACKPATH}/user_backtrace
    mkdir -p ${NATIVEBACKTRACEPATH}
    cat proc/stat > ${JUNKLOGSFBACKPATH}/proc_stat.txt &
    cat /sys/devices/system/cpu/cpu0/cpufreq/cpuinfo_cur_freq > ${JUNKLOGSFBACKPATH}/cpu_freq_0_.txt &
    cat /sys/devices/system/cpu/cpu1/cpufreq/cpuinfo_cur_freq > ${JUNKLOGSFBACKPATH}/cpu_freq_1.txt &
    cat /sys/devices/system/cpu/cpu2/cpufreq/cpuinfo_cur_freq > ${JUNKLOGSFBACKPATH}/cpu_freq_2.txt &
    cat /sys/devices/system/cpu/cpu3/cpufreq/cpuinfo_cur_freq > ${JUNKLOGSFBACKPATH}/cpu_freq_3.txt &
    cat /sys/devices/system/cpu/cpu4/cpufreq/cpuinfo_cur_freq > ${JUNKLOGSFBACKPATH}/cpu_freq_4.txt &
    cat /sys/devices/system/cpu/cpu5/cpufreq/cpuinfo_cur_freq > ${JUNKLOGSFBACKPATH}/cpu_freq_5.txt &
    cat /sys/devices/system/cpu/cpu6/cpufreq/cpuinfo_cur_freq > ${JUNKLOGSFBACKPATH}/cpu_freq_6.txt &
    cat /sys/devices/system/cpu/cpu7/cpufreq/cpuinfo_cur_freq > ${JUNKLOGSFBACKPATH}/cpu_freq_7.txt &
    cat /sys/devices/system/cpu/cpu0/online > ${JUNKLOGSFBACKPATH}/cpu_online_0_.txt &
    cat /sys/devices/system/cpu/cpu1/online > ${JUNKLOGSFBACKPATH}/cpu_online_1_.txt &
    cat /sys/devices/system/cpu/cpu2/online > ${JUNKLOGSFBACKPATH}/cpu_online_2_.txt &
    cat /sys/devices/system/cpu/cpu3/online > ${JUNKLOGSFBACKPATH}/cpu_online_3_.txt &
    cat /sys/devices/system/cpu/cpu4/online > ${JUNKLOGSFBACKPATH}/cpu_online_4_.txt &
    cat /sys/devices/system/cpu/cpu5/online > ${JUNKLOGSFBACKPATH}/cpu_online_5_.txt &
    cat /sys/devices/system/cpu/cpu6/online > ${JUNKLOGSFBACKPATH}/cpu_online_6_.txt &
    cat /sys/devices/system/cpu/cpu7/online > ${JUNKLOGSFBACKPATH}/cpu_online_7_.txt &
    cat /proc/gpufreq/gpufreq_var_dump > ${JUNKLOGSFBACKPATH}/gpuclk.txt &
    top -n 1 -m 5 > ${JUNKLOGSFBACKPATH}/top.txt  &
    cp -R /data/native/* ${NATIVEBACKTRACEPATH}
    rm -rf /data/native
    ps -t > ${JUNKLOGSFBACKPATH}/pst.txt
}

function gettpinfo() {
    tplogflag=`getprop persist.sys.oplusdebug.tpcatcher`
    # tplogflag=511
    # echo "$tplogflag"
    if [ "$tplogflag" == "" ]
    then
        echo "tplogflag == error"
    else
        subtime=`date +%F-%H-%M-%S`
        subpath=/sdcard/tp_debug_info.txt
        echo "tplogflag = $tplogflag"
        # tplogflag=`echo $tplogflag | $XKIT awk '{print lshift($0, 1)}'`
        tpstate=0
        # tpstate=`echo $tplogflag | $XKIT awk '{print and($1, 1)}'`
        tpstate=$(($tplogflag & 1))
        echo "switch tpstate = $tpstate"
        if [ $tpstate == "0" ]
        then
            echo "switch tpstate off"
        else
            echo "switch tpstate on"
        # mFlagMainRegister = 1 << 1
        # subflag=`echo | $XKIT awk '{print lshift(1, 1)}'`
        subflag=$((1 << 1))
        echo "1 << 1 subflag = $subflag"
        # tpstate=`echo $tplogflag $subflag, | $XKIT awk '{print and($1, $2)}'`
        tpstate=$(($tplogflag & subflag))
        if [ $tpstate == "0" ]
        then
            echo "switch tpstate off mFlagMainRegister = 1 << 1 $tpstate"
        else
            echo "switch tpstate on mFlagMainRegister = 1 << 1 $tpstate"
            echo "Time : ${subtime}" >> $subpath
            echo /proc/touchpanel/debug_info/main_register  >> $subpath
            cat /proc/touchpanel/debug_info/main_register  >> $subpath
        fi
        # mFlagSelfDelta = 1 << 2;
        # subflag=`echo | $XKIT awk '{print lshift(1, 2)}'`
        subflag=$((1 << 2))
        echo " 1<<2 subflag = $subflag"
        # tpstate=`echo $tplogflag $subflag, | $XKIT awk '{print and($1, $2)}'`
        tpstate=$(($tplogflag & subflag))
        if [ $tpstate == "0" ]
        then
            echo "switch tpstate off mFlagSelfDelta = 1 << 2 $tpstate"
        else
            echo "switch tpstate on mFlagSelfDelta = 1 << 2 $tpstate"
            echo /proc/touchpanel/debug_info/self_delta  >> $subpath
            cat /proc/touchpanel/debug_info/self_delta  >> $subpath
        fi
        # mFlagDetal = 1 << 3;
        # subflag=`echo | $XKIT awk '{print lshift(1, 3)}'`
        subflag=$((1 << 3))
        echo "1 << 3 subflag = $subflag"
        # tpstate=`echo $tplogflag $subflag, | $XKIT awk '{print and($1, $2)}'`
        tpstate=$(($tplogflag & subflag))
        if [ $tpstate == "0" ]
        then
            echo "switch tpstate off mFlagDelta = 1 << 3 $tpstate"
        else
            echo "switch tpstate on mFlagDelta = 1 << 3 $tpstate"
            echo /proc/touchpanel/debug_info/delta  >> $subpath
            cat /proc/touchpanel/debug_info/delta  >> $subpath
        fi
        # mFlatSelfRaw = 1 << 4;
        # subflag=`echo | $XKIT awk '{print lshift(1, 4)}'`
        subflag=$((1 << 4))
        echo "1 << 4 subflag = $subflag"
        # tpstate=`echo $tplogflag $subflag, | $XKIT awk '{print and($1, $2)}'`
        tpstate=$(($tplogflag & subflag))
        if [ $tpstate == "0" ]
        then
            echo "switch tpstate off mFlagSelfRaw = 1 << 4 $tpstate"
        else
            echo "switch tpstate on mFlagSelfRaw = 1 << 4 $tpstate"
            echo /proc/touchpanel/debug_info/self_raw  >> $subpath
            cat /proc/touchpanel/debug_info/self_raw  >> $subpath
        fi
        # mFlagBaseLine = 1 << 5;
        # subflag=`echo | $XKIT awk '{print lshift(1, 5)}'`
        subflag=$((1 << 5))
        echo "1 << 5 subflag = $subflag"
        # tpstate=`echo $tplogflag $subflag, | $XKIT awk '{print and($1, $2)}'`
        tpstate=$(($tplogflag & subflag))
        if [ $tpstate == "0" ]
        then
            echo "switch tpstate off mFlagBaseline = 1 << 5 $tpstate"
        else
            echo "switch tpstate on mFlagBaseline = 1 << 5 $tpstate"
            echo /proc/touchpanel/debug_info/baseline  >> $subpath
            cat /proc/touchpanel/debug_info/baseline  >> $subpath
        fi
        # mFlagDataLimit = 1 << 6;
        # subflag=`echo | $XKIT awk '{print lshift(1, 6)}'`
        subflag=$((1 << 6))
        echo "1 << 6 subflag = $subflag"
        # tpstate=`echo $tplogflag $subflag, | $XKIT awk '{print and($1, $2)}'`
        tpstate=$(($tplogflag & subflag))
        if [ $tpstate == "0" ]
        then
            echo "switch tpstate off mFlagDataLimit = 1 << 6 $tpstate"
        else
            echo "switch tpstate on mFlagDataLimit = 1 << 6 $tpstate"
            echo /proc/touchpanel/debug_info/data_limit  >> $subpath
            cat /proc/touchpanel/debug_info/data_limit  >> $subpath
        fi
        # mFlagReserve = 1 << 7;
        # subflag=`echo | $XKIT awk '{print lshift(1, 7)}'`
        subflag=$((1 << 7))
        echo "1 << 7 subflag = $subflag"
        # tpstate=`echo $tplogflag $subflag, | $XKIT awk '{print and($1, $2)}'`
        tpstate=$(($tplogflag & subflag))
        if [ $tpstate == "0" ]
        then
            echo "switch tpstate off mFlagReserve = 1 << 7 $tpstate"
        else
            echo "switch tpstate on mFlagReserve = 1 << 7 $tpstate"
            echo /proc/touchpanel/debug_info/reserve  >> $subpath
            cat /proc/touchpanel/debug_info/reserve  >> $subpath
        fi
        # mFlagTpinfo = 1 << 8;
        # subflag=`echo | $XKIT awk '{print lshift(1, 8)}'`
        subflag=$((1 << 8))
        echo "1 << 8 subflag = $subflag"
        # tpstate=`echo $tplogflag $subflag, | $XKIT awk '{print and($1, $2)}'`
        tpstate=$(($tplogflag & subflag))
        if [ $tpstate == "0" ]
        then
            echo "switch tpstate off mFlagMainRegister = 1 << 8 $tpstate"
        else
            echo "switch tpstate on mFlagMainRegister = 1 << 8 $tpstate"
        fi

        echo $tplogflag " end else"
	fi
    fi
}

function inittpdebug(){
    panicstate=`getprop persist.sys.assert.panic`
    tplogflag=`getprop persist.sys.oplusdebug.tpcatcher`
    if [ "$panicstate" == "true" ]
    then
        # tplogflag=`echo $tplogflag , | $XKIT awk '{print or($1, 1)}'`
        tplogflag=$(($tplogflag | 1))
    else
        # tplogflag=`echo $tplogflag , | $XKIT awk '{print and($1, 510)}'`
        tplogflag=$(($tplogflag & 1))
    fi
    setprop persist.sys.oplusdebug.tpcatcher $tplogflag
}
function settplevel(){
    tplevel=`getprop persist.sys.oplusdebug.tplevel`
    if [ "$tplevel" == "0" ]
    then
        echo 0 > /proc/touchpanel/debug_level
    elif [ "$tplevel" == "1" ]
    then
        echo 1 > /proc/touchpanel/debug_level
    elif [ "$tplevel" == "2" ]
    then
        echo 2 > /proc/touchpanel/debug_level
    fi
}

#Fangfang.Hui@TECH.AD.Stability, 2019/08/13, Add for the quality feedback dcs config
function backupMinidump() {
    tag=`getprop sys.backup.minidump.tag`
    if [ x"$tag" = x"" ]; then
        echo "backup.minidump.tag is null, do nothing"
        return
    fi
    minidumppath="${DATA_OPLUS_LOG_PATH}/DCS/de/AEE_DB"
    miniDumpFile=$minidumppath/$(ls -t ${minidumppath} | head -1)
    if [ x"$miniDumpFile" = x"" ]; then
        echo "minidump.file is null, do nothing"
        return
    fi
    result=$(echo $miniDumpFile | grep "${tag}")
    if [ x"$result" = x"" ]; then
        echo "tag mismatch, do not backup"
        return
    else
        try_copy_minidump_to_oplusreserve $miniDumpFile
        setprop sys.backup.minidump.tag ""
    fi
}

function try_copy_minidump_to_oplusreserve() {
    OPLUSRESERVE_MINIDUMP_BACKUP_PATH="${DATA_OPLUS_LOG_PATH}/oplusreserve/media/log/minidumpbackup"
    OPLUSRESERVE2_MOUNT_POINT="/mnt/vendor/oplusreserve"

    if [ ! -d ${OPLUSRESERVE_MINIDUMP_BACKUP_PATH} ]; then
        mkdir ${OPLUSRESERVE_MINIDUMP_BACKUP_PATH}
    fi

    NewLogPath=$1
    if [ ! -f $NewLogPath ] ;then
        echo "Can not access ${NewLogPath}, the file may not exists "
        return
    fi
    TmpLogSize=$(du -sk ${NewLogPath} | sed 's/[[:space:]]/,/g' | cut -d "," -f1) #`du -s -k ${NewLogPath} | $XKIT awk '{print $1}'`
    curBakCount=`ls ${OPLUSRESERVE_MINIDUMP_BACKUP_PATH} | wc -l`
    echo "curBakCount = ${curBakCount}, TmpLogSize = ${TmpLogSize}, NewLogPath = ${NewLogPath}"
    while [ ${curBakCount} -gt 5 ]   #can only save 5 backup minidump logs at most
    do
        rm -rf ${OPLUSRESERVE_MINIDUMP_BACKUP_PATH}/$(ls -t ${OPLUSRESERVE_MINIDUMP_BACKUP_PATH} | tail -1)
        curBakCount=`ls ${OPLUSRESERVE_MINIDUMP_BACKUP_PATH} | wc -l`
        echo "delete one file curBakCount = $curBakCount"
    done
    FreeSize=$(df -ak | grep "${OPLUSRESERVE_MINIDUMP_BACKUP_PATH}" | sed 's/[ ][ ]*/,/g' | cut -d "," -f4)
    TotalSize=$(df -ak | grep "${OPLUSRESERVE_MINIDUMP_BACKUP_PATH}" | sed 's/[ ][ ]*/,/g' | cut -d "," -f2)
    ReserveSize=`expr $TotalSize / 5`
    NeedSize=`expr $TmpLogSize + $ReserveSize`
    echo "NeedSize = ${NeedSize}, ReserveSize = ${ReserveSize}, FreeSize = ${FreeSize}"
    while [ ${FreeSize} -le ${NeedSize} ]
    do
        curBakCount=`ls ${OPLUSRESERVE_MINIDUMP_BACKUP_PATH} | wc -l`
        if [ $curBakCount -gt 1 ]; then #leave at most on log file
            rm -rf ${OPLUSRESERVE_MINIDUMP_BACKUP_PATH}/$(ls -t ${OPLUSRESERVE_MINIDUMP_BACKUP_PATH} | tail -1)
            echo "${OPLUSRESERVE2_MOUNT_POINT} left space ${FreeSize} not enough for minidump, delete one de minidump"
            FreeSize=$(df -k | grep "${OPLUSRESERVE2_MOUNT_POINT}" | sed 's/[ ][ ]*/,/g' | cut -d "," -f4)
            continue
        fi
        echo "${OPLUSRESERVE2_MOUNT_POINT} left space ${FreeSize} not enough for minidump, nothing to delete"
        return 0
    done
    #space is enough, now copy
    cp $NewLogPath $OPLUSRESERVE_MINIDUMP_BACKUP_PATH
    chmod -R 0771 ${OPLUSRESERVE_MINIDUMP_BACKUP_PATH}
    chown -R system ${OPLUSRESERVE_MINIDUMP_BACKUP_PATH}
    chgrp -R system ${OPLUSRESERVE_MINIDUMP_BACKUP_PATH}
}

#Jianping.Zheng 2017/06/20, Add for collect futexwait block log
function collect_futexwait_log() {
    collect_path=/data/system/dropbox/extra_log
    if [ ! -d ${collect_path} ]
    then
        mkdir -p ${collect_path}
        chmod 700 ${collect_path}
        chown system:system ${collect_path}
    fi

    #time
    echo `date` > ${collect_path}/futexwait.time.txt

    #ps -t info
    ps -A -T > $collect_path/ps.txt

    #D status to dmesg
    echo w > /proc/sysrq-trigger

    #systemserver trace
    system_server_pid=`pidof system_server`
    kill -3 ${system_server_pid}
    sleep 10
    cp /data/anr/traces.txt $collect_path/

    #systemserver native backtrace
    debuggerd -b ${system_server_pid} > $collect_path/systemserver.backtrace.txt
}

# Add for clean pcm dump file.
function cleanpcmdump() {
    rm -rf /data/vendor/audiohal/audio_dump/*
    rm -rf /data/vendor/audiohal/aurisys_dump/*
    rm -rf /data/debuglogger/audio_dump/*
    rm -rf /sdcard/mtklog/audio_dump/*
}

#Jianping.Zheng, 2017/04/04, Add for record performance
function perf_record() {
    check_interval=`getprop persist.sys.oplus.perfinteval`
    if [ x"${check_interval}" = x"" ]; then
        check_interval=60
    fi
    perf_record_path=${DATA_DEBUGGING_PATH}/perf_record_logs
    while [ true ];do
        if [ ! -d ${perf_record_path} ];then
            mkdir -p ${perf_record_path}
        fi

        echo "\ndate->" `date` >> ${perf_record_path}/cpu.txt
        cat /sys/devices/system/cpu/cpu*/cpufreq/scaling_cur_freq >> ${perf_record_path}/cpu.txt

        echo "\ndate->" `date` >> ${perf_record_path}/mem.txt
        cat /proc/meminfo >> ${perf_record_path}/mem.txt

        echo "\ndate->" `date` >> ${perf_record_path}/buddyinfo.txt
        cat /proc/buddyinfo >> ${perf_record_path}/buddyinfo.txt

        echo "\ndate->" `date` >> ${perf_record_path}/top.txt
        top -n 1 -H >> ${perf_record_path}/top.txt

        sleep "$check_interval"
    done
}

function clearDataDebugLog(){
    if [ -d ${DATA_DEBUGGING_PATH} ]; then
        chmod 777 -R ${DATA_DEBUGGING_PATH}
        rm -rf ${DATA_DEBUGGING_PATH}/*
    fi
    if [ -d ${MTK_DEBUG_PATH} ]; then
        rm -rf ${MTK_DEBUG_PATH}/*
    fi
    setprop sys.clear.finished 1
}

function screen_record_backup(){
    backupFile="${SDCARD_LOG_BASE_PATH}/screen_record/screen_record_old.mp4"
    if [ -f "$backupFile" ]; then
         rm $backupFile
    fi

    curFile="${SDCARD_LOG_BASE_PATH}/screen_record/screen_record.mp4"
    if [ -f "$curFile" ]; then
         mv $curFile $backupFile
    fi
}

function pwkdumpon(){
    echo 1 >  /proc/aee_kpd_enable
}

function pwkdumpoff(){
    echo 0 >  /proc/aee_kpd_enable
}

# Add for full dump & mini dump
function mrdumpon(){
	/system/system_ext/bin/oplus_fulldump on
}

function mrdumpoff(){
	/system/system_ext/bin/oplus_fulldump off
}

function testTransferSystem(){
    TMPTIME=`date +%F-%H-%M-%S`
    setprop sys.oplus.log.stoptime ${TMPTIME}
    stoptime=`getprop sys.oplus.log.stoptime`;
    newpath="${SDCARD_LOG_BASE_PATH}/log@stop@${stoptime}"
    echo "${newpath}"

    mkdir -p ${newpath}/system
    #tar -cvf ${newpath}/log.tar ${DATA_OPLUS_LOG_PATH}/*
    cp -rf ${DATA_OPLUS_LOG_PATH}/ ${newpath}/system
}

function testTransferRoot(){
    TMPTIME=`date +%F-%H-%M-%S`
    setprop sys.oplus.log.stoptime ${TMPTIME}
    stoptime=`getprop sys.oplus.log.stoptime`;
    newpath="${SDCARD_LOG_BASE_PATH}/log@stop@${stoptime}"
    echo "${newpath}"

    mkdir -p ${newpath}
    mv ${MTK_DEBUG_PATH} ${newpath}
}

function checkSmallSizeAndCopy(){
    LOG_SOURCE_PATH="$1"
    LOG_TARGET_PATH="$2"
    echo "${CURTIME_FORMAT} CHECKSIZEANDCOPY:from ${LOG_SOURCE_PATH} to ${LOG_TARGET_PATH}" >> ${SDCARD_LOG_BASE_PATH}/logkit_transfer.log
    # 10M
    LIMIT_SIZE="10240"

    if [ -d "${LOG_SOURCE_PATH}" ]; then
        TMP_LOG_SIZE=`du -s -k ${LOG_SOURCE_PATH} | awk '{print $1}'`
        if [ ${TMP_LOG_SIZE} -le ${LIMIT_SIZE} ]; then  #log size less then 10M
            mkdir -p ${newpath}/${LOG_TARGET_PATH}
            cp -rf ${LOG_SOURCE_PATH}/* ${newpath}/${LOG_TARGET_PATH}
            echo "${CURTIME_FORMAT} CHECKSIZEANDCOPY:${LOG_SOURCE_PATH} done" >> ${SDCARD_LOG_BASE_PATH}/logkit_transfer.log
        else
            echo "${CURTIME_FORMAT} CHECKSIZEANDCOPY:${LOG_SOURCE_PATH} SIZE:${TMP_LOG_SIZE}/${LIMIT_SIZE}" >> ${SDCARD_LOG_BASE_PATH}/logkit_transfer.log
        fi
    fi
}

function checkFileAndMove(){
    LOG_SOURCE_PATH="$1"
    LOG_TARGET_PATH="$2"
    echo "${CURTIME_FORMAT} checkFileAndMove:from ${LOG_SOURCE_PATH} to ${LOG_TARGET_PATH}" >> ${SDCARD_LOG_BASE_PATH}/logkit_transfer.log

    if [ -f "${LOG_SOURCE_PATH}" ]; then
        mv ${LOG_SOURCE_PATH} ${LOG_TARGET_PATH}
        rm ${LOG_SOURCE_PATH}
        echo "${CURTIME_FORMAT} checkFileAndMove:mv ${LOG_SOURCE_PATH} to ${LOG_TARGET_PATH} done" >> ${SDCARD_LOG_BASE_PATH}/logkit_transfer.log
    else
        echo "checkFileAndMove: ${LOG_SOURCE_PATH} is not a original File"
    fi
}

function checkNumberSizeAndCopy(){
    LOG_SOURCE_PATH="$1"
    LOG_TARGET_PATH="$2"
    LOG_LIMIT_NUM="$3"
    LOG_LIMIT_SIZE="$4"
    echo "${CURTIME_FORMAT} CHECKNUMBERSIZEANDCOPY:FROM ${LOG_SOURCE_PATH} TO ${LOG_TARGET_PATH}"
    LIMIT_NUM=500
    #500*1024MB
    LIMIT_SIZE="512000"

    if [ -d "${LOG_SOURCE_PATH}" ] && [ ! "`ls -A ${LOG_SOURCE_PATH}`" = "" ]; then
        TMP_LOG_NUM=`ls -lR ${LOG_SOURCE_PATH} |grep "^-"|wc -l | awk '{print $1}'`
        TMP_LOG_SIZE=`du -s -k ${LOG_SOURCE_PATH} | awk '{print $1}'`
        echo "${CURTIME_FORMAT} CHECKNUMBERSIZEANDCOPY:NUM:${TMP_LOG_NUM}/${LIMIT_NUM} SIZE:${TMP_LOG_SIZE}/${LIMIT_SIZE}"
        if [ ${TMP_LOG_NUM} -le ${LIMIT_NUM} ] && [ ${TMP_LOG_SIZE} -le ${LIMIT_SIZE} ]; then
            if [ ! -d ${LOG_TARGET_PATH} ];then
                mkdir -p ${LOG_TARGET_PATH}
            fi

            cp -rf ${LOG_SOURCE_PATH}/* ${LOG_TARGET_PATH}
            echo "${CURTIME_FORMAT} CHECKNUMBERSIZEANDCOPY:${LOG_SOURCE_PATH} done" >> ${SDCARD_LOG_BASE_PATH}/logkit_transfer.log
        else
            echo "${CURTIME_FORMAT} CHECKNUMBERSIZEANDCOPY:${LOG_SOURCE_PATH} NUM:${TMP_LOG_NUM}/${LIMIT_NUM} SIZE:${TMP_LOG_SIZE}/${LIMIT_SIZE}" >> ${SDCARD_LOG_BASE_PATH}/logkit_transfer.log
            rm -rf ${LOG_SOURCE_PATH}/*
        fi
    fi
}

function checkNumberSizeAndMove(){
    LOG_SOURCE_PATH="$1"
    LOG_TARGET_PATH="$2"
    LOG_LIMIT_NUM="$3"
    LOG_LIMIT_SIZE="$4"
    echo "${CURTIME_FORMAT} CHECKNUMBERSIZEANDMOVE:FROM ${LOG_SOURCE_PATH} TO ${LOG_TARGET_PATH}" >> ${SDCARD_LOG_BASE_PATH}/logkit_transfer.log
    LIMIT_NUM=500
    #500*1024KB
    LIMIT_SIZE="512000"

    if [ -d "${LOG_SOURCE_PATH}" ] && [ ! "`ls -A ${LOG_SOURCE_PATH}`" = "" ]; then
        TMP_LOG_NUM=`ls -lR ${LOG_SOURCE_PATH} |grep "^-"|wc -l | awk '{print $1}'`
        TMP_LOG_SIZE=`du -s -k ${LOG_SOURCE_PATH} | awk '{print $1}'`
        echo "${CURTIME_FORMAT} CHECKNUMBERSIZEANDMOVE:NUM:${TMP_LOG_NUM}/${LIMIT_NUM} SIZE:${TMP_LOG_SIZE}/${LIMIT_SIZE}"
        if [ ${TMP_LOG_NUM} -le ${LIMIT_NUM} ] && [ ${TMP_LOG_SIZE} -le ${LIMIT_SIZE} ]; then
            if [ ! -d ${LOG_TARGET_PATH} ];then
                mkdir -p ${LOG_TARGET_PATH}
            fi

            mv ${LOG_SOURCE_PATH}/* ${LOG_TARGET_PATH}
            echo "${CURTIME_FORMAT} CHECKNUMBERSIZEANDMOVE:${LOG_SOURCE_PATH} done" >> ${SDCARD_LOG_BASE_PATH}/logkit_transfer.log
        else
            echo "${CURTIME_FORMAT} CHECKNUMBERSIZEANDMOVE:${LOG_SOURCE_PATH} NUM:${TMP_LOG_NUM}/${LIMIT_NUM} SIZE:${TMP_LOG_SIZE}/${LIMIT_SIZE}" >> ${SDCARD_LOG_BASE_PATH}/logkit_transfer.log
            rm -rf ${LOG_SOURCE_PATH}/*
        fi
    fi
}

function checkAgingAndMove(){
    LOG_SOURCE_PATH="$1"
    LOG_TARGET_PATH="$2"
    LOG_LIMIT_NUM="$3"
    LOG_LIMIT_SIZE="$4"
    traceTransferState "CHECKAGINGANDMOVE:FROM ${LOG_SOURCE_PATH} TO ${LOG_TARGET_PATH}"
    LIMIT_NUM=500

    if [[ -d "${LOG_SOURCE_PATH}" ]] && [[ ! "`ls -A ${LOG_SOURCE_PATH}`" = "" ]]; then
        TMP_LOG_NUM=`ls -lR ${LOG_SOURCE_PATH} |grep "^-"|wc -l | awk '{print $1}'`
        traceTransferState "CHECKAGINGANDMOVE:NUM:${TMP_LOG_NUM}/${LIMIT_NUM}"
        if [[ ${TMP_LOG_NUM} -le ${LIMIT_NUM} ]]; then
            if [[ ! -d ${LOG_TARGET_PATH} ]];then
                mkdir -p ${LOG_TARGET_PATH}
            fi

            mv ${LOG_SOURCE_PATH}/* ${LOG_TARGET_PATH}
            traceTransferState "CHECKAGINGANDMOVE:${LOG_SOURCE_PATH} done"
        else
            traceTransferState "CHECKAGINGANDMOVE:${LOG_SOURCE_PATH} NUM:${TMP_LOG_NUM}/${LIMIT_NUM}"
            rm -rf ${LOG_SOURCE_PATH}/*
        fi
    fi
}

function transferSystrace(){
    SYSTRACE_LOG=/data/local/traces
    TARGET_SYSTRACE_LOG=${newpath}/systrace

    checkNumberSizeAndMove ${SYSTRACE_LOG} ${TARGET_SYSTRACE_LOG}
}

function transferScreenshots() {
    MAX_NUM=5
    is_release=`getprop ro.build.release_type`
    if [ x"${is_release}" != x"true" ]; then
        #Zhiming.chen@ANDROID.DEBUG.BugID 2724830, 2019/12/17,The log tool captures child user screenshots
        ALL_USER=`ls -t /data/media/`
        for m in $ALL_USER;
        do
            IDX=0
            screen_shot="/data/media/${m}/Pictures/Screenshots/"
            if [ -d "${screen_shot}" ]; then
                mkdir -p ${newpath}/Screenshots/$m
                touch ${newpath}/Screenshots/${m}/.nomedia
                ALL_FILE=`ls -t ${screen_shot}`
                for index in ${ALL_FILE};
                do
                    let IDX=${IDX}+1;
                    if [ "$IDX" -lt ${MAX_NUM} ] ; then
                       cp $screen_shot/${index} ${newpath}/Screenshots/${m}/
                       traceTransferState "${IDX}: ${index} done"
                    fi
                done
                traceTransferState "copy /${m} screenshots done"
            fi
        done
    fi
}

function transferTouchpanel() {
    echo "transferTouchpanel executing" >> ${SDCARD_LOG_BASE_PATH}/logkit_transfer.log
    checkFileAndMove "/sdcard/tp_debug_info.txt" "${newpath}/tp_debug_info.txt"
}

function copyWXlog() {
    LOG_TYPE=`getprop persist.sys.debuglog.config`
    if [ "${LOG_TYPE}" != "thirdpart" ]; then
        return
    fi
    stoptime=`getprop sys.oplus.log.stoptime`;
    newpath="${SDCARD_LOG_BASE_PATH}/log@stop@${stoptime}"
    saveallxlog=`getprop sys.oplus.log.save_all_xlog`
    argtrue='true'
    XLOG_MAX_NUM=35
    XLOG_IDX=0
    XLOG_DIR="/sdcard/Android/data/com.tencent.mm/MicroMsg/xlog"
    CRASH_DIR="/sdcard/Android/data/com.tencent.mm/MicroMsg/crash"
    mkdir -p ${newpath}/wxlog
    if [ "${saveallxlog}" = "${argtrue}" ]; then
        mkdir -p ${newpath}/wxlog/xlog
        if [ -d "${XLOG_DIR}" ]; then
            cp -rf ${XLOG_DIR}/*.xlog ${newpath}/wxlog/xlog/
        fi
    else
        if [ -d "${XLOG_DIR}" ]; then
            mkdir -p ${newpath}/wxlog/xlog
            ALL_FILE=`find ${XLOG_DIR} -iname '*.xlog' | xargs ls -t`
            for i in $ALL_FILE;
            do
                echo "now we have Xlog file $i"
                let XLOG_IDX=$XLOG_IDX+1;
                echo ========file num is $XLOG_IDX===========
                if [ "$XLOG_IDX" -lt $XLOG_MAX_NUM ] ; then
                    #echo  $i >> ${newpath}/xlog/.xlog.txt
                    cp $i ${newpath}/wxlog/xlog/
                fi
            done
        fi
    fi
    setprop sys.tranfer.finished cp:xlog
    mkdir -p ${newpath}/wxlog/crash
    if [ -d "${CRASH_DIR}" ]; then
            cp -rf ${CRASH_DIR}/* ${newpath}/wxlog/crash/
    fi

    XLOG_IDX=0
    if [ "${saveallxlog}" = "${argtrue}" ]; then
        mkdir -p ${newpath}/sub_wxlog/xlog
        cp -rf /storage/emulated/999/Android/data/com.tencent.mm/MicroMsg/xlog/* ${newpath}/sub_wxlog/xlog
    else
        if [ -d "/storage/emulated/999/Android/data/com.tencent.mm/MicroMsg/xlog" ]; then
            mkdir -p ${newpath}/sub_wxlog/xlog
            ALL_FILE=`ls -t /storage/emulated/999/Android/data/com.tencent.mm/MicroMsg/xlog`
            for i in $ALL_FILE;
            do
                echo "now we have subXlog file $i"
                let XLOG_IDX=$XLOG_IDX+1;
                echo ========file num is $XLOG_IDX===========
                if [ "$XLOG_IDX" -lt $XLOG_MAX_NUM ] ; then
                   echo  $i\!;
                    cp  /storage/emulated/999/Android/data/com.tencent.mm/MicroMsg/xlog/$i ${newpath}/sub_wxlog/xlog
                fi
            done
        fi
    fi
    setprop sys.tranfer.finished cp:sub_wxlog
}

function copyQlog() {
    LOG_TYPE=`getprop persist.sys.debuglog.config`
    if [ "${LOG_TYPE}" != "thirdpart" ]; then
        return
    fi
    stoptime=`getprop sys.oplus.log.stoptime`;
    newpath="${SDCARD_LOG_BASE_PATH}/log@stop@${stoptime}"
    argtrue='true'
    QLOG_MAX_NUM=100
    QLOG_IDX=0
    QLOG_DIR="/sdcard/Android/data/com.tencent.mobileqq/files/tencent/msflogs/com/tencent/mobileqq"
    mkdir -p ${newpath}/qlog
    if [ -d "${QLOG_DIR}" ]; then
        mkdir -p ${newpath}/qlog
        Q_FILE=`find ${QLOG_DIR} -iname '*log' | xargs ls -t`
        for i in $Q_FILE;
        do
            echo "now we have Qlog file $i"
            let QLOG_IDX=$QLOG_IDX+1;
            echo ========file num is $QLOG_IDX===========
            if [ "$QLOG_IDX" -lt $QLOG_MAX_NUM ] ; then
                cp $i ${newpath}/qlog
            fi
        done
    fi
    setprop sys.tranfer.finished cp:qlog

    QLOG_IDX=0
    if [ -d "/storage/emulated/999/Android/data/com.tencent.mobileqq/files/tencent/msflogs/com/tencent/mobileqq" ]; then
        mkdir -p ${newpath}/sub_qlog
        ALL_FILE=`ls -t /storage/emulated/999/Android/data/com.tencent.mobileqq/files/tencent/msflogs/com/tencent/mobileqq`
        for i in $ALL_FILE;
        do
            echo "now we have subQlog file $i"
            let QLOG_IDX=$QLOG_IDX+1;
            echo ========file num is $QLOG_IDX===========
            if [ "$QLOG_IDX" -lt $QLOG_MAX_NUM ] ; then
               echo  $i\!;
                cp  /storage/emulated/999/Android/data/com.tencent.mobileqq/files/tencent/msflogs/com/tencent/mobileqq/$i ${newpath}/sub_qlog
            fi
        done
    fi
    setprop sys.tranfer.finished cp:sub_qlog
}

function transferPower() {
    # Add for thermalrec log
    dumpsys batterystats --thermalrec
    thermalrec_dir="/data/system/thermal/dcs"
    thermalstats_file="/data/system/thermalstats.bin"
    if [ -f ${thermalstats_file} ] || [ -d ${thermalrec_dir} ]; then
        mkdir -p ${newpath}/power/thermalrec/
        chmod 770 ${thermalstats_file}
        cp -rf ${thermalstats_file} ${newpath}/power/thermalrec/

        chmod 770 /data/system/thermal/ -R
        checkNumberSizeAndCopy ${thermalrec_dir}/* ${newpath}/power/thermalrec/
    fi

    #Add for powermonitor log
    POWERMONITOR_DIR="/data/oplus/psw/powermonitor"
    chmod 770 ${POWERMONITOR_DIR} -R
    checkNumberSizeAndCopy "${POWERMONITOR_DIR}" "${newpath}/power/powermonitor"

    POWERMONITOR_BACKUP_LOG=/data/oplus/psw/powermonitor_backup/
    chmod 770 ${POWERMONITOR_BACKUP_LOG} -R
    checkNumberSizeAndCopy "${POWERMONITOR_BACKUP_LOG}" "${newpath}/power/powermonitor_backup"
}

function transferThirdApp() {
    #Chunbo.Gao@ANDROID.DEBUG.NA, 2019/6/21, Add for pubgmhd.ig
    app_pubgmhd_dir="/sdcard/Android/data/com.tencent.tmgp.pubgmhd/files/UE4Game/ShadowTrackerExtra/ShadowTrackerExtra/Saved/Logs"
    if [ -d ${app_pubgmhd_dir} ]; then
        mkdir -p ${newpath}/os/TClogs/pubgmhd
        echo "copy pubgmhd..."
        cp -rf ${app_pubgmhd_dir} ${newpath}/os/TClogs/pubgmhd
    fi

    #Yi.Jiang@ANDROID.DEBUG.NA, 2022/1/10 ,Add for kugou qqlive yx yy,wework ,tmgp.cf
    LOG_TYPE=`getprop persist.sys.debuglog.config`
    if [ "${LOG_TYPE}" != "thirdpart" ]; then
       return
    fi

    traceTransferState "${CURTIME_FORMAT} THIRDAPP:copy thirdapp start"
    stoptime=`getprop sys.oplus.log.stoptime`;
    newpath="${SDCARD_LOG_BASE_PATH}/log@stop@${stoptime}"

    app_kugou_dir="/sdcard/kugou/log"
    if [ -d ${app_kugou_dir} ]; then
        traceTransferState "${CURTIME_FORMAT} THIRDAPP:copy app_kugou_dir success " + "${?}"
        mkdir -p ${newpath}/ThirdAppLogs/kugou
        traceTransferState "copy kogou..."
        checkSmallSizeAndCopy "${app_kugou_dir}" "ThirdAppLogs/kugou"
    fi

    app_qqlive_dir="/sdcard/Android/data/com.tencent.qqlive/files/log"
    if [ -d ${app_qqlive_dir} ]; then
        mkdir -p ${newpath}/ThirdAppLogs/qqlive
        traceTransferState "copy qqlive..."
        checkSmallSizeAndCopy "${app_qqlive_dir}" "ThirdAppLogs/qqlive"
    else
        traceTransferState "${CURTIME_FORMAT} THIRDAPP:copy app_qqlive_dir fail " + "${?}"
    fi

    app_yx_dir="/sdcard/Android/data/com.yx"
    if [ -d ${app_yx_dir} ]; then
        mkdir -p ${newpath}/ThirdAppLogs/yx
        traceTransferState "copy yx..."
        checkSmallSizeAndCopy "${app_yx_dir}" "ThirdAppLogs/yx"
    else
        traceTransferState "${CURTIME_FORMAT} THIRDAPP:copy app_yx_dir fail " + "${?}"
    fi

    app_yymobile_dir="/sdcard/Android/data/com.duowan.mobile/files/yymobile/logs"
    if [ -d ${app_yymobile_dir} ]; then
        mkdir -p ${newpath}/ThirdAppLogs/yymobile
        echo "copy yymobile..."
        checkSmallSizeAndCopy "${app_yymobile_dir}" "ThirdAppLogs/yymobile"
    else
        echo "${CURTIME_FORMAT} THIRDAPP:copy app_yymobile_dir fail " + "${?}"
    fi

    app_wework_dir="/sdcard/Android/data/com.tencent.wework/files/src_clog"
    if [ -d ${app_wework_dir} ]; then
        mkdir -p ${newpath}/ThirdAppLogs/wework
        cp -rf ${app_wework_dir} ${newpath}/ThirdAppLogs/wework
        traceTransferState "${CURTIME_FORMAT} THIRDAPP:copy app_wework_dir result " + "${?}"
    else
        traceTransferState "${CURTIME_FORMAT} THIRDAPP:copy app_wework_dir fail " + "${?}"
    fi

    app_wework_dir1="/sdcard/Android/data/com.tencent.wework/files/src_log"
    if [ -d ${app_wework_dir1} ]; then
        if [ -d ${newpath}/ThirdAppLogs/wework ];then
           mkdir -p ${newpath}/ThirdAppLogs/wework
        fi
        cp -rf ${app_wework_dir1} ${newpath}/ThirdAppLogs/wework
        traceTransferState "${CURTIME_FORMAT} THIRDAPP:copy app_wework_dir1 result " + "${?}"
    else
        traceTransferState "${CURTIME_FORMAT} THIRDAPP:copy app_wework_dir1 fail " + "${?}"
    fi


    app_tmgpcf_dir="/sdcard/Android/data/com.tencent.tmgp.cf/cache/Cache/Log/"
    if [ -d ${app_tmgpcf_dir} ]; then
        mkdir -p ${newpath}/ThirdAppLogs/tmgpcf
        traceTransferState "copy tmgp cf..."
        checkSmallSizeAndCopy "${app_tmgpcf_dir}" "ThirdAppLogs/tmgpcf"
    fi

    traceTransferState "${CURTIME_FORMAT} THIRDAPP:copy thirdapp done"
}

function transferSystemAppLog(){
    #TraceLog
    TRACELOG=/sdcard/Documents/TraceLog
    checkSmallSizeAndCopy "${TRACELOG}" "os/TraceLog"

    #OVMS
    OVMS_LOG=/sdcard/Documents/OVMS
    checkSmallSizeAndCopy "${OVMS_LOG}" "os/OVMS"

    #Pictorial
    PICTORIAL_LOG=/sdcard/Android/data/com.heytap.pictorial/files/xlog
    checkSmallSizeAndCopy "${PICTORIAL_LOG}" "os/Pictorial"

    #Camera
    CAMERA_LOG=/sdcard/DCIM/Camera/spdebug
    checkSmallSizeAndCopy "${CAMERA_LOG}" "os/Camera"

    #Browser
    BROWSER_LOG=/sdcard/Android/data/com.heytap.browser/files/xlog
    checkSizeAndCopy "${BROWSER_LOG}" "os/com.heytap.browser"

    #OBRAIN
    OBRAIN_LOG=/data/misc/midas/xlog
    checkSmallSizeAndCopy "${OBRAIN_LOG}" "os/com.oplus.obrain"

    #YOLI
    YOLI_LOG1=/sdcard/Android/data/com.heytap.yoli/files/yoliVideo/xlog
    checkSmallSizeAndCopy "${YOLI_LOG1}" "os/com.heytap.yoli"

    #common path
    cp -rf /sdcard/Documents/*/.dog/* ${newpath}/os/
    traceTransferState "transfer log:copy system app done"
}

function transferUser() {
    stoptime=`getprop sys.oplus.log.stoptime`;
    userpath="${SDCARD_LOG_BASE_PATH}/log@stop@${stoptime}"

    USER_LOG=/data/system/users/0/*
    TARGET_USER_LOG=${userpath}/user_0
    mkdir -p ${TARGET_USER_LOG}
    touch ${TARGET_USER_LOG}/.nomedia
    checkNumberSizeAndCopy ${USER_LOG} ${TARGET_USER_LOG}

    wait
}

function transferDebuggingLog() {
    TARGET_MTK_DEBUG_PATH=${newpath}/debuglogger

    traceTransferState "TRANSFERDEBUGGINGLOG start "
    # 1-1
    if [ -d  ${MTK_DEBUG_PATH} ]; then
        ALL_SUB_DIR=`ls ${MTK_DEBUG_PATH} | grep -v SI_stop`
        for SUB_DIR in ${ALL_SUB_DIR};do
            if [[ -d ${MTK_DEBUG_PATH}/${SUB_DIR} ]] || [[ -f ${MTK_DEBUG_PATH}/${SUB_DIR} ]]; then
                if [[ ! -d ${TARGET_MTK_DEBUG_PATH} ]]; then
                    mkdir ${TARGET_MTK_DEBUG_PATH}
                fi
                traceTransferState "TRANSFERDEBUGGINGLOG:mv ${MTK_DEBUG_PATH}/${SUB_DIR} to ${TARGET_MTK_DEBUG_PATH}"
                mv ${MTK_DEBUG_PATH}/${SUB_DIR} ${TARGET_MTK_DEBUG_PATH}
            fi
        done
    fi

    #1-2
    if [[ -d  ${DATA_DEBUGGING_PATH} ]]; then
        ALL_SUB_DIR=`ls ${DATA_DEBUGGING_PATH} | grep -v SI_stop`
        for SUB_DIR in ${ALL_SUB_DIR};do
            if [[ -d ${DATA_DEBUGGING_PATH}/${SUB_DIR} ]] || [[ -f ${DATA_DEBUGGING_PATH}/${SUB_DIR} ]]; then
                traceTransferState "TRANSFERDEBUGGINGLOG:mv ${DATA_DEBUGGING_PATH}/${SUB_DIR} to ${newpath}"
                mv ${DATA_DEBUGGING_PATH}/${SUB_DIR} ${newpath}
            fi
        done
    fi
    traceTransferState "TRANSFERDEBUGGINGLOG done "
}

function traceTransferState() {
    if [ ! -d ${SDCARD_LOG_BASE_PATH} ]; then
        mkdir -p ${SDCARD_LOG_BASE_PATH}
        chmod 770 ${SDCARD_LOG_BASE_PATH} -R
        echo "${CURTIME_FORMAT} TRACETRANSFERSTATE:${SDCARD_LOG_BASE_PATH} " >> ${SDCARD_LOG_BASE_PATH}/logkit_transfer.log
    fi

    content=$1
    currentTime=`date "+%Y-%m-%d %H:%M:%S"`
    echo "${currentTime} ${content} " >> ${SDCARD_LOG_BASE_PATH}/logkit_transfer.log
}

function transferDataPersistLog(){
    TARGET_DATA_OPLUS_LOG=${newpath}/assistlog

    chmod 777 ${DATA_OPLUS_LOG_PATH}/ -R
    #tar -czvf ${newpath}/LOG.dat.gz -C ${DATA_OPLUS_LOG_PATH} .
    #tar -czvf ${TARGET_DATA_OPLUS_LOG}/LOG.tar.gz ${DATA_OPLUS_LOG}

    # filter DCS
    if [[ -d  ${DATA_OPLUS_LOG_PATH} ]]; then
        ALL_SUB_DIR=`ls ${DATA_OPLUS_LOG_PATH} | grep -v DCS | grep -v data_vendor | grep -v TMP | grep -v hprofdump`
        for SUB_DIR in ${ALL_SUB_DIR};do
            if [[ -d ${DATA_OPLUS_LOG_PATH}/${SUB_DIR} ]] || [[ -f ${DATA_OPLUS_LOG_PATH}/${SUB_DIR} ]]; then
                checkNumberSizeAndCopy "${DATA_OPLUS_LOG_PATH}/${SUB_DIR}" "${TARGET_DATA_OPLUS_LOG}/${SUB_DIR}"
            fi
        done
    fi

    transferDataDCS
    transferDataTMP
    transferDataHprof
}

function transferDataDCS(){
    DATA_DCS_LOG=${DATA_OPLUS_LOG_PATH}/DCS/de
    TARGET_DATA_DCS_LOG=${newpath}/assistlog/DCS

    if [[ -d  ${DATA_DCS_LOG} ]]; then
        ALL_SUB_DIR=`ls ${DATA_DCS_LOG}`
        for SUB_DIR in ${ALL_SUB_DIR};do
            if [[ -d ${DATA_DCS_LOG}/${SUB_DIR} ]] || [[ -f ${DATA_DCS_LOG}/${SUB_DIR} ]]; then
                checkNumberSizeAndCopy "${DATA_DCS_LOG}/${SUB_DIR}" "${TARGET_DATA_DCS_LOG}/${SUB_DIR}"
            fi
        done
    fi

    DATA_DCS_BACKUP_LOG=${DATA_OPLUS_LOG_PATH}/backup
    if [ -d  ${DATA_DCS_LOG} ]; then
        ALL_SUB_DIR=`ls ${DATA_DCS_BACKUP_LOG}`
        for SUB_DIR in ${ALL_SUB_DIR};do
            if [ -d ${DATA_DCS_BACKUP_LOG}/${SUB_DIR} ] || [ -f ${DATA_DCS_BACKUP_LOG}/${SUB_DIR} ]; then
                checkNumberSizeAndCopy "${DATA_DCS_BACKUP_LOG}/${SUB_DIR}" "${TARGET_DATA_DCS_LOG}/${SUB_DIR}"
            fi
        done
    fi
}

function transferDataTMP(){
    DATA_TMP_LOG=${DATA_OPLUS_LOG_PATH}/TMP
    TARGET_DATA_TMP_LOG=${newpath}/assistlog

    if [[ -d ${DATA_TMP_LOG} ]]; then
        ALL_SUB_DIR=`ls ${DATA_TMP_LOG}`
        for SUB_DIR in ${ALL_SUB_DIR};do
            if [[ -d ${DATA_TMP_LOG}/${SUB_DIR} ]] || [[ -f ${DATA_TMP_LOG}/${SUB_DIR} ]]; then
                checkNumberSizeAndMove "${DATA_TMP_LOG}/${SUB_DIR}" "${TARGET_DATA_TMP_LOG}/${SUB_DIR}"
            fi
        done
    fi
}

function transferDataHprof(){
    DATA_HPROF_LOG=${DATA_OPLUS_LOG_PATH}
    TARGET_DATA_HPROF_LOG=${newpath}/assistlog

    if [[ -d ${DATA_HPROF_LOG} ]]; then
        ALL_SUB_DIR=`ls ${DATA_HPROF_LOG} | grep hprofdump`
        for SUB_DIR in ${ALL_SUB_DIR};do
            if [[ -d ${DATA_HPROF_LOG}/${SUB_DIR} ]] || [[ -f ${DATA_HPROF_LOG}/${SUB_DIR} ]]; then
                checkAgingAndMove "${DATA_HPROF_LOG}/${SUB_DIR}" "${TARGET_DATA_HPROF_LOG}/${SUB_DIR}"
            fi
        done
    fi
}

function transferDataVendor(){
    stoptime=`getprop sys.oplus.log.stoptime`;
    newpath="${SDCARD_LOG_BASE_PATH}/log@stop@${stoptime}"
    DATA_VENDOR_LOG=${DATA_OPLUS_LOG_PATH}/data_vendor
    TARGET_DATA_VENDOR_LOG=${newpath}/data_vendor

    if [ -d  ${DATA_VENDOR_LOG} ]; then
        chmod 777 ${DATA_VENDOR_LOG} -R
        ALL_SUB_DIR=`ls ${DATA_VENDOR_LOG}`
        for SUB_DIR in ${ALL_SUB_DIR};do
            if [ -d ${DATA_VENDOR_LOG}/${SUB_DIR} ] || [ -f ${DATA_VENDOR_LOG}/${SUB_DIR} ]; then
                checkNumberSizeAndMove "${DATA_VENDOR_LOG}/${SUB_DIR}" "${TARGET_DATA_VENDOR_LOG}/${SUB_DIR}"
            fi
        done
    fi
    chmod 777 ${TARGET_DATA_VENDOR_LOG} -R
}

function getSystemStatus() {
    echo "${CURTIME_FORMAT} GETSYSTEMSTATUS:start...." >> ${SDCARD_LOG_BASE_PATH}/logkit_transfer.log
    stoptime=`getprop sys.oplus.log.stoptime`;
    newpath="${SDCARD_LOG_BASE_PATH}/log@stop@${stoptime}"
    SYSTEM_STATUS_PATH=${newpath}/SI_stop
    mkdir -p ${SYSTEM_STATUS_PATH}
    rm -f ${SYSTEM_STATUS_PATH}/finish_system
    echo "${CURTIME_FORMAT} GETSYSTEMSTATUS:${SYSTEM_STATUS_PATH}" >> ${SDCARD_LOG_BASE_PATH}/logkit_transfer.log

    echo "${CURTIME_FORMAT} GETSYSTEMSTATUS:ps,top" >> ${SDCARD_LOG_BASE_PATH}/logkit_transfer.log
    ps -A -T > ${SYSTEM_STATUS_PATH}/ps.txt
    top -n 1 > ${SYSTEM_STATUS_PATH}/top.txt
    cat /proc/meminfo > ${SYSTEM_STATUS_PATH}/proc_meminfo.txt

    cat /proc/osvelte/dma_buf/bufinfo > ${SYSTEM_STATUS_PATH}/dma_buf_bufinfo.txt
    cat /proc/osvelte/dma_buf/procinfo > ${SYSTEM_STATUS_PATH}/dma_buf_procinfo.txt

    getprop > ${SYSTEM_STATUS_PATH}/prop.txt
    df > ${SYSTEM_STATUS_PATH}/df.txt
    mount > ${SYSTEM_STATUS_PATH}/mount.txt
    cat /proc/meminfo > ${SYSTEM_STATUS_PATH}/proc_meminfo.txt
    cat /data/system/packages.xml  > ${SYSTEM_STATUS_PATH}/packages.txt
    cat /data/system/appops.xml  > ${SYSTEM_STATUS_PATH}/appops.xml
    cat /proc/zoneinfo > ${SYSTEM_STATUS_PATH}/zoneinfo.txt
    cat /proc/slabinfo > ${SYSTEM_STATUS_PATH}/slabinfo.txt
    cat /proc/interrupts > ${SYSTEM_STATUS_PATH}/interrupts.txt
    cat /sys/kernel/debug/wakeup_sources > ${SYSTEM_STATUS_PATH}/wakeup_sources.log
    cp -rf /sys/kernel/debug/ion ${SYSTEM_STATUS_PATH}/

    #dumpsys appops
    dumpsys appops > ${SYSTEM_STATUS_PATH}/dumpsys_appops.xml

    #dumpsys meminfo
    dumpsys -t 15 meminfo > ${SYSTEM_STATUS_PATH}/dumpsys_meminfo.txt &

    #dumpsys package
    dumpsys package --da > ${SYSTEM_STATUS_PATH}/dumpsys_package_da.txt

    dumpsys location > ${SYSTEM_STATUS_PATH}/dumpsys_location.txt
    dumpsys nfc > ${SYSTEM_STATUS_PATH}/dumpsys_nfc.txt
    dumpsys secure_element > ${SYSTEM_STATUS_PATH}/dumpsys_secure_element.txt
    dumpsys user > ${SYSTEM_STATUS_PATH}/dumpsys_user.txt
    dumpsys power > ${SYSTEM_STATUS_PATH}/dumpsys_power.txt
    dumpsys cpuinfo > ${SYSTEM_STATUS_PATH}/dumpsys_cpuinfo.txt
    dumpsys alarm > ${SYSTEM_STATUS_PATH}/dumpsys_alarm.txt
    dumpsys batterystats > ${SYSTEM_STATUS_PATH}/dumpsys_batterystats.txt
    dumpsys batterystats -c > ${SYSTEM_STATUS_PATH}/battersystats_for_bh.txt
    dumpsys activity exit-info > ${SYSTEM_STATUS_PATH}/dumpsys_exit_info.txt
    traceTransferState "dropbox:start"
    dumpsys dropbox --print > ${SYSTEM_STATUS_PATH}/dumpsys_dropbox_all.txt
    traceTransferState "dropbox:end"

    #dumpsys settings
    traceTransferState "dumpSystem:settings"
    dumpsys settings --no-config --all-history > ${SYSTEM_STATUS_PATH}/dumpsys_settings_no_config_all_history.txt
    traceTransferState "dumpSystem:settings done"

    traceTransferState "dumpSystem:dumpsys notification"
    dumpsys notification > ${SYSTEM_STATUS_PATH}/dumpsys_notification.xml
    cat /data/system/notification_policy.xml > ${SYSTEM_STATUS_PATH}/notification_policy.xml
    traceTransferState "dumpSystem:notification done"
    #yong8.huang@ANDROID.AMS, 2020/12/30, Add for dumpsys activity info
    dumpsys activity processes > ${SYSTEM_STATUS_PATH}/dumpsys_processes.txt
    dumpsys activity broadcasts > ${SYSTEM_STATUS_PATH}/dumpsys_broadcasts.txt
    dumpsys activity providers > ${SYSTEM_STATUS_PATH}/dumpsys_providers.txt
    dumpsys activity services > ${SYSTEM_STATUS_PATH}/dumpsys_services.txt

    #Hun.Xu@ANDROID.SENSOR,2021/07/16, Add for dumpsys sensorservice info
    dumpsys sensorservice > ${SYSTEM_STATUS_PATH}/dumpsys_sensorservice.txt

    #Qianyou.Chen@Android.MULTIUSER, 2021/12/13, Add for dumpsys accessibility services
    dumpsys accessibility > ${SYSTEM_STATUS_PATH}/dumpsys_accessibility.txt
    #Qianyou.Chen@Android.MULTIUSER, 2021/12/13, Add for dumpsys device/profile owner
    dumpsys device_policy > ${SYSTEM_STATUS_PATH}/dumpsys_devicepolicy.txt

    ##kevin.li@ROM.Framework, 2019/11/5, add for hans freeze manager(for protection)
    hans_enable=`getprop persist.sys.enable.hans`
    if [ "$hans_enable" == "true" ]; then
        dumpsys activity hans history > ${SYSTEM_STATUS_PATH}/dumpsys_hans_history.txt
    fi
    #kevin.li@ROM.Framework, 2019/12/2, add for hans cts property
    hans_enable=`getprop persist.vendor.enable.hans`
    if [ "$hans_enable" == "true" ]; then
        dumpsys activity hans history > ${SYSTEM_STATUS_PATH}/dumpsys_hans_history.txt
    fi

    #chao.zhu@ROM.Framework, 2020/04/17, add for preload
    preload_enable=`getprop persist.vendor.enable.preload`
    if [ "$preload_enable" == "true" ]; then
        dumpsys activity preload > ${SYSTEM_STATUS_PATH}/dumpsys_preload.txt
    fi

    #qingxin.guo@ROM.Framework, 2022/04/25, add for cpulimit
    cpulimit_enable=`getprop persist.vendor.enable.cpulimit`
    if [ "$cpulimit_enable" == "true" ]; then
        dumpsys activity cpulimit history > ${outputPath}/dumpsys_cpulimit_history.txt
    fi

    #liqiang3@ANROID.RESCONTROL, 2021/12/15, add for jobscheduler
    dumpsys jobscheduler > ${SYSTEM_STATUS_PATH}/dumpsys_jobscheduler.txt

    #CaiLiuzhuang@MULTIMEDIA.AUDIODRIVER.FEATURE, 2021/01/18, Add for dump media log
    dumpMedia

    #kevin.li@ANDROID.RESCONTROL, 2021/10/18, add for Osense
    dumpsys osensemanager log > ${SYSTEM_STATUS_PATH}/dumpsys_osense_log.txt

    echo "${CURTIME_FORMAT} GETSYSTEMSTATUS:done...." >> ${SDCARD_LOG_BASE_PATH}/logkit_transfer.log
    wait
    touch ${SYSTEM_STATUS_PATH}/finish_system
}

#CaiLiuzhuang@MULTIMEDIA.AUDIODRIVER.FEATURE, 2021/01/18, Add for dump media log
function dumpMedia() {
    mediaTypes=(media bluetooth thirdpart)
    LOG_TYPE=`getprop persist.sys.debuglog.config`
    if [[ "${mediaTypes[@]}" != *"${LOG_TYPE}"* ]]; then
        return
    fi
    mediaPath="${SYSTEM_STATUS_PATH}/media"
    mkdir -p ${mediaPath}
    echo "${CURTIME_FORMAT} dumpMedia:start...." >> ${SDCARD_LOG_BASE_PATH}/logkit_transfer.log
    dumpsys media.audio_flinger > ${mediaPath}/audio_flinger.txt
    dumpsys media.audio_policy > ${mediaPath}/audio_policy.txt
    dumpsys media.metrics > ${mediaPath}/media_metrics.txt
    dumpsys media_session > ${mediaPath}/media_session.txt
    dumpsys media_router > ${mediaPath}/media_router.txt
    dumpsys audio > ${mediaPath}/audioservice.txt
    dumpsys media.player > ${mediaPath}/media_player.txt
    pid_audioserver=`pgrep -f audioserver`
    debuggerd -b ${pid_audioserver} > ${mediaPath}/audioserver.txt
    pid_audiohal=`pgrep -f audio.service`
    debuggerd -b ${pid_audiohal} > ${mediaPath}/audiohal.txt
    atlasservice=`pgrep -f atlasservice`
    debuggerd -b ${atlasservice} > ${mediaPath}/atlasservice.txt
    system_server=`pgrep -f system_server`
    debuggerd -j ${system_server} > ${mediaPath}/system_server.txt
    multimedia=`pgrep -f persist.multimedia`
    debuggerd -j ${multimedia} > ${mediaPath}/multimedia.txt
    echo "${CURTIME_FORMAT} dumpMedia:done...." >> ${SDCARD_LOG_BASE_PATH}/logkit_transfer.log
}

function checkStartServicesDone(){
    traceTransferState "check ctl.start services done"
    checkServicesList=(dump_system transferUser transfer_anrtomb transfer_bugreport)
    allSerivcesDoneFlag=1
    timeCount=0
    while [ ${allSerivcesDoneFlag} -eq 1 ] && [ timeCount -le 30 ]
    do
        allSerivcesDoneFlag=0
        for i in "${!checkServicesList[@]}"
        do
            serviceStatus=`getprop init.svc.${checkServicesList[$i]}`
            traceTransferState "${checkServicesList[$i]} state:${serviceStatus}"
            if [[ "${serviceStatus}" == "running" ]];then
                allSerivcesDoneFlag=1
            else
                unset checkServicesList[i]
            fi
        done
        echo "${CURTIME_FORMAT} ${LOGTAG}:count=$timeCount" >> ${SDCARD_LOG_BASE_PATH}/logkit_transfer.log
        timeCount=$((timeCount + 1))
        sleep 1
    done
}

function transferAnrTomb() {
    stoptime=`getprop sys.oplus.log.stoptime`;
    TMP_PATH="${SDCARD_LOG_BASE_PATH}/log@stop@${stoptime}"
    echo "${CURTIME_FORMAT} TRANSFERANRTOMB:start...." >> ${SDCARD_LOG_BASE_PATH}/logkit_transfer.log

    ANR_LOG=/data/anr
    TARGET_ANR_LOG=${TMP_PATH}/anr
    TOMBSTONE_LOG=/data/tombstones
    TARGET_TOMBSTONE_LOG=${TMP_PATH}/tombstones

    checkNumberSizeAndCopy "${ANR_LOG}" "${TARGET_ANR_LOG}"
    checkNumberSizeAndCopy "${TOMBSTONE_LOG}" "${TARGET_TOMBSTONE_LOG}"

    echo "${CURTIME_FORMAT} TRANSFERANRTOMB:done...." >> ${SDCARD_LOG_BASE_PATH}/logkit_transfer.log
    wait
}

#ifdef OPLUS_FEATURE_BT_HCI_LOG
# added by bluetooth team
function transferBtCachedSnoop() {
    btCachedPath=`getprop persist.sys.oplus.bt.cache_hcilog_path`
    if [ "w${btCachedPath}" == "w" ];then
        btCachedPath="/data/misc/bluetooth/cached_hci/"
    fi
    echo "${CURTIME_FORMAT} transferBtCachedSnoop:start...." >> ${SDCARD_LOG_BASE_PATH}/logkit_transfer.log
    stoptime=`getprop sys.oplus.log.stoptime`;
    newpath="${SDCARD_LOG_BASE_PATH}/log@stop@${stoptime}"
    #mkdir -p "${newpath}/cached_hci/"
    #echo "${CURTIME_FORMAT} btCachedPath=${btCachedPath}, newpath=${newpath}" >> ${SDCARD_LOG_BASE_PATH}/logkit_transfer.log
    checkNumberSizeAndCopy "${btCachedPath}" "${newpath}/cached_hci/"
    echo "${CURTIME_FORMAT} transferBtCachedSnoop:done...." >> ${SDCARD_LOG_BASE_PATH}/logkit_transfer.log
}
#endif /* OPLUS_FEATURE_BT_HCI_LOG */

function transferMtkLog() {
    LOGTAG="MTKLOG"
    setprop ctl.start dump_system
    setprop ctl.start transferUser
    setprop ctl.start transfer_anrtomb

    stoptime=`getprop sys.oplus.log.stoptime`;
    echo "${CURTIME_FORMAT} ${LOGTAG}:start...." >> ${SDCARD_LOG_BASE_PATH}/logkit_transfer.log
    newpath="${SDCARD_LOG_BASE_PATH}/log@stop@${stoptime}"
    mkdirInSpecificPermission ${newpath} 2770
    echo "${CURTIME_FORMAT} ${LOGTAG}:from ${DATA_DEBUGGING_PATH} to ${newpath}" >> ${SDCARD_LOG_BASE_PATH}/logkit_transfer.log

    mvrecoverylog

    setprop ctl.start transfer_bugreport

    transferDebuggingLog

    transferScreenshots

    transferTouchpanel
    mv ${SDCARD_LOG_BASE_PATH}/recovery_log/ ${newpath}
    mv ${SDCARD_LOG_TRIGGER_PATH} ${newpath}/

    copyWXlog
    copyQlog

    transferPower
    transferThirdApp
    transferSystemAppLog

    #cp dropbox traces tombstone
    chmod 777 -R /data/system/dropbox
    chmod 777 -R /data/anr
    chmod 777 -R /data/tombstones
    cp -rf /data/system/dropbox ${newpath}/

    transferDataPersistLog

    #ifdef OPLUS_FEATURE_BT_HCI_LOG
    # added by bluetooth team
    transferBtCachedSnoop
    #endif /* OPLUS_FEATURE_BT_HCI_LOG */

    # systrace
    transferSystrace

    ## cp aee_exp/
    mkdir -p ${newpath}/data_aee
    cp -rf /data/aee_exp/* ${newpath}/data_aee
    rm -rf /data/aee_exp/*

    #checkDumpSystemDone
    checkStartServicesDone

    chmodFromBasePath

    mv ${SDCARD_LOG_BASE_PATH}/bugreports/ ${newpath}/

    wait
    setprop sys.tranfer.finished 1
    echo "${CURTIME_FORMAT} ${LOGTAG}:done...." >> ${SDCARD_LOG_BASE_PATH}/logkit_transfer.log
    mv ${SDCARD_LOG_BASE_PATH}/logkit_transfer.log ${newpath}/
}

function chmodFromBasePath() {
    traceTransferState "chmodFromBasePath"
    chmod 2770 ${BASE_PATH} -R
    SDCARDFS_ENABLED=`getprop external_storage.sdcardfs.enabled 1`
    traceTransferState "TRANSFER_LOG:SDCARDFS_ENABLED is ${SDCARDFS_ENABLED}"
    if [ "${SDCARDFS_ENABLED}" == "0" ]; then
        chown system:ext_data_rw ${SDCARD_LOG_BASE_PATH} -R
    fi
}

function mkdirInSpecificPermission() {
    MKDIR_PATH=$1
    MKDIR_PERMISSION=$2
    if [ ! -d ${MKDIR_PATH} ]; then
        mkdir -p ${MKDIR_PATH}
    fi
    chmod ${MKDIR_PERMISSION} ${MKDIR_PATH} -R
}

#ifdef OPLUS_FEATURE_EAP
#Haifei.Liu@ANDROID.RESCONTROL, 2020/08/18, Add for copy binder_info
function copyEapBinderInfo() {
    destBinderInfoPath=`getprop sys.eap.binderinfo.path`
    echo ${destBinderInfoPath}
    if [ -f "/dev/binderfs/binder_logs/state" ]; then
        cat /dev/binderfs/binder_logs/state > ${destBinderInfoPath}
    else
        cat /sys/kernel/debug/binder/state > ${destBinderInfoPath}
    fi
}
#endif /* OPLUS_FEATURE_EAP */

# ifdef OPLUS_FEATURE_THEIA
# Yangkai.Yu@ANDROID.STABILITY, Add hook for TheiaBinderBlock
function copyTheiaBinderInfo() {
    destBinderFile=`getprop sys.theia.binderpath`
    echo "copy binder infomation to ${destBinderFile}"
    if [ -f "/dev/binderfs/binder_logs/transactions" ]; then
        cat /dev/binderfs/binder_logs/transactions > ${destBinderFile}
    else
        cat /sys/kernel/debug/binder/transactions > ${destBinderFile}
    fi
}
# endif /*OPLUS_FEATURE_THEIA*/

function dumpsysInfo(){
    if [ ! -d ${SDCARD_LOG_TRIGGER_PATH} ];then
        mkdir -p ${SDCARD_LOG_TRIGGER_PATH}
    fi
    dumpsys > ${SDCARD_LOG_TRIGGER_PATH}/dumpsys_all_${CURTIME}.txt;
}
function dumpStateInfo(){
    if [ ! -d ${SDCARD_LOG_TRIGGER_PATH} ];then
        mkdir -p ${SDCARD_LOG_TRIGGER_PATH}
    fi
    dumpstate > ${SDCARD_LOG_TRIGGER_PATH}/dumpstate_${CURTIME}.txt
}
function topInfo(){
    if [ ! -d ${SDCARD_LOG_TRIGGER_PATH} ];then
        mkdir -p ${SDCARD_LOG_TRIGGER_PATH}
    fi
    top -n 1 > ${SDCARD_LOG_TRIGGER_PATH}/top_${CURTIME}.txt;
}
function psInfo(){
    if [ ! -d ${SDCARD_LOG_TRIGGER_PATH} ];then
        mkdir -p ${SDCARD_LOG_TRIGGER_PATH}
    fi
    ps > ${SDCARD_LOG_TRIGGER_PATH}/ps_${CURTIME}.txt;
}
function serviceListInfo(){
    if [ ! -d ${SDCARD_LOG_TRIGGER_PATH} ];then
        mkdir -p ${SDCARD_LOG_TRIGGER_PATH}
    fi
    service list > ${SDCARD_LOG_TRIGGER_PATH}/service_list_${CURTIME}.txt;
}
function dumpStorageInfo() {
    STORAGE_PATH=${SDCARD_LOG_TRIGGER_PATH}/storage
    if [ ! -d ${STORAGE_PATH} ];then
        mkdir -p ${STORAGE_PATH}
    fi

    mount > ${STORAGE_PATH}/mount.txt
    dumpsys devicestoragemonitor > ${STORAGE_PATH}/dumpsys_devicestoragemonitor.txt
    dumpsys mount > ${STORAGE_PATH}/dumpsys_mount.txt
    dumpsys diskstats > ${STORAGE_PATH}/dumpsys_diskstats.txt
    du -H /data > ${STORAGE_PATH}/diskUsage.txt
}

function mvrecoverylog() {
    echo "mvrecoverylog begin"
    rm -rf ${SDCARD_LOG_BASE_PATH}/recovery_log/
    mkdir -p ${SDCARD_LOG_BASE_PATH}/recovery_log
    state=`getprop ro.build.ab_update`
    if [ "${state}" = "true" ] ;then
        mkdir -p ${SDCARD_LOG_BASE_PATH}/recovery_log/recovery
        mkdir -p ${SDCARD_LOG_BASE_PATH}/recovery_log/factory
        mkdir -p ${SDCARD_LOG_BASE_PATH}/recovery_log/update_engine_log
        setprop sys.oplus.copyrecoverylog 1
    else
        mv /cache/recovery/* ${SDCARD_LOG_BASE_PATH}/recovery_log
    fi
    echo "mvrecoverylog end"
}

function customdmesg() {
    echo "customdmesg begin"
    chmod 777 -R ${DATA_DEBUGGING_PATH}
    echo "customdmesg end"
}

function checkAeeLogs() {
    echo "checkAeeLogs begin"
    setprop sys.move.aeevendor.ready 0
    cp -rf /data/vendor/aee_exp/db.* /data/aee_exp/
    rm -rf /data/vendor/aee_exp/db.*
    restorecon -RF /data/aee_exp/
    chmod 777 -R /data/aee_exp/
    setprop sys.move.aeevendor.ready 1
    echo "checkAeeLogs end"
}

function DumpEnvironment(){
    setprop sys.dumpenvironment.finished 1
}

# Kun.Hu@TECH.BSP.Stability.Phoenix, 2019/4/17, fix the core domain limits to search hang_oplus dirent
function remount_oplusreserve2() {
    HANGOPLUS_DIR_REMOUNT_POINT="/data/persist_log/oplusreserve/media/log/hang_oplus"
    if [ ! -d ${HANGOPLUS_DIR_REMOUNT_POINT} ]; then
        mkdir -p ${HANGOPLUS_DIR_REMOUNT_POINT}
    fi
    chmod -R 0770 /data/persist_log/oplusreserve
    chgrp -R system /data/persist_log/oplusreserve
    chown -R system /data/persist_log/oplusreserve
    mount /mnt/vendor/oplusreserve/media/log/hang_oplus ${HANGOPLUS_DIR_REMOUNT_POINT}
}

#ifdef OPLUS_FEATURE_SHUTDOWN_DETECT
#Liang.Zhang@TECH.Storage.Stability.OPLUS_SHUTDOWN_DETECT, 2019/04/28, Add for shutdown detect
function remount_oplusreserve2_shutdown() {
    OPLUSRESERVE2_REMOUNT_POINT="/data/persist_log/oplusreserve/media/log/shutdown"
    if [ ! -d ${OPLUSRESERVE2_REMOUNT_POINT} ]; then
        mkdir ${OPLUSRESERVE2_REMOUNT_POINT}
    fi
    chmod 0770 /data/persist_log/oplusreserve
    chgrp system /data/persist_log/oplusreserve
    chown system /data/persist_log/oplusreserve
    mount /mnt/vendor/oplusreserve/media/log/shutdown ${OPLUSRESERVE2_REMOUNT_POINT}
}
#endif

#Xuefeng.Peng@PSW.AD.Performance.Storage.1721598, 2018/12/26, Add for customize version to control sdcard
#Kang.Zou@PSW.AD.Performance.Storage.1721598, 2019/10/17, Add for customize version to control sdcard with new methods
function exstorage_support() {
    exStorage_support=`getprop persist.sys.exStorage_support`
    if [ x"${exStorage_support}" == x"1" ]; then
        #echo 1 > /sys/class/mmc_host/mmc0/exStorage_support
        echo 1 > /sys/bus/mmc/drivers_autoprobe
        mmc_devicename=$(ls /sys/bus/mmc/devices | grep "mmc0:")
        if [ -n "$mmc_devicename" ];then
            echo "$mmc_devicename" > /sys/bus/mmc/drivers/mmcblk/bind
        fi
        #echo "fsck test start" >> /data/media/0/fsck.txt

        #DATE=`date +%F-%H-%M-%S`
        #echo "${DATE}" >> /data/media/0/fsck.txt
        #echo "fsck test end" >> /data/media/0/fsck.txt
    fi
    if [ x"${exStorage_support}" == x"0" ]; then
        #echo 0 > /sys/class/mmc_host/mmc0/exStorage_support
        echo 0 > /sys/bus/mmc/drivers_autoprobe
        mmc_devicename=$(ls /sys/bus/mmc/devices | grep "mmc0:")
        if [ -n "$mmc_devicename" ];then
            echo "$mmc_devicename" > /sys/bus/mmc/drivers/mmcblk/unbind
        fi
        #echo "fsck test111 start" >> /data/media/0/fsck.txt

        #DATE=`date +%F-%H-%M-%S`
        #echo "${DATE}" >> /data/media/0/fsck.txt
        #echo "fsck test111 end" >> /data/media/0/fsck.txt
    fi
}

#Xiaomin.Yang@PSW.CN.BT.Basic.Customize.1586031,2018/12/02, Add for updating wcn firmware by sau_res
function wcnfirmwareupdate(){

    saufwdir="/data/oplus/common/sau_res/res/SAU-AUTO_LOAD_FW-10/"
    pushfwdir="/data/misc/firmware/push/"
    if [ -f ${saufwdir}/ROMv4_be_patch_1_0_hdr.bin ]; then
        cp  ${saufwdir}/ROMv4_be_patch_1_0_hdr.bin  ${pushfwdir}
        chown system:system ${pushfwdir}/ROMv4_be_patch_1_0_hdr.bin
        chmod 666 ${pushfwdir}/ROMv4_be_patch_1_0_hdr.bin
    fi

    if [ -f ${saufwdir}/ROMv4_be_patch_1_1_hdr.bin ]; then
        cp  ${saufwdir}/ROMv4_be_patch_1_1_hdr.bin  ${pushfwdir}
        chown system:system ${pushfwdir}/ROMv4_be_patch_1_1_hdr.bin
        chmod 666 ${pushfwdir}/ROMv4_be_patch_1_1_hdr.bin
    fi

    if [ -f ${saufwdir}/WIFI_RAM_CODE_6759 ]; then
       cp  ${saufwdir}/WIFI_RAM_CODE_6759  ${pushfwdir}
       chown system:system ${pushfwdir}/WIFI_RAM_CODE_6759
       chmod 666 ${pushfwdir}/WIFI_RAM_CODE_6759
    fi

    if [ -f ${saufwdir}/soc2_0_patch_mcu_3_1_hdr.bin ]; then
       cp  ${saufwdir}/soc2_0_patch_mcu_3_1_hdr.bin  ${pushfwdir}
       chown system:system ${pushfwdir}/soc2_0_patch_mcu_3_1_hdr.bin
       chmod 666  ${pushfwdir}/soc2_0_patch_mcu_3_1_hdr.bin
    fi

    if [ -f ${saufwdir}/soc2_0_ram_mcu_3_1_hdr.bin ]; then
       cp  ${saufwdir}/soc2_0_ram_mcu_3_1_hdr.bin  ${pushfwdir}
       chown system:system ${pushfwdir}/soc2_0_ram_mcu_3_1_hdr.bin
       chmod 666  ${pushfwdir}/soc2_0_ram_mcu_3_1_hdr.bin
    fi

    if [ -f ${saufwdir}/soc2_0_ram_bt_3_1_hdr.bin ]; then
       cp  ${saufwdir}/soc2_0_ram_bt_3_1_hdr.bin  ${pushfwdir}
       chown system:system ${pushfwdir}/soc2_0_ram_bt_3_1_hdr.bin
       chmod 666 ${pushfwdir}/soc2_0_ram_bt_3_1_hdr.bin
    fi

    if [ -f ${saufwdir}/soc2_0_ram_wifi_3_1_hdr.bin ]; then
       cp  ${saufwdir}/soc2_0_ram_wifi_3_1_hdr.bin  ${pushfwdir}
       chown system:system ${pushfwdir}/soc2_0_ram_wifi_3_1_hdr.bin
       chmod 666 ${pushfwdir}/soc2_0_ram_wifi_3_1_hdr.bin
    fi

    if [ -f ${saufwdir}/WIFI_RAM_CODE_soc2_0_3_1.bin ]; then
       cp  ${saufwdir}/WIFI_RAM_CODE_soc2_0_3_1.bin  ${pushfwdir}
       chown system:system ${pushfwdir}/WIFI_RAM_CODE_soc2_0_3_1.bin
       chmod 666 ${pushfwdir}/WIFI_RAM_CODE_soc2_0_3_1.bin
    fi

    if [ -f ${saufwdir}/soc2_0_patch_mcu_3a_1_hdr.bin ]; then
       cp  ${saufwdir}/soc2_0_patch_mcu_3a_1_hdr.bin  ${pushfwdir}
       chown system:system ${pushfwdir}/soc2_0_patch_mcu_3a_1_hdr.bin
       chmod 666  ${pushfwdir}/soc2_0_patch_mcu_3a_1_hdr.bin
    fi

    if [ -f ${saufwdir}/soc2_0_ram_mcu_3a_1_hdr.bin ]; then
       cp  ${saufwdir}/soc2_0_ram_mcu_3a_1_hdr.bin  ${pushfwdir}
       chown system:system ${pushfwdir}/soc2_0_ram_mcu_3a_1_hdr.bin
       chmod 666  ${pushfwdir}/soc2_0_ram_mcu_3a_1_hdr.bin
    fi

    if [ -f ${saufwdir}/soc2_0_ram_bt_3a_1_hdr.bin ]; then
       cp  ${saufwdir}/soc2_0_ram_bt_3a_1_hdr.bin  ${pushfwdir}
       chown system:system ${pushfwdir}/soc2_0_ram_bt_3a_1_hdr.bin
       chmod 666 ${pushfwdir}/soc2_0_ram_bt_3a_1_hdr.bin
    fi

    if [ -f ${saufwdir}/soc2_0_ram_wifi_3a_1_hdr.bin ]; then
       cp  ${saufwdir}/soc2_0_ram_wifi_3a_1_hdr.bin  ${pushfwdir}
       chown system:system ${pushfwdir}/soc2_0_ram_wifi_3a_1_hdr.bin
       chmod 666 ${pushfwdir}/soc2_0_ram_wifi_3a_1_hdr.bin
    fi

    if [ -f ${saufwdir}/WIFI_RAM_CODE_soc2_0_3a_1.bin ]; then
       cp  ${saufwdir}/WIFI_RAM_CODE_soc2_0_3a_1.bin  ${pushfwdir}
       chown system:system ${pushfwdir}/WIFI_RAM_CODE_soc2_0_3a_1.bin
       chmod 666 ${pushfwdir}/WIFI_RAM_CODE_soc2_0_3a_1.bin
    fi

    if [ -f ${saufwdir}/push.log ]; then
       cp  ${saufwdir}/push.log  ${pushfwdir}
    fi

}

function wcnfirmwareupdatedump(){

    logfwdir="/data/misc/firmware/"
    wifidir="/data/misc/wifi/"
    if [ -f ${logfwdir}/wcn_fw_update_result.conf ]; then
       cp  ${logfwdir}/wcn_fw_update_result.conf  ${wifidir}
       chown wifi:wifi ${wifidir}/wcn_fw_update_result.conf
       chmod 777  ${wifidir}/wcn_fw_update_result.conf
    fi
}

#ifdef OPLUS_DEBUG_SSLOG_CATCH
#Asiga@NETWORK.POWER 2021/03/11,add for mtk catch ss log
function logcatSsLog(){
    LOG_TYPE=`getprop persist.sys.debuglog.config`
    if [ "${LOG_TYPE}" == "call" ] || [ "${LOG_TYPE}" == "network" ] || [ "${LOG_TYPE}" == "wifi" ] || [ "${LOG_TYPE}" == "thermal" ] || [ "${LOG_TYPE}" == "power" ] || [ "${LOG_TYPE}" == "other" ]; then
        echo "logcatSsLog start"
        SSLOG_PATH=${MTK_DEBUG_PATH}/sslog
        if [[ ! -d ${SSLOG_PATH} ]];then
            mkdir -p ${SSLOG_PATH}
        fi
        LOG_RUNNING=`getprop vendor.mtklog.netlog.Running`
        while [ "${LOG_RUNNING}" == "1" ]
        do
            ss -ntp -o state established >> ${SSLOG_PATH}/sslog.txt
            sleep 15 #Sleep 15 seconds
            LOG_RUNNING=`getprop vendor.mtklog.netlog.Running`
        done
    fi
}
#endif

#ifdef OPLUS_FEATURE_WIFI_LOG
#Chuanye.Xu@OPLUS_FEATURE_WIFI_LOG, 2022/06/29 , add for collect wifi log
function captureTcpdumpLog(){
    COLLECT_LOG_PATH="${DATA_DEBUGGING_PATH}/wifi_log_temp/"
    if [ -d  ${COLLECT_LOG_PATH} ];then
        rm -rf ${COLLECT_LOG_PATH}
    fi
    if [ ! -d  ${COLLECT_LOG_PATH} ];then
        mkdir -p ${COLLECT_LOG_PATH}
        chown system:system ${COLLECT_LOG_PATH}
        chmod -R 777 ${COLLECT_LOG_PATH}
    fi
    tcpdump -i any -p -s 0 -W 4 -C 5 -w ${COLLECT_LOG_PATH}/tcpdump -Z system
}
function tcpDumpLog(){
    DATA_LOG_TCPDUMPLOG_PATH=`getprop sys.oplus.logkit.netlog`
    #limit the tcpdump size to 300M and packet size 100 byte for power log type and other log type
    traceTransferState "tcpDumpLog tcpdumpSize=${tcpdumpSize} tcpdumpCount=${tcpdumpCount} tcpdumpPacketSize=${tcpdumpPacketSize}"
    if [ "${tmpTcpdump}" != "" ]; then
        #limit the tcpdump size to 300M and packet size 100 byte for power log type and other log type
        tcpdump -i any -p -s ${tcpdumpPacketSize} -W ${tcpdumpCount} -C ${tcpdumpSize} -w ${DATA_LOG_TCPDUMPLOG_PATH}/tcpdump
    fi
}
function initLogSizeAndNums() {
    FreeSize=`df /data | grep -v Mounted | awk '{print $4}'`
    GSIZE=`echo | awk '{printf("%d",2*1024*1024)}'`
    traceTransferState "data FreeSize:${FreeSize} and GSIZE:${GSIZE}"

    tmpTcpdump=`getprop persist.sys.log.tcpdump`
    if [ "${tmpTcpdump}" != "" ]; then
        tmpTcpdumpSize=`set -f;array=(${tmpTcpdump//|/ });echo "${array[0]}"`
        tmpTcpdumpCount=`set -f;array=(${tmpTcpdump//|/ });echo "${array[1]}"`
        tcpdumpSize=`echo ${tmpTcpdumpSize} | awk '{printf("%d",$1*1024)}'`
        tcpdumpCount=`echo ${FreeSize} 10 50 ${tcpdumpSize} | awk '{printf("%d",$1*$2/$3/$4)}'`
        ##tcpdump use MB in the order
        tcpdumpSize=${tmpTcpdumpSize}
        if [ ${tcpdumpCount} -ge ${tmpTcpdumpCount} ]; then
            tcpdumpCount=${tmpTcpdumpCount}
        fi
    fi

    #LiuHaipeng@NETWORK.DATA.2959182, modify for limit the tcpdump size to 300M and packet size 100 byte for power log type and other log type
    #YangQing@CONNECTIVITY.WIFI.DCS.4219844, only limit tcpdump total size to 300M for other log, not limit packet size.
    LOG_TYPE=`getprop persist.sys.debuglog.config`
    tcpdumpPacketSize=0
    if [ "${LOG_TYPE}" != "call" ] && [ "${LOG_TYPE}" != "network" ] && [ "${LOG_TYPE}" != "wifi" ]; then
        tcpdumpSizeTotal=300
        tcpdumpCount=`echo ${tcpdumpSizeTotal} ${tcpdumpSize} 1 | awk '{printf("%d",$1/$2)}'`
    fi
}
#endif /* OPLUS_FEATURE_WIFI_LOG */

#Guotian.Wu add for wifi p2p connect fail log
function collectWifiP2pLog() {
    boot_completed=`getprop sys.boot_completed`
    while [ x${boot_completed} != x"1" ];do
        sleep 2
        boot_completed=`getprop sys.boot_completed`
    done
    wifiP2pLogPath="${DATA_DEBUGGING_PATH}/wifi_p2p_log"
    if [ ! -d  ${wifiP2pLogPath} ];then
        mkdir -p ${wifiP2pLogPath}
    fi

    dmesg > ${wifiP2pLogPath}/dmesg.txt
    /system/bin/logcat -b main -b system -f ${wifiP2pLogPath}/android.txt -r10240 -v threadtime *:V
}

function packWifiP2pFailLog() {
    wifiP2pLogPath="${DATA_DEBUGGING_PATH}/wifi_p2p_log"
    DCS_WIFI_LOG_PATH=`getprop oplus.wifip2p.connectfail`
    logReason=`getprop oplus.wifi.p2p.log.reason`
    logFid=`getprop oplus.wifi.p2p.log.fid`
    version=`getprop ro.build.version.ota`

    if [ "w${logReason}" == "w" ];then
        return
    fi

    if [ ! -d ${DCS_WIFI_LOG_PATH} ];then
        mkdir -p ${DCS_WIFI_LOG_PATH}
        chown system:system ${DCS_WIFI_LOG_PATH}
        chmod -R 777 ${DCS_WIFI_LOG_PATH}
    fi

    if [ ! -d  ${wifiP2pLogPath} ];then
        return
    fi

    tar -czvf  ${DCS_WIFI_LOG_PATH}/${logReason}.tar.gz -C ${wifiP2pLogPath} ${wifiP2pLogPath}
    abs_file=${DCS_WIFI_LOG_PATH}/${logReason}.tar.gz

    fileName="wifip2p_connect_fail@${logFid}@${version}@${logReason}.tar.gz"
    mv ${abs_file} ${DCS_WIFI_LOG_PATH}/${fileName}
    chown system:system ${DCS_WIFI_LOG_PATH}/${fileName}
    setprop sys.oplus.wifi.p2p.log.stop 0
    rm -rf ${wifiP2pLogPath}
}

#Shuangquan.du@PSW.AD.Recovery.0, 2019/07/03, add for generate runtime prop
function generate_runtime_prop() {
    getprop | sed -r 's|\[||g;s|\]||g;s|: |=|' | sed 's|ro.cold_boot_done=true||g' > /cache/runtime.prop
    chown root:root /cache/runtime.prop
    chmod 600 /cache/runtime.prop
    sync
}
#endif

#add for oidt begin
#PanZhuan@BSP.Tools, 2020/10/21, modify for way of OIDT log collection changed, please contact me for new reqirement in the future
function oidtlogs() {
    # get this prop to remove specified path
    removed_path=`getprop sys.oidt.remove_path`
    if [ "$removed_path" ];then
        traceTransferState "remove path ${removed_path}"
        rm -rf ${removed_path}
        setprop sys.oidt.remove_path ''
        return
    fi

    traceTransferState "oidtlogs start... "
    setprop sys.oidt.log_ready 0

    log_path=`getprop sys.oidt.log_path`
    if [ "$log_path" ];then
        oidt_root=${log_path}
    else
        oidt_root="BASE_PATH/oidt/"
    fi

    mkdir -p ${oidt_root}
    traceTransferState "oidt root: ${oidt_root}"

    log_config_file=`getprop sys.oidt.log_config`
    traceTransferState "log config file: ${log_config_file} "

    if [ "$log_config_file" ];then
        POWERMONITOR_BACKUP_LOG=/data/oplus/psw/powermonitor_backup/
        chmod 774 ${POWERMONITOR_BACKUP_LOG} -R

        paths=`cat ${log_config_file}`

        for file_path in ${paths};do
            # create parent directory of each path
            dest_path=${oidt_root}${file_path%/*}
            # replace dunplicate character '//' with '/' in directory
            dest_path=${dest_path//\/\//\/}
            mkdir -p ${dest_path}
            traceTransferState "copy ${file_path} "
            cp -rf ${file_path} ${dest_path}
        done

        chmod 770 ${POWERMONITOR_BACKUP_LOG} -R
        chmod -R 777 ${oidt_root}

        setprop sys.oidt.log_config ''
    fi

    setprop sys.oidt.log_ready 1
    setprop sys.oidt.log_path ''
    traceTransferState "oidtlogs end "
}
#add for oidt end

#ifdef OPLUS_BUG_DEBUG
#Miao.Yu@ANDROID.WMS, 2019/11/25, Add for dump wm info
function dumpWm() {
    panicstate=`getprop persist.sys.assert.panic`
    dumpenable=`getprop debug.screencapdump.enable`
    if [ "$panicstate" == "true" ] && [ "$dumpenable" == "true" ]
    then
        if [ ! -d ${DATA_DEBUGGING_PATH}/wm/ ];then
        mkdir -p ${DATA_DEBUGGING_PATH}/wm/
        fi

        LOGTIME=`date +%F-%H-%M-%S`
        DIR=${DATA_DEBUGGING_PATH}/wm/${LOGTIME}
        mkdir -p ${DIR}
        dumpsys window -a > ${DIR}/windows.txt
        dumpsys activity a > ${DIR}/activities.txt
        dumpsys activity -v top > ${DIR}/top_activity.txt
        dumpsys SurfaceFlinger > ${DIR}/sf.txt
        dumpsys input > ${DIR}/input.txt
        ps -A > ${DIR}/ps.txt
    fi
}
#endif /* OPLUS_BUG_DEBUG */

#zhaochengsheng@PSW.CN.WiFi.Basic.Custom.2204034, 2019/07/29
#add for Add for:solve camera interference ANT.
function iwprivswapant0(){
    iwpriv wlan0 driver 'SET_CHIP AntSwapManualCtrl 1 0'
    iwpriv wlan0 driver 'SET_CHIP AntSwapManualCtrl 0'
}

function iwprivswapant1(){
    iwpriv wlan0 driver 'SET_CHIP AntSwapManualCtrl 1 1'
}

function iwprivswitchswapant(){
    iwpriv wlan0 driver 'SET_CHIP AntSwapManualCtrl 1 0'
}

#genglin.lian@PSW.CN.WiFi.Connect.Network.2566837, 2019/9/23
#Add enable/disable interface for SmartGear
function disableSmartGear() {
    iwpriv wlan0 driver 'set_chip SmartGear 9 0'
}

function enableSmartGear() {
    iwpriv wlan0 driver 'set_chip SmartGear 9 1'
}

#Junhao.Liang 2020/01/02, Add for OTA to catch log
function resetlogfirstbootbuffer() {
    echo "resetlogfirstbootbuffer start"
    setprop sys.tranfer.finished "resetlogfirstbootbuffer start"
    enable=`getprop persist.sys.assert.panic`
    argfalse='false'
    if [ "${enable}" = "${argfalse}" ]; then
    /system/bin/logcat -G 256K
    fi
    echo "resetlogfirstbootbuffer end"
    setprop sys.tranfer.finished "resetlogfirstbootbuffer end"
}

function logfirstbootmain() {
    echo "logfirstbootmain begin"
    setprop sys.tranfer.finished "logfirstbootmain begin"
    path=${MTK_DEBUG_PATH}/firstboot
    mkdir -p ${path}
    /system/bin/logcat -G 5M
    /system/bin/logcat  -f ${path}/android.txt -r10240 -v threadtime *:V
    setprop sys.tranfer.finished "logfirstbootmain end"
    echo "logfirstbootmain end"
}

function logfirstbootevent() {
    echo "logfirstbootevent begin"
    setprop sys.tranfer.finished "logfirstbootevent begin"
    path=${MTK_DEBUG_PATH}/firstboot
    mkdir -p ${path}
    /system/bin/logcat -b events -f ${path}/event.txt -r10240 -v threadtime *:V
    setprop sys.tranfer.finished "logfirstbootevent end"
    echo "logfirstbootevent end"
}

function logfirstbootkernel() {
    echo "logfirstbootkernel begin"
    setprop sys.tranfer.finished "logfirstbootkernel begin"
    path=${MTK_DEBUG_PATH}/firstboot
    mkdir -p ${path}
    dmesg > ${path}/kinfo_boot.txt
    setprop sys.tranfer.finished "logfirstbootkernel end"
    echo "logfirstbootkernel end"
}

function chmodDcsEnPath() {
    DCS_EN_PATH=${DATA_OPLUS_LOG_PATH}/DCS/en
    chmod 777 -R ${DCS_EN_PATH}
}

function logcusmain() {
    echo "logcusmain begin"
    path=${DATA_OPLUS_LOG_PATH}/temp
    mkdir -p ${path}
    chown -R system:system ${path}
    chmod 755 -R ${path}
    /system/bin/logcat  -f ${path}/android.txt -r10240 -v threadtime *:V
    echo "logcusmain end"
}

function logcusevent() {
    echo "logcusevent begin"
    path=${DATA_OPLUS_LOG_PATH}/temp
    mkdir -p ${path}
    chown -R system:system ${path}
    chmod 755 -R ${path}
    /system/bin/logcat -b events -f ${path}/event.txt -r10240 -v threadtime *:V
    echo "logcusevent end"
}

function logcusradio() {
    echo "logcusradio begin"
    path=${DATA_OPLUS_LOG_PATH}/temp
    mkdir -p ${path}
    chown -R system:system ${path}
    chmod 755 -R ${path}
    /system/bin/logcat -b radio -f ${path}/radio.txt -r10240 -v threadtime *:V
    echo "logcusradio end"
}

function logcuskernel() {
    echo "logcuskernel begin"
    path=${DATA_OPLUS_LOG_PATH}/temp
    mkdir -p ${path}
    chown -R system:system ${path}
    chmod 755 -R ${path}
    dmesg > ${path}/dmesg.txt
    echo "logcuskernel end"
}

#ifdef VENDOR_EDIT
#Hailong.Liu@ANDROID.MM, 2020/03/18, add for capture native malloc leak on aging_monkey test
function storeSvelteLog() {
    local dest_dir="/data/oplus/heapdump/svelte/"
    local log_file="${dest_dir}/svelte_log.txt"
    local log_dev="/dev/svelte_log"
    local err_file="${DATA_DEBUGGING_PATH}/svelte_err.txt"

    if [ ! -c ${log_dev} ]; then
        echo "svelte ${log_dev} does not exist." >> ${err_file}
        return 1
    fi

    if [ ! -d ${dest_dir} ]; then
        mkdir -p ${dest_dir}
        if [ "$?" -ne "0" ]; then
            echo "svelte mkdir failed." >> ${err_file}
            return 1
        fi
        chmod 0777 ${dest_dir}
    fi

    if [ ! -f ${log_file} ]; then
        echo --------Start `date` >> ${log_file}
        if [ "$?" -ne "0" ]; then
            echo "svelte create file failed." >> ${err_file}
            return 1
        fi
        chmod 0777 ${log_file}
    fi

    while true
    do
        echo --------`date` >> ${log_file}
        /system_ext/bin/svelte logger >> ${log_file}
    done
}
#endif

#ifdef OPLUS_BUG_STABILITY
#Tian.Pan@ANDROID.STABILITY.3054721.2020/08/31.add for fix debug system_server register too many receivers issue
function receiverinfocapture() {
    alreadycaped=`getprop sys.debug.receiverinfocapture`
    if [ "$alreadycaped" == "1" ] ;then
        return
    fi

    uuid=`cat /proc/sys/kernel/random/uuid`
    version=`getprop ro.build.version.ota`
    logtime=`date +%F-%H-%M-%S`
    logpath="${DATA_OPLUS_LOG_PATH}/DCS/de/stability_monitor"
    if [ ! -d "${logpath}" ]; then
        mkdir ${logpath}
        chown system:system ${logpath}
        chmod 777 ${logpath}
    fi
    filename="${logpath}/stability_receiversinfo@${uuid}@${version}@${logtime}.txt"
    dumpsys -t 60 activity broadcasts > ${filename}
    chown system:system ${filename}
    chmod 0666 ${filename}
    setprop sys.debug.receiverinfocapture 1
}
#endif /*OPLUS_BUG_STABILITY*/

#ifdef OPLUS_BUG_STABILITY
#Jason.Yu@ANDROID.STABILITY.3502573.2022/04/15.add for catch ps and binder infos when SWT happened
function catch_ps_binder_infos() {
    LOGTIME=`date +%F-%H-%M-%S`
    PS_BINDER_INFOS_DIR=${DATA_OPLUS_LOG_PATH}/DCS/de/ps_binder_infos/${LOGTIME}

    echo ${PS_BINDER_INFOS_DIR}
    if [ ! -d "${PS_BINDER_INFOS_DIR}" ]; then
        mkdir -p ${PS_BINDER_INFOS_DIR}
        chown system:system ${PS_BINDER_INFOS_DIR}
        chmod 777 ${PS_BINDER_INFOS_DIR}
    fi
    ps -A -T > ${PS_BINDER_INFOS_DIR}/ps_AT.txt
    cat /dev/binderfs/binder_logs/state > ${PS_BINDER_INFOS_DIR}/binder_info.txt

    wait
}
#endif /*OPLUS_BUG_STABILITY*/

case "$config" in
# Add for SurfaceFlinger Layer dump
    "layerdump")
        layerdump
        ;;
#Shuangquan.du@PSW.AD.Recovery.0, 2019/07/03, add for generate runtime prop
    "generate_runtime_prop")
        generate_runtime_prop
        ;;
#endif
#Xuefeng.Peng@PSW.AD.Performance.Storage.1721598, 2018/12/26, Add for abnormal sd card shutdown long time
    "exstorage_support")
        exstorage_support
        ;;
    "gettpinfo")
        gettpinfo
    ;;
    "inittpdebug")
        inittpdebug
    ;;
    "settplevel")
        settplevel
    ;;
#Deliang.Peng, 2017/7/7,add for native watchdog
    "nativedump")
        nativedump
    ;;
#Jianping.Zheng 2017/04/04, Add for record performance
        "perf_record")
        perf_record
    ;;
    #Fei.Mo, 2017/09/01 ,Add for power monitor top info
    "thermal_top")
        thermalTop
    #end, Add for power monitor top info
    ;;
    "cleardatadebuglog")
        clearDataDebugLog
    ;;
#Linjie.Xu@PSW.AD.Power.PowerMonitor.1104067, 2018/01/17, Add for OplusPowerMonitor get dmesg at O
        "kernelcacheforopm")
        kernelcacheforopm
    ;;
#Jianfa.Chen@PSW.AD.PowerMonitor,add for powermonitor getting Xlog
        "catchWXlogForOpm")
        catchWXlogForOpm
    ;;
        "catchQQlogForOpm")
        catchQQlogForOpm
    ;;
# Qiurun.Zhou@ANDROID.DEBUG, 2022/6/17, copy wxlog for EAP
        "eapCopyWXlog")
        eapCopyWXlog
    ;;
#endif /* THIRD_PART_LOG_FOR_OPM */
        "psforopm")
        psforopm
    ;;
        "tranferPowerRelated")
        tranferPowerRelated
    ;;
        "startSsLogPower")
        startSsLogPower
    ;;
        "logcatMainCacheForOpm")
        logcatMainCacheForOpm
    ;;
        "logcatEventCacheForOpm")
        logcatEventCacheForOpm
    ;;
        "logcatRadioCacheForOpm")
        logcatRadioCacheForOpm
    ;;
        "catchBinderInfoForOpm")
        catchBinderInfoForOpm
    ;;
        "catchBattertFccForOpm")
        catchBattertFccForOpm
    ;;
        "catchTopInfoForOpm")
        catchTopInfoForOpm
    ;;
          "dumpsysHansHistoryForOpm")
        dumpsysHansHistoryForOpm
    ;;
        "getPropForOpm")
        getPropForOpm
    ;;
        "dumpsysSurfaceFlingerForOpm")
        dumpsysSurfaceFlingerForOpm
    ;;
        "dumpsysSensorserviceForOpm")
        dumpsysSensorserviceForOpm
    ;;
        "dumpsysBatterystatsForOpm")
        dumpsysBatterystatsForOpm
    ;;
        "dumpsysBatterystatsOplusCheckinForOpm")
        dumpsysBatterystatsOplusCheckinForOpm
    ;;
        "dumpsysBatterystatsCheckinForOpm")
        dumpsysBatterystatsCheckinForOpm
    ;;
        "dumpsysMediaForOpm")
        dumpsysMediaForOpm
    ;;
        "logcusMainForOpm")
        logcusMainForOpm
    ;;
        "logcusEventForOpm")
        logcusEventForOpm
    ;;
        "logcusRadioForOpm")
        logcusRadioForOpm
    ;;
        "logcusKernelForOpm")
        logcusKernelForOpm
    ;;
        "logcusTCPForOpm")
        logcusTCPForOpm
    ;;
        "customDiaglogForOpm")
        customDiaglogForOpm
    ;;
        "clearMtkDebuglogger")
        clearMtkDebuglogger
    ;;
    "screen_record_backup")
        screen_record_backup
        ;;
    "pwkdumpon")
        pwkdumpon
        ;;
    "pwkdumpoff")
        pwkdumpoff
        ;;
    "mrdumpon")
        mrdumpon
        ;;
    "mrdumpoff")
        mrdumpoff
        ;;
    "transfermtklog")
        transferMtkLog
        ;;
#Miao.Yu@ANDROID.WMS, 2019/11/25, Add for dump wm info
    "dumpWm")
        dumpWm
        ;;
    "psinfo")
        psInfo
        ;;
    "topinfo")
        topInfo
        ;;
    "servicelistinfo")
        serviceListInfo
        ;;
    "dumpsysinfo")
        dumpsysInfo
        ;;
    "dumpstate")
        dumpStateInfo
        ;;
    "dumpstorageinfo")
        dumpStorageInfo
        ;;
        "mvrecoverylog")
        mvrecoverylog
    ;;
        "logcusmain")
        logcusmain
    ;;
        "logcusevent")
        logcusevent
    ;;
        "logcusradio")
        logcusradio
    ;;
        "logcuskernel")
        logcuskernel
    ;;
        "customdmesg")
        customdmesg
    ;;
        "checkAeeLogs")
        checkAeeLogs
    ;;
        "dumpenvironment")
        DumpEnvironment
    ;;
        "slabinfoforhealth")
        slabinfoforhealth
    ;;
        "svelteforhealth")
        svelteforhealth
    ;;
        "meminfoforhealth")
        meminfoforhealth
    ;;
        "dmaprocsforhealth")
        dmaprocsforhealth
    ;;
    #ifdef OPLUS_FEATURE_EAP
    #Haifei.Liu@ANDROID.RESCONTROL, 2020/08/18, Add for copy binder_info
    "copyEapBinderInfo")
        copyEapBinderInfo
    ;;
    #endif /* OPLUS_FEATURE_EAP */
    # ifdef OPLUS_FEATURE_THEIA
    # Yangkai.Yu@ANDROID.STABILITY, Add hook for TheiaBinderBlock
    "copyTheiaBinderInfo")
        copyTheiaBinderInfo
    ;;
    # endif /*OPLUS_FEATURE_THEIA*/
#Xiaomin.Yang@PSW.CN.BT.Basic.Customize.1586031,2018/12/02, Add for updating wcn firmware by sau
    "wcnfirmwareupdate")
        wcnfirmwareupdate
        ;;
    "wcnfirmwareupdatedump")
        wcnfirmwareupdatedump
        ;;
# Kun.Hu@PSW.TECH.RELIABILTY, 2019/1/3, fix the core domain limits to search /mnt/vendor/oplusreserve
        "remount_oplusreserve2")
        remount_oplusreserve2
    ;;
#ifdef OPLUS_FEATURE_SHUTDOWN_DETECT
        "remount_oplusreserve2_shutdown")
        remount_oplusreserve2_shutdown
    ;;
#endif
    "cleanpcmdump")
        cleanpcmdump
    ;;
    "oidtlogs")
        oidtlogs
    ;;
#zhaochengsheng@PSW.CN.WiFi.Basic.Custom.2204034, 2019/07/29
#add for Add for:solve camera interference ANT.
    "iwprivswapant0")
        iwprivswapant0
    ;;
    "iwprivswapant1")
        iwprivswapant1
    ;;
    "iwprivswitchswapant")
        iwprivswitchswapant
    ;;

#genglin.lian@PSW.CN.WiFi.Connect.Network.23456788, 2019/9/23
#Add enable/disable interface for SmartGear
    "disableSmartGear")
        disableSmartGear
    ;;
    "enableSmartGear")
        enableSmartGear
    ;;
#add for firstboot log
        "resetlogfirstbootbuffer")
        resetlogfirstbootbuffer
    ;;
        "logfirstbootmain")
        logfirstbootmain
    ;;
        "logfirstbootevent")
        logfirstbootevent
    ;;
        "logfirstbootkernel")
        logfirstbootkernel
    ;;
	"transferUser")
        transferUser
    ;;
	"dump_system")
        getSystemStatus
    ;;
    "transfer_data_vendor")
        transferDataVendor
    ;;
    "transfer_anrtomb")
        transferAnrTomb
    ;;
    "testtransfersystem")
        testTransferSystem
    ;;
	"testtransferroot")
        testTransferRoot
    ;;
#ifdef OPLUS_DEBUG_SSLOG_CATCH
#Asiga@NETWORK.POWER 2021/03/11,add for mtk catch ss log
        "logcatSsLog")
        logcatSsLog
    ;;
#endif
#ifdef OPLUS_FEATURE_MEMLEAK_DETECT
        "storeSvelteLog")
        storeSvelteLog
    ;;
#endif /* OPLUS_FEATURE_MEMLEAK_DETECT */
    "chmoddcsenpath")
        chmodDcsEnPath
    ;;
    "backup_minidumplog")
        backupMinidump
    ;;
#ifdef OPLUS_FEATURE_WIFI_LOG
#Chuanye.Xu@OPLUS_FEATURE_WIFI_LOG, 2022/06/29 , add for collect wifi log
        "captureTcpdumpLog")
        captureTcpdumpLog
    ;;
    "tcpdumplog")
        initLogSizeAndNums
        tcpDumpLog
    ;;
#endif /* OPLUS_FEATURE_WIFI_LOG */
#ifdef OPLUS_BUG_STABILITY
#Tian.Pan@ANDROID.STABILITY.3054721.2020/08/31.add for fix debug system_server register too many receivers issue.
    "receiverinfocapture")
        receiverinfocapture
        ;;
#endif /*OPLUS_BUG_STABILITY*/

#ifdef OPLUS_BUG_STABILITY
#Jason.Yu@ANDROID.STABILITY.3502573.2022/04/15.add for catch ps and binder infos when SWT happened
    "catch_ps_binder_infos")
        catch_ps_binder_infos
        ;;
#endif /*OPLUS_BUG_STABILITY*/

       *)

      ;;
esac
