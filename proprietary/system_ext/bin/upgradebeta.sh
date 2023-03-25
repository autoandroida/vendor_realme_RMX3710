#! /system/bin/sh

config="$1"
function initupgradebeta()
{
    ## 非ab "/cache/recovery/intent"
    ##非ab 是recovery 阶段 /cache/recovery/intent
    ##ab boot 阶段 /cache/recovery/intent
    ##recovery 非vab 在线场景 0 是成功 1 失败 ；本地场景 2 是成功，3是失败
    ##vab /cache/recovery/intent  软链接 /data/cache
    ##VAB：0是成功，1是失败
    ##     升级前            recovery               boot                        android init
    ##|***************|**********************|*************************|**************************|
    ##
    log -p d -t Debuglog ${config};
    versiontype=`getprop ro.oplusupgrade.alpha.version`
    otaversion=`getprop ro.build.version.ota`
    target_version=`getprop persist.sys.oplusupgrade.version_type|awk -F : '{print $1}' ||true`
    ota_usertype=`getprop persist.sys.oplusupgrade.version_type|awk -F : '{print $2}' ||true`
    currentusertype=`getprop persist.sys.oplusupgrade.user.type  ||true`
    historyusertype=`getprop persist.sys.oplusupgrade.oplusreserve  ||true`
    otastatefile="/cache/recovery/intent"
    factoryresetstate=`getprop oplus.device.firstboot ||true`

    prebuildusertype=`getprop ro.oplusupgrade.user.type`

    ##if no upgrade.alpha ota or upgrade case,do nothing
    if [ x"$versiontype" = x"" ] ;then
        return
    fi
    log -p d -t Debuglog "otastatefile_"$otastatefile
    if [ -f ${otastatefile} ]; then
       otastate=$(cat ${otastatefile})
       log -p d -t Debuglog "otastate111_"$otastate
    elif [ "${factoryresetstate}" == "1" ]; then
       log -p d -t Debuglog "factoryresetstate_"$factoryresetstate
    else
        return
    fi
    #c1 if ota server info && cache info cannot get  && current && prebuild upgrade do nothing
    if [[ x"${ota_usertype}" = x"" ]]  && [[ x"${historyusertype}" = x"" ]] && [[ x"${currentusertype}" = x"" ]] && [[ x"${prebuildusertype}" = x"" ]]; then
        return
    fi

    ##init default usertype first chose prebuild ;
    if [ x"${prebuildusertype}" != x"" ];then
        usertype=${prebuildusertype}
        log -p d -t Debuglog "prebuildusertype"${usertype}
    fi
    if [ x"${historyusertype}" != x"" ]; then
        usertype=${historyusertype}
        log -p d -t Debuglog "historyusertype"${usertype}
    fi

    ##c1: ota server info and cache info exist;ota success
    if [[ x"${otastate}" = x"0" ]] || [[ x"${otastate}" = x"2" ]] ; then
      if [ x"$otaversion" == x"$target_version" ]; then
          log -p d -t Debuglog "otastate:"${ota_usertype}
          usertype=${ota_usertype}
      fi
    fi
    setprop persist.sys.oplusupgrade.user.type ${usertype}

    if [ "$usertype" == "5" ] || [ "$usertype" == "6" ]; then
        setprop persist.sys.alwayson.enable true
        setprop persist.vendor.ssr.enable_ramdumps 1
        setprop persist.sys.enable_wcnss_dump 1
    else
        setprop persist.sys.alwayson.enable false
        setprop persist.vendor.ssr.enable_ramdumps 0
        setprop persist.sys.enable_wcnss_dump 0
    fi
}

function resetusertype()
{
    versiontype=`getprop ro.oplusupgrade.alpha.version ||true`
    if [ x"$versiontype" = x"" ] ;then
        sys_alwayson=`getprop persist.sys.alwayson.enable ||true`
        vendor_enable_ramdumps=`getprop persist.vendor.ssr.enable_ramdumps ||true`
        sys_enable_wcnss_dump=`getprop persist.sys.enable_wcnss_dump ||true`
        sys_oplusreserve=`getprop persist.sys.oplusupgrade.oplusreserve ||true`

        setprop persist.sys.oplusupgrade.user.type ""
        if [ x"${sys_alwayson}" != x"" ]; then
            setprop persist.sys.alwayson.enable false
        fi
        if [ x"${vendor_enable_ramdumps}" != x"" ]; then
            setprop persist.vendor.ssr.enable_ramdumps 0
        fi
        if [ x"${sys_enable_wcnss_dump}" != x"" ]; then
            setprop persist.sys.enable_wcnss_dump 0
        fi
        if [ x"${sys_oplusreserve}" != x"" ]; then
            setprop persist.sys.oplusupgrade.oplusreserve ""
        fi
    fi
}

case "$config" in
    "initupgradebeta")
        initupgradebeta
        ;;
    "resetusertype")
        resetusertype
        ;;
    *)
        ;;
esac
