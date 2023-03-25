#!/system/bin/sh

config="$1"
para="$2"

function doSwitchEng {
    setprop persist.sys.allcommode true
    setprop persist.sys.oplus.usbactive true
    setprop persist.sys.adb.engineermode 0
    is_mtk=`getprop ro.vendor.mediatek.platform`
    if [[ ${is_mtk} ]] ; then
        atm_mode=`getprop sys.boot.atm`
        if [[ ${atm_mode} != "enable" ]]; then
            setprop sys.usb.config adb
            setprop vendor.oplus.engineer.usb.config adb
        fi
     else
        setprop sys.usb.config diag,adb
        setprop vendor.oplus.engineer.usb.config diag,adb
    fi
}

function doAccessCpuInfo {
    chmod 0444 /sys/devices/system/cpu/cpu0/cpufreq/cpuinfo_cur_freq
    chmod 0444 /sys/devices/system/cpu/cpu1/cpufreq/cpuinfo_cur_freq
    chmod 0444 /sys/devices/system/cpu/cpu2/cpufreq/cpuinfo_cur_freq
    chmod 0444 /sys/devices/system/cpu/cpu3/cpufreq/cpuinfo_cur_freq
    chmod 0444 /sys/devices/system/cpu/cpu4/cpufreq/cpuinfo_cur_freq
    chmod 0444 /sys/devices/system/cpu/cpu5/cpufreq/cpuinfo_cur_freq
    chmod 0444 /sys/devices/system/cpu/cpu6/cpufreq/cpuinfo_cur_freq
    chmod 0444 /sys/devices/system/cpu/cpu7/cpufreq/cpuinfo_cur_freq
    chmod 0444 /sys/devices/system/cpu/cpufreq/policy0/cpuinfo_cur_freq
    chmod 0444 /sys/devices/system/cpu/cpufreq/policy4/cpuinfo_cur_freq
    chmod 0444 /sys/devices/system/cpu/cpufreq/policy7/cpuinfo_cur_freq
    chmod 0666 /sys/devices/system/cpu/cpufreq/policy0/scaling_governor
    chmod 0666 /sys/devices/system/cpu/cpufreq/policy4/scaling_governor
    chmod 0666 /sys/devices/system/cpu/cpufreq/policy7/scaling_governor
}

case "$config" in
    "switchEng")
    doSwitchEng
    ;;
    "accessCpuInfo")
    doAccessCpuInfo
    ;;
esac
