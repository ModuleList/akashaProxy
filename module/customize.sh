#!/system/bin/sh

MIN_KSU_VERSION=11563
MIN_KSUD_VERSION=11563
MIN_MAGISK_VERSION=26402

if [ ! $KSU ];then
    ui_print "- Magisk ver: $MAGISK_VER"
    if [[ $($MAGISK_VER | grep "kitsune") ]] || [[ $($MAGISK_VER | grep "delta") ]]; then
        ui_print "*********************************************************"
        ui_print "不支持 Magisk Delta 和 Magisk kitsune"
        echo "">remove
        abort "*********************************************************"
    fi
    
    ui_print "- Magisk version: $MAGISK_VER_CODE"
    if [ "$MAGISK_VER_CODE" -lt MIN_MAGISK_VERSION ]; then
        ui_print "*********************************************************"
        ui_print "! 请使用 Magisk alpha 26301+"
        abort "*********************************************************"
    fi
elif [ $KSU ];then
    ui_print "- KernelSU version: $KSU_KERNEL_VER_CODE (kernel) + $KSU_VER_CODE (ksud)"
    if ! [ "$KSU_KERNEL_VER_CODE" ] || [ "$KSU_KERNEL_VER_CODE" -lt $MIN_KSU_VERSION ] || [ "$KSU_VER_CODE" -lt $MIN_KSUD_VERSION ]; then
        ui_print "*********************************************************"
        ui_print "! KernelSU 版本太旧!"
        ui_print "! 请将 KernelSU 更新到最新版本"
        abort "*********************************************************"
    fi
else
    ui_print "! 未知的模块管理器"
    ui_print "$(set)"
    abort
fi


status=""
architecture=""
system_gid="1000"
system_uid="1000"
clash_data_dir="/data/clash"
modules_dir="/data/adb/modules"
ABI=$(getprop ro.product.cpu.abi)
mkdir -p ${clash_data_dir}/run
mkdir -p ${clash_data_dir}/clashkernel

if [ ! -f ${clash_data_dir}/clashkernel/clashMeta ];then
    unzip -o "$ZIPFILE" 'bin/*' -d "$TMPDIR" >&2
    if [ -f "${MODPATH}/bin/clashMeta-android-${ABI}.tar.bz2" ];then
        tar -xjf ${MODPATH}/bin/clashMeta-android-${ABI}.tar.bz2 -C ${clash_data_dir}/clashkernel/
        mv -f ${clash_data_dir}/clashkernel/clashMeta-android-${ABI} ${clash_data_dir}/clashkernel/clashMeta
    else
        if [ -f "${MODPATH}/bin/clashMeta-android-default.tar.bz2" ];then
            tar -xjf ${MODPATH}/bin/clashMeta-android-${ABI}.tar.bz2 -C ${clash_data_dir}/clashkernel/
            mv -f ${clash_data_dir}/clashkernel/clashMeta-android-${ABI} ${clash_data_dir}/clashkernel/clashMeta
        else
            ui_print "未找到架构: ${ABI}"
            abort "请使用 “make default” 为${ABI}架构编译clashMeta"
        fi
    fi
fi

unzip -o "${ZIPFILE}" -x 'META-INF/*' -d ${MODPATH} >&2
unzip -o "${ZIPFILE}" -x 'clash/*' -d ${MODPATH} >&2

if [ -f "${clash_data_dir}/config.yaml" ];then
    ui_print "- config.yaml 文件已存在 跳过覆盖."
    rm -rf ${MODPATH}/clash/config.yaml
fi

if [ -f "${clash_data_dir}/clash.yaml" ];then
    ui_print "- clash.yaml 文件已存在 跳过覆盖."
    rm -rf ${MODPATH}/clash/clash.yaml
fi

if [ -f "${clash_data_dir}/packages.list" ];then
        ui_print "- packages.list 文件已存在 跳过覆盖."
        rm -rf ${MODPATH}/clash/packages.list
fi

if [ -f "${clash_data_dir}/clash.config" ];then
    mode=$(grep -i "^mode" ${clash_data_dir}/clash.config | awk -F '=' '{print $2}' | sed "s/\"//g")
    oldVersion=$(grep -i "version" ${clash_data_dir}/clash.config | awk -F '=' '{print $2}' | sed "s/\"//g")
    newVersion=$(grep -i "version" ${MODPATH}/clash/clash.config | awk -F '=' '{print $2}' | sed "s/\"//g")
    if [ "${oldVersion}" < "${newVersion}" ] && [ ! "${oldVersion}" == "" ];then
        ui_print "- clash.config 文件已存在 跳过覆盖."
        rm -rf ${MODPATH}/clash/clash.config
    else
        sed -i "s/global/${mode}/g" ${MODPATH}/clash/clash.config
    fi
fi

cp -Rf ${MODPATH}/clash/* ${clash_data_dir}/
rm -rf ${MODPATH}/clash
rm -rf ${MODPATH}/bin
rm -rf ${MODPATH}/clashkernel

ui_print "- 开始设置权限."
set_perm_recursive ${MODPATH} 0 0 0770 0770
set_perm_recursive ${clash_data_dir} ${system_uid} ${system_gid} 0770 0770
set_perm_recursive ${clash_data_dir}/scripts ${system_uid} ${system_gid} 0770 0770
set_perm_recursive ${clash_data_dir}/mosdns ${system_uid} ${system_gid} 0770 0770
set_perm_recursive ${clash_data_dir}/adguard ${system_uid} ${system_gid} 0770 0770
set_perm_recursive ${clash_data_dir}/clashkernel ${system_uid} ${system_gid} 6770 6770
set_perm  ${clash_data_dir}/mosdns/mosdns  ${system_uid}  ${system_gid}  6770
set_perm  ${clash_data_dir}/adguard/AdGuardHome  ${system_uid}  ${system_gid}  6770
set_perm  ${clash_data_dir}/clashkernel/clashMeta  ${system_uid}  ${system_gid}  6770
set_perm  ${clash_data_dir}/clash.config ${system_uid} ${system_gid} 0770
set_perm  ${clash_data_dir}/packages.list ${system_uid} ${system_gid} 0770


ui_print ""
ui_print "教程见→https://github.com/ModuleList/akashaProxy"
ui_print "************************************************"
ui_print "Telegram Channel: https://t.me/akashaProxy"
ui_print ""
ui_print "为了让你能够阅读以上消息，安装进度暂停5秒!"
sleep 5
