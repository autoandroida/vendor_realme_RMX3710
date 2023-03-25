#! /vendor/bin/sh
#***********************************************************
## Copyright 2021 OPLUS Mobile Comm Corp., Ltd.
## OPLUS_FEATURE_BT_FW_SAU_MTK
## File: vendor_bluetooth_fw_permission.te
## Description :change permission of /data/vendor/firmware/update for supporting
##              MTK firmware update by sau_res for bluetooth model.
## Version: 1.0
## Date : 2021/03/25
## Author: FengChen@CONNECTIVITY.BT
## ----------------- Revision History: ----------------------
## <author>      <data>        <desc>
## FengChen     2021/03/25    create this file
#****************************************************************/


config="$1"

function changeBtFwPermission() {
    chown -R bluetooth bluetooth /data/vendor/firmware/update/
#    chmod 0777 /data/vendor/bluetooth/fw/*
    chmod -R 0777 /data/vendor/firmware/update/
}

case "$config" in
        "changeBtFwPermission")
        changeBtFwPermission
    ;;
esac
