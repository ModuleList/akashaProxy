#!/system/bin/sh

status=""
architecture=""
system_gid="1000"
system_uid="1000"
clash_data_dir="/data/clash"
modules_dir="/data/adb/modules"
config="false" #更新是否替换clash.config
ABI=$(getprop ro.product.cpu.abi)
mkdir -p ${clash_data_dir}/run
mkdir -p ${clash_data_dir}/clashkernel

if [ ! -f ${clash_data_dir}/clashkernel/clashMeta ];then
    if [ -f "${MODPATH}/bin/clashMeta-android-${ABI}.tar.bz2" ];then
        tar -xjf ${MODPATH}/bin/clashMeta-android-${ABI}.tar.bz2 -C ${clash_data_dir}/clashkernel/
        mv -f ${clash_data_dir}/clashkernel/clashMeta-android-${ABI} ${clash_data_dir}/clashkernel/clashMeta
    else
        if [ -f "${MODPATH}/bin/clashMeta-android-default.tar.bz2" ];then
            tar -xjf ${MODPATH}/bin/clashMeta-android-${ABI}.tar.bz2 -C ${clash_data_dir}/clashkernel/
            mv -f ${clash_data_dir}/clashkernel/clashMeta-android-${ABI} ${clash_data_dir}/clashkernel/clashMeta
        else
            ui_print "Your architecture was not found: ${ABI}\nPlease use 'make default' to compile clashMeta for ${ABI} architecture"
            abort 1
        fi
    fi
fi

unzip -o "${ZIPFILE}" -x 'META-INF/*' -d ${MODPATH} >&2

if [ -f "${clash_data_dir}/config.yaml" ];then
    ui_print "-config.yaml The file already exists. Do not add the default file."
    rm -rf ${MODPATH}/config.yaml
else
    ui_print "-config.yaml The file not exists. Do add the default file."
fi

if [ -f "${clash_data_dir}/clash.yaml" ];then
    ui_print "-clash.yaml The file already exists. Do not add the default file."
    rm -rf ${MODPATH}/clash.yaml
else
    ui_print "-clash.yaml The file not exists. Do add the default file."
fi

if [ -f "${clash_data_dir}/packages.list" ];then
    if [ "${config}" == "false" ];then
        ui_print "-packages.list The file already exists. Do not add the default file."
        rm -rf ${MODPATH}/packages.list
    fi
else
    ui_print "-packages.list The file not exists. Do add the default file."
fi

mv -f ${MODPATH}/clash/* ${clash_data_dir}/
rm -rf ${MODPATH}/clashkernel

ui_print "- Start setting permissions."
set_perm_recursive ${MODPATH} 0 0 0755 0755
set_perm  ${MODPATH}/system/bin/setcap  0  0  0755
set_perm  ${MODPATH}/system/bin/getcap  0  0  0755
set_perm  ${MODPATH}/system/bin/getpcaps  0  0  0755
set_perm  ${MODPATH}${ca_path}/cacert.pem 0 0 0644
set_perm  ${MODPATH}/system/bin/curl 0 0 0755
set_perm_recursive ${clash_data_dir} ${system_uid} ${system_gid} 0755 0644
set_perm_recursive ${clash_data_dir}/scripts ${system_uid} ${system_gid} 0755 0755
set_perm_recursive ${clash_data_dir}/clashkernel ${system_uid} ${system_gid} 6755 6755
set_perm  ${clash_data_dir}/clashkernel/clash  ${system_uid}  ${system_gid}  6755
set_perm  ${clash_data_dir}/clash.config ${system_uid} ${system_gid} 0755
set_perm  ${clash_data_dir}/packages.list ${system_uid} ${system_gid} 0644


ui_print ""
ui_print ""
ui_print "************************************************"
ui_print "## Module path:
**Work path: /data/clash/
```
├── adguard
│   ├── // AdGuardHome module
├── clash.config (clash start config)
├── clash.yaml (clash config#1)
├── clashkernel
│   ├── clashMeta //clash
├── config.yaml (clash config#2)
├── packages.list (black/white list packages list)
├── mosdns
│   ├── // mosdns module
├── scripts // clash start script
│   ├── clash.inotify
│   ├── clash.iptables
│   ├── clash.service
│   └── clash.tool 
├── yacd
│   ├── //yacd-Meta
└── DeleteCache.sh
```"
ui_print "telegram channel: @wtdnwbzda"
ui_print ""
ui_print "In order to allow you to read the above message, the installation progress is paused for 5 seconds!"
sleep 5