#! /vendor/bin/sh

config="$1"

function lowram_device_setup()
{
    MemTotalStr=`cat /proc/meminfo | grep MemTotal`
    MemTotal=${MemTotalStr:16:8}

    Heapminfree=2m
    Heapmaxfree=16m
    Heapstartsize=16m
    Heapsize=512m
    Heapgrowthlimit=384m

    if [ $MemTotal -lt 6291456 ]; then
       Heapminfree=512k
       Heapmaxfree=8m
       Heapstartsize=8m
       Heapsize=512m
    fi

    if [ $MemTotal -lt 4194430 ]; then
       Heapminfree=512k
       Heapmaxfree=8m
       Heapstartsize=8m
       Heapsize=512m
       setprop ro.vendor.config.oplus.low_ram true
    fi

    if [ $MemTotal -lt 3145728 ]; then
       Heapminfree=512k
       Heapmaxfree=8m
       Heapstartsize=4m
       Heapsize=512m
       Heapgrowthlimit=192m
    fi

    setprop vendor.oplus.dalvik.vm.heapminfree $Heapminfree
    setprop vendor.oplus.dalvik.vm.heapmaxfree $Heapmaxfree
    setprop vendor.oplus.dalvik.vm.heapstartsize $Heapstartsize
    setprop vendor.oplus.dalvik.vm.heapsize $Heapsize
    setprop vendor.oplus.dalvik.vm.heapgrowthlimit $Heapgrowthlimit
    setprop ro.vendor.config.oplus.low_ram false
}

case "$config" in
    "lowram_device_setup")
        lowram_device_setup
    ;;
       *)

      ;;
esac
