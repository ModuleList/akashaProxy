#!/system/bin/sh

scripts=$(realpath "$0")
scripts_dir=$(dirname "${scripts}")
. /data/clash/clash.config

check_file() {
    if [ ! -f "$1" ]; then
        echo "文件不存在: $1"
        return 1
    fi
    if [ ! -x "$1" ]; then
        echo "文件不可执行: $1"
        return 1
    fi
    return 0
}

monitor_local_ipv4() {
    local change=false
    local wifistatus
    local mobilestatus

    wifistatus=$(dumpsys connectivity | grep "WIFI" | grep "state:" | awk -F ", " '{print $2}' | awk -F "=" '{print $2}' 2>&1)

    if [ ! -z "${wifistatus}" ]; then
        if [ ! "${wifistatus}" = "$(cat ${clash_run_path}/lastwifi)" ]; then
            change=true
            echo "${wifistatus}" >"${clash_run_path}/lastwifi"
        elif [ "$(ip route get 1.2.3.4 | awk '{print $5}' 2>&1)" != "wlan0" ]; then
            change=true
            echo "${wifistatus}" >"${clash_run_path}/lastwifi"
        fi
    else
        echo "" >"${clash_run_path}/lastwifi"
    fi

    if [ "$(settings get global mobile_data 2>&1)" -eq 1 ] || [ "$(settings get global mobile_data1 2>&1)" -eq 1 ]; then
        if [ ! "${mobilestatus}" = "$(cat ${clash_run_path}/lastmobile)" ]; then
            change=true
            echo "${mobilestatus}" >"${clash_run_path}/lastmobile"
        fi
    fi

    if [ "${change}" == true ]; then
        local local_ipv4
        local local_ipv6
        local rules_ipv4
        local rules_ipv6

        local_ipv4=$(ip a | awk '$1~/inet$/{print $2}')
        local_ipv6=$(ip -6 a | awk '$1~/inet6$/{print $2}')
        rules_ipv4=$(${iptables_wait} -t mangle -nvL FILTER_LOCAL_IP | grep "ACCEPT" | awk '{print $9}' 2>&1)
        rules_ipv6=$(${ip6tables_wait} -t mangle -nvL FILTER_LOCAL_IP | grep "ACCEPT" | awk '{print $8}' 2>&1)

        for rules_subnet in ${rules_ipv4[*]}; do
            ${iptables_wait} -t mangle -D FILTER_LOCAL_IP -d "${rules_subnet}" -j ACCEPT
        done

        for subnet in ${local_ipv4[*]}; do
            if ! (${iptables_wait} -t mangle -C FILTER_LOCAL_IP -d "${subnet}" -j ACCEPT >/dev/null 2>&1); then
                ${iptables_wait} -t mangle -I FILTER_LOCAL_IP -d "${subnet}" -j ACCEPT
            fi
        done

        for rules_subnet6 in ${rules_ipv6[*]}; do
            ${ip6tables_wait} -t mangle -D FILTER_LOCAL_IP -d "${rules_subnet6}" -j ACCEPT
        done

        for subnet6 in ${local_ipv6[*]}; do
            if ! (${ip6tables_wait} -t mangle -C FILTER_LOCAL_IP -d "${subnet6}" -j ACCEPT >/dev/null 2>&1); then
                ${ip6tables_wait} -t mangle -I FILTER_LOCAL_IP -d "${subnet6}" -j ACCEPT
            fi
        done
    fi

    unset local_ipv4
    unset rules_ipv4
    unset local_ipv6
    unset rules_ipv6
    unset wifistatus
    unset mobilestatus
    unset change
}

restart_clash() {
    ${scripts_dir}/clash.service -k && ${scripts_dir}/clash.iptables -k
    ${scripts_dir}/clash.service -s && ${scripts_dir}/clash.iptables -s
    if [ "$?" == "0" ]; then
        echo "内核成功重启."
    else
        ${scripts_dir}/clash.service -k && ${scripts_dir}/clash.iptables -k
        echo "内核重启失败."
        exit 1
    fi
}

# 更新Clash内核
upgrade_clash() {
    echo "正在下载 ${clash_bin_name} 内核..."
    mkdir -p "${clash_data_dir}/clashkernel/temp"
    remote_clash_ver=$1
    general_clash_filename="mihomo-android-arm64-v8-"
    specific_clash_filename="${general_clash_filename}${remote_clash_ver}"

    download_url="${ghproxy}https://github.com/MetaCubeX/mihomo/releases/latest/download/${specific_clash_filename}.gz"
    
    curl --connect-timeout 5 -Ls -o "${clash_data_dir}/clashkernel/temp/clashMeta.gz" "${download_url}"
    
    if [ ! -f "${clash_data_dir}/clashkernel/temp/clashMeta.gz" ]; then
        echo "下载失败，文件未找到：${clash_data_dir}/clashkernel/temp/clashMeta.gz"
        return 1
    fi

    ${busybox_path} gunzip -f "${clash_data_dir}/clashkernel/temp/clashMeta.gz"
    if [ -f "${clash_data_dir}/clashkernel/temp/clashMeta" ]; then
        rm -f "${clash_data_dir}/clashkernel/clashMeta"
        mv "${clash_data_dir}/clashkernel/temp/clashMeta" "${clash_data_dir}/clashkernel/"
        rm -rf "${clash_data_dir}/clashkernel/temp"
        chmod +x "${clash_data_dir}/clashkernel/clashMeta"
        echo "更新完成"
    else
        rm -rf "${clash_data_dir}/clashkernel/temp"
        echo "更新失败，无法解压 clashMeta.gz"
        return 1
    fi
}

update_pre() {
    local flag=false
    if [ "$geo_auto_update" != "true" ]; then
        if [ "$auto_update_geoip" == "true" ]; then
            update_file "$geoip_url" "$clash_geoip_file"
        fi
        if [ "$auto_update_geosite" == "true" ]; then
            update_file "$geosite_url" "$clash_geosite_file"
        fi
    fi
    if [ "$auto_update_clashmeta" == "true" ] || [ ! -f "$clash_bin_path" ]; then
        check_clash_ver
        flag=true
    fi
    if [ -f "$clash_pid_file" ] && [ "$flag" == true ]; then
        if [ "$restart_update" == "true" ]; then
            restart_clash
        fi
    fi
}

update_file() {
    local file="$1"
    local file_temp="${file}.temp"
    local update_url="$2"

    curl -L "$update_url" -o "$file_temp"

    if [ -f "$file_temp" ]; then
        mv -f "$file_temp" "$file"
        echo "${file}更新成功."
    else
        rm -rf "$file_temp"
        echo "${file}更新失败"
        return 1
    fi
}

while getopts ":kfmpusl" signal; do
    case ${signal} in
    u)
        update_pre
        ;;
    s)
        reload
        ;;
    k)
        if [ "$mode" = "blacklist" ] || [ "$mode" = "whitelist" ] || [ "$mode" = "global" ]; then
            keep_dns
        else
            exit 0
        fi
        ;;
    f)
        find_packages_uid
        ;;
    m)
        if [ "$mode" = "blacklist" ] && [ -f "$clash_pid_file" ]; then
            monitor_local_ipv4
        elif [ "$mode" = "global" ] && [ -f "$clash_pid_file" ]; then
            monitor_local_ipv4
        else
            exit 0
        fi
        ;;
    p)
        port_detection
        ;;
    l)
        limit_clash
        ;;
    ?)
        echo "Usage: $0 [-u] [-s] [-k] [-f] [-m] [-p] [-l]"
        ;;
    esac
done