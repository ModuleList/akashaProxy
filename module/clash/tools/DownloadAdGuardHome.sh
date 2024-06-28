#!/system/bin/sh
. /data/clash/clash.config

curl -# -L -o AdGuardHome_linux_arm64.tar.gz "${ghproxy}/https://github.com/AdguardTeam/AdGuardHome/releases/latest/download/AdGuardHome_linux_arm64.tar.gz"
if [ ! -f "AdGuardHome_linux_arm64.tar.gz" ];then
    echo "下载失败"
    exit
else
    [ ! -d ${Clash_data_dir}/adguard/temp ] && mkdir -p ${Clash_data_dir}/adguard/temp
    tar -xzvf AdGuardHome_linux_arm64.tar.gz -C ${Clash_data_dir}/adguard/temp
    mv -f ${Clash_data_dir}/adguard/temp/AdGuardHome/AdGuardHome ${Clash_data_dir}/adguard/AdGuardHome
    rm -rf ${Clash_data_dir}/adguard/temp
    rm -rf AdGuardHome_linux_arm64.tar.gz
    chmod 6755 ${Clash_data_dir}/adguard/AdGuardHome
fi

if [ ! -f "${Adguard_config_file}" ] || [ -f ${Adguard_bin_path} ];then
    echo "进入adguardhome初始化流程"
    nohup ${Adguard_bin_path} -w ${Clash_data_dir} --pidfile ${Adguard_pid_file} -l /data/clash/run/adg.log > /dev/null &
    sleep 0.5
    echo "请使用浏览器打开 http://127.0.0.1:3000 完成初始化设置"
    am start -a android.intent.action.VIEW -d "http://127.0.0.1:3000"
    while true
    do
    sleep 0.1
        if [ -f "${Adguard_config_file}" ];then
            echo "完成"
            kill -15 $(cat ${Adguard_pid_file})
            rm -rf ${Adguard_pid_file}
            rm -rf ${Clash_data_dir}/data
            break
        fi
    done
fi