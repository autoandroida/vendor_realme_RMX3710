#!/system/bin/sh

SPECIAL_MY_COMPANY_RES_PATH=/my_company/media/logo
SPECIAL_MY_OPERATOR_RES_PATH=${MY_CARRIER_ROOT}/media/logo
SPECIAL_MY_COUNTRY_RES_PATH=${MY_REGION_ROOT}/media/logo
SPECIAL_MY_PRODUCT_RES_PATH=/my_product/media/logo

CLGEN_BIN_FILE_PATH=/system_ext/bin/CLGen
SPLASH_LOGO_BLOCK_LOCATION=/dev/block/by-name/splash_odm
LOGO_PARTITION=/dev/block/by-name/logo
SPLASH_LOGO_BLOCK_LOCATION_A=/dev/block/by-name/splash_a
SPLASH_LOGO_BLOCK_LOCATION_B=/dev/block/by-name/splash_b

CHECKSUM_PROP=persist.sys.cust_logo_checksum
DISPLAYMETRICS_PROP="persist.sys.oppo.displaymetrics"
HW_PLATFORM_PROP="ro.boot.hardware"

special_logo_file=""
is_current_platform=""

function check_md5sum {
    local src_file=$1

    if [ -f $src_file ];then
      md5=$(md5sum $src_file |cut -b 1-32)

      if [ x"$(getprop $CHECKSUM_PROP)" != x"$md5" ];then
          setprop $CHECKSUM_PROP "$md5"
      else
          echo "try to override the logo with previous image, exit"
          exit 1
      fi
    else
       echo "None special logo file been found, nothing to do, exit"
       exit 1
    fi

}

function do_exec {
    local src_file=$1

    if [  ! -x ${CLGEN_BIN_FILE_PATH} ];then
       echo "GLGen can not been executed, exit!"
       exit 1
    fi

    if [ x"${is_current_platform}" == x"Qualcomm" ];then
        echo "Qualcomm change logo now!"
	    if [ -w $SPLASH_LOGO_BLOCK_LOCATION ];then
	       ${CLGEN_BIN_FILE_PATH} ${SPLASH_LOGO_BLOCK_LOCATION} ${src_file}
	       echo "Splash partition is SPLASH_LOGO_BLOCK_LOCATION!"
	    elif [ -w $SPLASH_LOGO_BLOCK_LOCATION_A ];then
	       ${CLGEN_BIN_FILE_PATH} ${SPLASH_LOGO_BLOCK_LOCATION_A} ${src_file}
	       echo "Splash partition is SPLASH_LOGO_BLOCK_LOCATION_A!"
	    elif [ -w $SPLASH_LOGO_BLOCK_LOCATION_B ];then
	       ${CLGEN_BIN_FILE_PATH} ${SPLASH_LOGO_BLOCK_LOCATION_B} ${src_file}
	       echo "Splash partition is SPLASH_LOGO_BLOCK_LOCATION_B!"
	    else
	       echo "Splash partition does not exist!"
	    fi
    else
        echo "MTK change logo now!"
        ${CLGEN_BIN_FILE_PATH} ${src_file} ${SPLASH_LOGO_BLOCK_LOCATION}
    fi
}

function recover_exec {

    if [  ! -x ${CLGEN_BIN_FILE_PATH} ];then
       echo "GLGen can not been executed, exit!"
       exit 1
    fi

    if [ x"$(getprop $CHECKSUM_PROP)" == x"" ];then
       echo "Empty CHECKSUM_PROP, nothing to do with logo CLGen!"
       exit 1
    fi

    if [[ x"$(getprop $CHECKSUM_PROP)" != x"0" && -w ${SPLASH_LOGO_BLOCK_LOCATION} ]];then
        setprop $CHECKSUM_PROP 0
        ${CLGEN_BIN_FILE_PATH} ${SPLASH_LOGO_BLOCK_LOCATION}
    elif [[ x"$(getprop $CHECKSUM_PROP)" != x"0" && -w ${SPLASH_LOGO_BLOCK_LOCATION_A} ]];then
        setprop $CHECKSUM_PROP 0
        ${CLGEN_BIN_FILE_PATH} ${SPLASH_LOGO_BLOCK_LOCATION_A}
    elif [[ x"$(getprop $CHECKSUM_PROP)" != x"0" && -w ${SPLASH_LOGO_BLOCK_LOCATION_B} ]];then
        setprop $CHECKSUM_PROP 0
        ${CLGEN_BIN_FILE_PATH} ${SPLASH_LOGO_BLOCK_LOCATION_B}
    else
        echo "Already recovered, no need again!"
    fi
}

function check_current_platform {
    if [ x"$(getprop $HW_PLATFORM_PROP)" == x"qcom" ];then
        echo "current platform is Qualcomm!"
        is_current_platform=Qualcomm
    else
        echo "current platform is MTK!"
        is_current_platform=MTK
        if [ -L ${LOGO_PARTITION} ];then
            SPLASH_LOGO_BLOCK_LOCATION=${LOGO_PARTITION}
        fi
    fi
    echo ${SPLASH_LOGO_BLOCK_LOCATION}
}

function choose_special_logo_file {
    local lcm_height=`getprop ${DISPLAYMETRICS_PROP}|cut -d "," -f 2`
    echo "lcm_height: ${lcm_height}"

    if [[ x"${special_logo_file}" == x"" && -d ${SPECIAL_MY_COMPANY_RES_PATH} ]];then
        if [ -d ${SPECIAL_MY_COMPANY_RES_PATH}/${lcm_height} ];then
            for bmp_file in `find ${SPECIAL_MY_COMPANY_RES_PATH}/${lcm_height} -name "*.bmp"`;do
                special_logo_file=${bmp_file}
                break
            done
        fi
    fi

    if [[ x"${special_logo_file}" == x"" && -d ${SPECIAL_MY_OPERATOR_RES_PATH} ]];then
        if [ -d ${SPECIAL_MY_OPERATOR_RES_PATH}/${lcm_height} ];then
            for bmp_file in `find ${SPECIAL_MY_OPERATOR_RES_PATH}/${lcm_height} -name "*.bmp"`;do
                special_logo_file=${bmp_file}
                break
            done
        fi
    fi

    if [[ x"${special_logo_file}" == x"" && -d ${SPECIAL_MY_COUNTRY_RES_PATH} ]];then
        if [ -d ${SPECIAL_MY_COUNTRY_RES_PATH}/${lcm_height} ];then
            for bmp_file in `find ${SPECIAL_MY_COUNTRY_RES_PATH}/${lcm_height} -name "*.bmp"`;do
                special_logo_file=${bmp_file}
                break
            done
        fi
    fi

    if [[ x"${special_logo_file}" == x"" && -d ${SPECIAL_MY_PRODUCT_RES_PATH} ]];then
        if [ -d ${SPECIAL_MY_PRODUCT_RES_PATH}/${lcm_height} ];then
            for bmp_file in `find ${SPECIAL_MY_PRODUCT_RES_PATH}/${lcm_height} -name "*.bmp"`;do
                special_logo_file=${bmp_file}
                break
            done
        fi
    fi
}

function main {
    echo "do_splash_logo start!"

    check_current_platform

    echo "check_current_platform end!"

    choose_special_logo_file

    echo "choose_special_logo_file end!"

    echo ${special_logo_file}

    if [ x"${special_logo_file}" != x"" ];then
        check_md5sum ${special_logo_file}

        echo "check_md5sum end!"

        do_exec ${special_logo_file}
    else
        echo "recover_exec start!"
        recover_exec
    fi

    echo "do_splash_logo end!"
}

main
