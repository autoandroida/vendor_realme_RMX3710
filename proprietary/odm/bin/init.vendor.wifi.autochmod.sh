#!/vendor/bin/sh
#***********************************************************
#** Copyright (C), 2019-2029, OPLUS Mobile Comm Corp., Ltd
#** All rights reserved.
#**
#** File: - vendor.wifi.autochmod.sh
#** Description: vendor domain operation
#**
#** Version: 1.1
#** Date : 2020/02/20
#** Author: JiaoBo
#** TAG: CONNECTIVITY.WIFI.BASIC.HARDWARE
#** ---------------------Revision History: ---------------------
#**  <author>    <data>       <version >       <desc>
#**  Jiao.Bo       2020/02/20     1.0     build this module
#****************************************************************/

config="$1"


#ifdef OPLUS_FEATURE_WIFI_RUSUPGRADE
#JiaoBo@CONNECTIVITY.WIFI.BASIC.HARDWARE.2795386, 2020/02/20
#add for: support auto update function, include mtk fw, mtk wifi.cfg, qcom fw, qcom bdf, qcom ini
#common info
defaultVersion="20190101000000"
nullVersion="null"
rusEntityConfigXmlfile=/odm/etc/vendor_wifi_rus_config.xml
isConfigXmlParseDone="false"
#mtk platform info
mtkWifirusEntityVersionList="null;null;null;null;null"
mtkWifirusEntityTypeList=("wifi.cfg" "wifi.fw" "wifi.nv")
mtkWifirusEntityVersionFileNameList=(
"wifi.cfg"
"WIFI_RAM_CODE_soc2_0_3a_1.bin"
"WIFI")
mtkWifirusEntityFileNameList=(
"wifi.cfg"
"WIFI_RAM_CODE_soc2_0_3a_1.bin;soc2_0_ram_wifi_3a_1_hdr.bin;soc2_0_ram_bt_3a_1_hdr.bin;soc2_0_ram_mcu_3a_1_hdr.bin;soc2_0_patch_mcu_3a_1_hdr.bin"
"WIFI")
mtkWifirusEntityVendorPathList=(
"/vendor/firmware/"
"/vendor/firmware/"
"/vendor/firmware/")
#qcom paltform info
qcomWifirusEntityVersionList="null;null;null"
qcomWifirusEntityTypeList=("wifi.ini" "wifi.fw" "wifi.bdf")
qcomWifirusEntityVersionFileNameList=(
"WCNSS_qcom_cfg.ini"
"wlandsp.mbn"
"bin_version")
qcomWifirusEntityFileNameList=(
"WCNSS_qcom_cfg.ini"
"wlandsp.mbn"
"bin_version;bdwlan.bin")
qcomWifirusEntityVendorPathList=(
"/vendor/firmware_mnt/"
"/vendor/firmware_mnt/"
"/vendor/firmware_mnt/")

#function: get the entity type index
function getrusEntityTypeIdx() {
    local platform=$1
    local type=$2
    if [ "$platform" = "mtk" ]; then
        if [ "$type" = "wifi.cfg" ]; then
            return 0
        elif [ "$type" = "wifi.fw" ]; then
            return 1
        elif [ "$type" = "wifi.nv" ]; then
            return 2
        fi
    elif [ "$platform" = "qcom" ]; then
        if [ "$type" = "wifi.ini" ]; then
            return 0
        elif [ "$type" = "wifi.fw" ]; then
            return 1
        elif [ "$type" = "wifi.bdf" ]; then
            return 2
        fi
    fi
    return 0
}

#function: get the vendor suppprt Entity file name which include version information
function parseSupportrusEntityConfigXml() {
    local board=`getprop ro.board.platform`
    if [ "$isConfigXmlParseDone" = "false" ]; then
        local cmd=$(cat $rusEntityConfigXmlfile | awk -F '[ =]' '{if (NF == 13) {printf("%s==%s==%s==%s==", $7, $9, $11, $13)}}' | sed -e 's/\/>//g' -e 's/"//g')
        execute=(${cmd//==/ })
        local length=${#execute[*]}
        local i=0
        while [ i -lt length ]
        do
            local platform=${execute[i]}
            local type=${execute[++i]}
            local versionFileName=${execute[++i]}
            local fileNameList=${execute[++i]}
            local typeIdx
            if [[ $board == *"mt"* ]] || [[ $board == *"Mt"*  ]] || [[ $board == *"MT"*  ]];then
                getrusEntityTypeIdx "mtk" $type
                typeIdx=$?
                if [ "$platform" = "$board" ]; then
                    mtkWifirusEntityVersionFileNameList[typeIdx]=$versionFileName
                    mtkWifirusEntityFileNameList[typeIdx]=$fileNameList
                    echo "index=$i Entity$typeIdx: platform:$platform type:$type"
                    echo "         versionFileName:${mtkWifirusEntityVersionFileNameList[typeIdx]}"
                    echo "         fileNameList:${mtkWifirusEntityFileNameList[typeIdx]}"
                fi
            else
                getrusEntityTypeIdx "qcom" $type
                typeIdx=$?
                if [ "$platform" = "$board" ]; then
                    qcomWifirusEntityVersionFileNameList[typeIdx]=$versionFileName
                    qcomWifirusEntityFileNameList[typeIdx]=$fileNameList
                    echo "index=$i Entity$typeIdx: platform:$platform type:$type"
                    echo "         versionFileName:${qcomWifirusEntityVersionFileNameList[typeIdx]}"
                    echo "         fileNameList:${qcomWifirusEntityFileNameList[typeIdx]}"
                fi
            fi
            i=$((i+1))
        done
        isConfigXmlParseDone="true"
    else
        echo "already parse done."
    fi
}

#function: get all vendor suppprt Entity version for mtk
function rusMtkWifiObjsVendorVerGet() {
    parseSupportrusEntityConfigXml
    mtkWifirusEntityVersionList=""
    local length=${#mtkWifirusEntityTypeList[@]}
    local i=0
    while [ i -lt length ]
    do
        local type=${mtkWifirusEntityTypeList[i]}
        local file=${mtkWifirusEntityVendorPathList[i]}${mtkWifirusEntityVersionFileNameList[i]}
        if [ -f $file ]; then
            if [ "$type" = "wifi.cfg" ]; then
                str=`head -c 25 $file`
                version=${str:9:14}
            elif [ "$type" = "wifi.fw" ]; then
                str=`tail -c 19 $file`
                version=${str:0:14}
            elif [ "$type" = "wifi.nv" ]; then
                #default not support update this entity
                version=$nullVersion
            else
                version=$nullVersion
            fi
        else
            version=$nullVersion
        fi
        mtkWifirusEntityVersionList+=$version";"
        i=$((i+1))
    done
    mtkWifirusEntityVersionList=${mtkWifirusEntityVersionList%;*}
    echo "mtkWifirusEntityVersionList=$mtkWifirusEntityVersionList"
}

#function: get all vendor suppprt Entity version for qcom
function rusQcomWifiObjsVendorVerGet() {
    parseSupportrusEntityConfigXml
    qcomWifirusEntityVersionList=""
    local length=${#qcomWifirusEntityTypeList[@]}
    local i=0
    while [ i -lt length ]
    do
        local type=${qcomWifirusEntityTypeList[i]}
        local file=${qcomWifirusEntityVendorPathList[i]}${qcomWifirusEntityVersionFileNameList[i]}
        if [ -f $file ]; then
            if [ "$type" = "wifi.ini" ]; then
                #default not support update this entity
                version=$nullVersion
            elif [ "$type" = "wifi.fw" ]; then
                #default not support update this entity
                version=$nullVersion
            elif [ "$type" = "wifi.bdf" ]; then
                #default not support update this entity
                version=$nullVersion
            else
                version=$nullVersion
            fi
        else
            version=$nullVersion
        fi
        qcomWifirusEntityVersionList+=$version";"
        i=$((i+1))
    done
    qcomWifirusEntityVersionList=${qcomWifirusEntityVersionList%;*}
    echo "qcomWifirusEntityVersionList=$qcomWifirusEntityVersionList"
}

#function: set the versionlist to attribute when bootup
function rusWifiVendorVerBootCheck() {
    local platform
    local board=`getprop ro.board.platform`
    if [[ $board == *"mt"* ]] || [[ $board == *"Mt"*  ]] || [[ $board == *"MT"*  ]];then
        platform="mtk"
    else
        platform="qcom"
    fi

    if [ "$platform" = "mtk" ]; then
        rusMtkWifiObjsVendorVerGet
        setprop vendor.oplus.wifi.rus.version $mtkWifirusEntityVersionList
    elif [ "$platform" = "qcom" ]; then
        rusQcomWifiObjsVendorVerGet
        setprop vendor.oplus.wifi.rus.version $qcomWifirusEntityVersionList
    fi
    setprop vendor.oplus.wifi.rus.upgrade.ctl "vendor-bootcheck-done"
}

#function: set the versionlist to attribute when rus upgrade
function rusWifiVendorVerUpgradeCheck() {
    local platform
    local board=`getprop ro.board.platform`
    if [[ $board == *"mt"* ]] || [[ $board == *"Mt"*  ]] || [[ $board == *"MT"*  ]];then
        platform="mtk"
    else
        platform="qcom"
    fi
    echo "rusWifiVendorVerUpgradeCheck platform=$platform"

    if [ "$platform" = "mtk" ]; then
        rusMtkWifiObjsVendorVerGet
        setprop vendor.oplus.wifi.rus.version $mtkWifirusEntityVersionList
    elif [ "$platform" = "qcom" ]; then
        rusQcomWifiObjsVendorVerGet
        setprop vendor.oplus.wifi.rus.version $qcomWifirusEntityVersionList
    fi
    setprop vendor.oplus.wifi.rus.upgrade.ctl "vendor-upgradeCheck-done"
}
#endif /* OPLUS_FEATURE_WIFI_RUSUPGRADE */

#ifdef OPLUS_FEATURE_WIFI_DUMP
#JiaoBo@CONNECTIVITY.WIFI.BASIC.LOG.1162003, 2018/7/02
#add for wifi dump related log collection and DCS handle, dynamic enable/disable wifi core dump, offer trigger wifi dump API.
QCOM_DUMP_PATH="/data/vendor/tombstones/rfs/modem/*"
QCOM_KONA_DUMP_PATH="/data/vendor/ramdump/ramdump_wlan*"
MTK_DUMP_PATH="/data/vendor/connsyslog/wifi/*"
function clearWifiDumpFile() {
    local platform=`getprop ro.board.platform`
    if [[ $platform == *"mt"* ]] || [[ $platform == *"Mt"*  ]] || [[ $platform == *"MT"*  ]];then
        rm -rf $MTK_DUMP_PATH
    else
        if [ "x${platform}" == "xkona" ];then
            rm -rf $QCOM_KONA_DUMP_PATH
        else
            rm -rf $QCOM_DUMP_PATH
        fi
    fi
}
#endif /* OPLUS_FEATURE_WIFI_DUMP */

#ifdef OPLUS_FEATURE_WIFI_SAR
#Shanbolun@CONNECTIVITY.WIFI.BASIC.HARDWARE.337348, 2020/9/17
#add property to trigger wifisar command
COMMON_SAR_PATH="/odm/etc/wifi/wifisar.cfg"

function getSarMappedIndex() {
	fwkIdx="$1"
	pwrIdx="$1"
	mapFile="/odm/etc/wifi/wifisar.map"

	if [ -f "$mapFile" ]; then
		pwrIdx=$(cat "$mapFile" | awk -F ":" '{
		if ($1 == "'$fwkIdx'") {
			print $2
		}}')

		# if no index matched, force set index to 1 and use default power
		if [ -z "$pwrIdx" ]; then
			pwrIdx="1"
		fi
	fi

	echo "$pwrIdx"
}

#LiFenfen@CONNECTIVITY.WIFI.HARDWARE.SAR.2900034, 2022/03/21
#add for project sar flag, projectBit keyword in wifisar.cfg, such as projectBit=100011, it focus on bit0,4,5
#sourcesar is framework sarbit, projectsar is customized sar support, the result is "sourcesar"&"projectsar"
function transferSarIndex() {
local sourcesar=$1
local projectsar=$2
local replace=0
local len=${#projectsar}
local i=0                  #projectBit start from left
local j=${#sourcesar}-$len #align with projectBit
local str=""               #destination bit

while [ ${i} -lt ${len} ]
do
    pbit=${projectsar:${i}:1}
    sbit=${sourcesar:${j}:1}

    #if pbit[i] is 0, set str[i] 0, this project doesn't care this scene bit.
    if [ "${pbit}" == "${replace}" ]; then
        str=${str}${pbit}
    else
        str=${str}${sbit}
    fi
let i++
let j++
done

 echo $str
}

#LiFenfen@CONNECTIVITY.WIFI.HARDWARE.SAR.1785313, 2021/12/11
#add for common sar config, wifisar.cfg, txpowerctrl.cfg abandoned
function getCommonSarIndex() {
	fwkIdx="$1"
	pwrIdx="$1"
	mapFile=$COMMON_SAR_PATH
	local projectBit=""

	if [ -f "$mapFile" ]; then
		projectBit=$(cat "$mapFile" | awk -F "=" '{
		if ($1 == "projectBit") {
			print $2
		}}')
		#echo $projectBit
		#echo $fwkIdx
		if [ -n "$projectBit" ]; then
			fwkIdx="$(transferSarIndex $fwkIdx $projectBit)"
		fi
		#echo $fwkIdx
		pwrIdx=$(cat "$mapFile" | awk -F ";" '{
		if ($1 == "idx:""'$fwkIdx'") {
			print $2
		}}')

		# if no index matched, force set index to 0 and disable sar power
		if [ -z "$pwrIdx" ]; then
			pwrIdx="set_pwr_ctrl _SAR_PwrLevel 0"
		fi
	fi

	echo "$pwrIdx"
}

function excuteSarCommand() {
    local sarindex=`getprop sys.oplus.wlan.sar_idx`
    local lastsarindex=`getprop vendor.oplus.wlan.sar_last_idx`
    mapFile="/odm/etc/wifi/wifisar.map"
    disableSar="set_pwr_ctrl _SAR_PwrLevel 0"
    CommonFile=$COMMON_SAR_PATH

    #According to the order of sar config:wifisar.map > wifisar.cfg > txpowerctrl.cfg
    if [ -f "$mapFile" ]; then
        local powerIndex="$(getSarMappedIndex $sarindex)"
        echo "old index=$sarindex, new index=$powerIndex"
        /odm/bin/iwpriv_vendor wlan0 driver set_pwr_ctrl\ OplusSar\ $powerIndex
    else
        if [ -f "$CommonFile" ]; then
            local powerIndex="$(getCommonSarIndex $sarindex)"
            echo "old index=$sarindex, new index=$powerIndex, lastsarindex=$lastsarindex"
            if [ "$powerIndex" != "$lastsarindex" ]; then
				if [ "${lastsarindex}" == "" ] && [ "${powerIndex}" == "${disableSar}" ]; then
					echo "disableSar=$disableSar, return"
				else
					/odm/bin/iwpriv_vendor wlan0 driver "$powerIndex"
					setprop vendor.oplus.wlan.sar_last_idx "$powerIndex"
				fi
            fi
        else
            echo $sarindex
            local length=${#sarindex}
            echo "length =$length"
            if [ $length -gt 32 -o  $length -eq 0 ]; then
                sarindex=10000000000000000000000000000000
            fi
            echo "new index=${sarindex}"
            if [ $lastsarindex -ne 0 ]; then
                /odm/bin/iwpriv_vendor wlan0 driver "set_pwr_ctrl $lastsarindex 0"
            fi
            /odm/bin/iwpriv_vendor wlan0 driver "set_pwr_ctrl $sarindex 1"
            setprop vendor.oplus.wlan.sar_last_idx $sarindex
        fi
    fi
}

#endif /* OPLUS_FEATURE_WIFI_SAR */

case "$config" in
    #ifdef OPLUS_FEATURE_WIFI_DUMP
    #JiaoBo@CONNECTIVITY.WIFI.BASIC.LOG.1162003, 2018/7/02
    #add for wifi dump related log collection and DCS handle, dynamic enable/disable wifi core dump, offer trigger wifi dump API.
    "clearWifiDumpFile")
    clearWifiDumpFile
    ;;
    #endif /* OPLUS_FEATURE_WIFI_DUMP */
    #ifdef OPLUS_FEATURE_WIFI_RUSUPGRADE
    #JiaoBo@CONNECTIVITY.WIFI.BASIC.HARDWARE.2795386, 2020/02/20
    #add for: support auto update function, include mtk fw, mtk wifi.cfg, qcom fw, qcom bdf, qcom ini
    "rusWifiVendorVerBootCheck")
    rusWifiVendorVerBootCheck
    ;;
    "rusWifiVendorVerUpgradeCheck")
    rusWifiVendorVerUpgradeCheck
    ;;
    #endif /* OPLUS_FEATURE_WIFI_RUSUPGRADE */
    #ifdef OPLUS_FEATURE_WIFI_SAR
    #Shanbolun@CONNECTIVITY.WIFI.BASIC.HARDWARE.337348, 2020/9/17
    #add property to trigger wifisar command
    "excuteSarCommand")
    excuteSarCommand
    ;;
    #endif /* OPLUS_FEATURE_WIFI_SAR */
esac
