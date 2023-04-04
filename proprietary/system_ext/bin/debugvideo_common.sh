#! /system/bin/sh

config="$1"

#================================== COMMON LOG =========================

function videologmtkc2on() {
    echo -codec_log 7 -vpud_log 3 -job_log 3 > /sys/module/mtk_vcodec_dec_v2/parameters/mtk_vdec_vcp_log
    echo 2 > /proc/mtprintk
    echo 7 > /sys/module/mtk_vcodec_dec_v2/parameters/mtk_v4l2_dbg_level
    echo 1 > /sys/module/mtk_vcodec_dec_v2/parameters/mtk_vcodec_dbg
}

function videologmtkc2off() {
    echo -codec_log 0 -vpud_log 0 -job_log 0 > /sys/module/mtk_vcodec_dec_v2/parameters/mtk_vdec_vcp_log
    echo 0 > /proc/mtprintk
    echo 0 > /sys/module/mtk_vcodec_dec_v2/parameters/mtk_v4l2_dbg_level
    echo 0 > /sys/module/mtk_vcodec_dec_v2/parameters/mtk_vcodec_dbg
}

function videologqcomc2on() {
}

function videologqcomc2off() {
}

case "$config" in
    "videologmtkc2on")
        videologmtkc2on
        ;;
    "videologmtkc2off")
        videologmtkc2off
        ;;
    "videologqcomc2on")
        videologqcomc2on
        ;;
    "videologqcomc2off")
        videologqcomc2off
        ;;
       *)

      ;;
esac
