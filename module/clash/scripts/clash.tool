#!/system/bin/sh

script_path=$(realpath "$0")
script_dir=$(dirname "${script_path}")
config_file="/data/clash/clash.config"

if [ -f "${config_file}" ]; then
    . "${config_file}"
else
    echo "err: 配置文件 ${config_file} 不存在" >&2
    exit 1
fi

# 日志函数
log() {
    local level=$(echo "$1" | cut -d ':' -f 1)
    local message=$(echo "$1" | cut -d ':' -f 2-)
    local timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    
    [ -z "${clash_log_file}" ] && clash_log_file="/dev/null"
    
    case "${level}" in
        "err") echo "[${timestamp}] ERROR: ${message}" >> "${clash_log_file}" ;;
        "warn") echo "[${timestamp}] WARNING: ${message}" >> "${clash_log_file}" ;;
        *) echo "[${timestamp}] INFO: ${message}" >> "${clash_log_file}" ;;
    esac
}

monitor_local_ipv4() {
    local change=false
    local wifi_status=$(dumpsys connectivity | grep "WIFI" | grep "state:" | awk -F ", " '{print $2}' | awk -F "=" '{print $2}' 2>&1)
    local last_wifi_file="${clash_run_path}/lastwifi"
    local last_mobile_file="${clash_run_path}/lastmobile"

    if [ -n "${wifi_status}" ]; then
        if [ ! -f "${last_wifi_file}" ] || [ "${wifi_status}" != "$(cat "${last_wifi_file}")" ]; then
            change=true
            echo "${wifi_status}" > "${last_wifi_file}"
        elif [ "$(ip route get 1.2.3.4 | awk '{print $5}' 2>&1)" != "wlan0" ]; then
            change=true
            echo "${wifi_status}" > "${last_wifi_file}"
        fi
    else
        echo "" > "${last_wifi_file}"
    fi

    if [ "$(settings get global mobile_data 2>&1)" -eq 1 ] || [ "$(settings get global mobile_data1 2>&1)" -eq 1 ]; then
        local mobile_status="active"
        if [ ! -f "${last_mobile_file}" ] || [ "${mobile_status}" != "$(cat "${last_mobile_file}")" ]; then
            change=true
            echo "${mobile_status}" > "${last_mobile_file}"
        fi
    fi

    if [ "${change}" = true ]; then
        update_ip_rules
    fi
}

update_ip_rules() {
    local local_ipv4_list=$(ip a | awk '$1~/inet$/{print $2}')
    local rules_ipv4_list=$(${iptables_wait} -t mangle -nvL FILTER_LOCAL_IP | grep "ACCEPT" | awk '{print $9}' 2>&1)
    
    for rules_subnet in ${rules_ipv4_list}; do
        ${iptables_wait} -t mangle -D FILTER_LOCAL_IP -d "${rules_subnet}" -j ACCEPT
    done

    for subnet in ${local_ipv4_list}; do
        if ! ${iptables_wait} -t mangle -C FILTER_LOCAL_IP -d "${subnet}" -j ACCEPT >/dev/null 2>&1; then
            ${iptables_wait} -t mangle -I FILTER_LOCAL_IP -d "${subnet}" -j ACCEPT
        fi
    done

    local local_ipv6_list=$(ip -6 a | awk '$1~/inet6$/{print $2}')
    local rules_ipv6_list=$(${ip6tables_wait} -t mangle -nvL FILTER_LOCAL_IP | grep "ACCEPT" | awk '{print $8}' 2>&1)

    for rules_subnet6 in ${rules_ipv6_list}; do
        ${ip6tables_wait} -t mangle -D FILTER_LOCAL_IP -d "${rules_subnet6}" -j ACCEPT
    done

    for subnet6 in ${local_ipv6_list}; do
        if ! ${ip6tables_wait} -t mangle -C FILTER_LOCAL_IP -d "${subnet6}" -j ACCEPT >/dev/null 2>&1; then
            ${ip6tables_wait} -t mangle -I FILTER_LOCAL_IP -d "${subnet6}" -j ACCEPT
        fi
    done
}

restart_clash() {
    log "info: 正在重启Clash服务..."
    
    if ! ${script_dir}/clash.service -k || ! ${script_dir}/clash.iptables -k; then
        log "err: 停止服务失败"
        return 1
    fi

    if ${script_dir}/clash.service -s && ${script_dir}/clash.iptables -s; then
        log "info: 服务重启成功"
        return 0
    else
        log "err: 服务启动失败"
        ${script_dir}/clash.service -k
        ${script_dir}/clash.iptables -k
        return 1
    fi
}

keep_dns() {
    local local_dns=$(getprop net.dns1)
    local dns_count=$(getprop | grep -c 'net\.dns')

    if [ "${local_dns}" != "${static_dns}" ]; then
        for count in $(seq 1 "${dns_count}"); do
            setprop "net.dns${count}" "${static_dns}"
        done
    fi

    if [ "$(sysctl -n net.ipv4.ip_forward)" != "1" ]; then
        sysctl -w net.ipv4.ip_forward=1 >/dev/null
    fi
}

upgrade_clash() {
    local remote_version="$1"
    local temp_dir="${clash_data_dir}/clashkernel/temp"
    local general_filename="mihomo-android-arm64-v8-"
    local specific_filename=""
    local download_url=""
    local success=false

    mkdir -p "${temp_dir}" || {
        log "err: 无法创建 ${temp_dir}"
        return 1
    }

    if [[ "${cgo}" == "true" && "${go120}" == "true" ]]; then
        log "err: 不支持 cgo 和 go120 共存的构建版本"
        return 1
    elif [[ "${cgo}" == "true" ]]; then
        specific_filename="${general_filename}cgo-${remote_version}"
    elif [[ "${go120}" == "true" ]]; then
        specific_filename="${general_filename}go120-${remote_version}"
    else
        specific_filename="${general_filename}${remote_version}"
    fi

    if [[ "${alpha}" == "true" ]]; then
        download_url="${ghproxy}https://github.com/MetaCubeX/mihomo/releases/download/Prerelease-Alpha/${specific_filename}.gz"
    else
        download_url="${ghproxy}https://github.com/MetaCubeX/mihomo/releases/latest/download/${specific_filename}.gz"
    fi

    log "info: 正在下载内核 (${remote_version})..."
    if ! curl --connect-timeout 15 --retry 3 -Lfs -o "${temp_dir}/clashMeta.gz" "${download_url}"; then
        log "err: 下载失败: ${download_url}"
        rm -rf "${temp_dir}"
        return 1
    fi

    if ! ${busybox_path} gunzip -f "${temp_dir}/clashMeta.gz" || \
       [ ! -f "${temp_dir}/clashMeta" ]; then
        log "err: 解压失败或文件损坏"
        rm -rf "${temp_dir}"
        return 1
    fi

    if mv -f "${temp_dir}/clashMeta" "${clash_data_dir}/clashkernel/" && \
       chmod 755 "${clash_data_dir}/clashkernel/clashMeta"; then
        success=true
    fi

    rm -rf "${temp_dir}"

    if ${success}; then
        log "info: 内核更新成功"
        return 0
    else
        log "err: 文件移动或权限设置失败"
        return 1
    fi
}

check_clash_ver() {
    local remote_version=""
    local local_version=""
    local version_url=""

    if [[ "${alpha}" == "true" ]]; then
        version_url="${ghproxy}https://github.com/MetaCubeX/mihomo/releases/download/Prerelease-Alpha/version.txt"
    else
        version_url="${ghproxy}https://github.com/MetaCubeX/mihomo/releases/latest/download/version.txt"
    fi

    remote_version=$(curl --connect-timeout 10 -Ls "${version_url}" | head -n 1 | tr -d '[:space:]')
    if [[ -z "${remote_version}" ]]; then
        log "err: 获取远程版本失败"
        return 1
    fi

    if [[ -f "${clash_bin_path}" ]]; then
        local_version=$("${clash_bin_path}" -v 2>/dev/null | awk '/Meta/{print $3}' | head -n 1)
    fi

    if [[ "${remote_version}" == "${local_version}" ]]; then
        log "info: 当前已是最新版 (${local_version})"
        return 0
    elif [[ -z "${local_version}" ]]; then
        log "warn: 未检测到本地内核，将安装最新版 (${remote_version})"
    else
        log "info: 发现新版本: 本地=${local_version}, 远程=${remote_version}"
    fi

    if ! upgrade_clash "${remote_version}"; then
        log "err: 内核更新失败"
        return 1
    fi

    if [[ "${restart_after_update}" == "true" ]] && [[ -f "${clash_pid_file}" ]]; then
        restart_clash
    fi
}

update_file() {
    local file="$1"
    local file_temp="${file}.temp"
    local update_url="$2"

    if ! curl -L --connect-timeout 10 -o "${file_temp}" "${update_url}"; then
        log "err: 下载失败: ${update_url}"
        rm -f "${file_temp}"
        return 1
    fi

    if [ -f "${file_temp}" ]; then
        if mv -f "${file_temp}" "${file}"; then
            log "info: 文件更新成功: ${file}"
            return 0
        else
            log "err: 文件移动失败: ${file_temp} -> ${file}"
            rm -f "${file_temp}"
            return 1
        fi
    else
        log "err: 临时文件不存在: ${file_temp}"
        return 1
    fi
}

find_packages_uid() {
    local uids=""
    local package=""
    local uid=""
    local nhd=""
    local hd=""

    rm -f "${appuid_file}" "${appuid_file}.tmp"

    if [ "${mode}" == "global" ]; then
        mode="blacklist"
        uids=""
    else
        if [ "${proxy_google}" == "true" ]; then
            if [ "${mode}" == "whitelist" ]; then
                uids=$(cat "${filter_packages_file}" "${clash_run_path}/Google.dat" 2>/dev/null)
            else
                log "err: proxy_google只能在whitelist模式下使用"
                exit 1
            fi
        else
            uids=$(cat "${filter_packages_file}" 2>/dev/null)
        fi
    fi

    for package in ${uids}; do
        if [[ "${package}" =~ : ]] || [[ "${package}" =~ [0-9]+\.[0-9]+\.[0-9]+\.[0-9]+ ]]; then
            echo "${package}" >> "${appuid_file}"
            log "info: 已添加规则: ${package}"
            continue
        fi

        nhd=$(awk -F ">" '/^[0-9]+>$/{print $1}' <<< "${package}")
        if [ -n "${nhd}" ]; then
            hd="${nhd}"
            continue
        fi

        uid=$(awk '$1~/^'"${package}"'$/{print $2}' "${system_packages_file}" 2>/dev/null)
        if [ -z "${uid}" ]; then
            uid=$(dumpsys package "${package}" | grep appId= | awk -F= '{print $2}')
            if [ -z "${uid}" ]; then
                log "warn: 未找到: ${package}"
                continue
            fi
        fi

        echo "${hd}${uid}" >> "${appuid_file}.tmp"
        log "info: 已添加: ${hd}${package} -> ${hd}${uid}"
    done

    if [ -f "${appuid_file}.tmp" ]; then
        sort -u "${appuid_file}.tmp" >> "${appuid_file}"
        rm -f "${appuid_file}.tmp"
    fi
}

port_detection() {
    local clash_pid=$(cat "${clash_pid_file}" 2>/dev/null)
    local clash_ports=""

    if [ -z "${clash_pid}" ]; then
        log "err: 未找到Clash进程ID"
        exit 1
    fi

    if ! ss -h >/dev/null 2>&1; then
        clash_ports=$(netstat -anlp | grep -v p6 | grep "${clash_bin_name}" | \
                     awk -v pid="${clash_pid}" '$6~pid"*"{print $4}' | awk -F: '{print $2}' | sort -u)
    else
        clash_ports=$(ss -antup | grep "${clash_bin_name}" | \
                     awk -v pid="${clash_pid}" '$7~"pid="pid"{print $5}' | awk -F: '{print $2}' | sort -u)
    fi

    if [[ "${clash_ports}" =~ ${clash_tproxy_port} ]]; then
        log "info: tproxy端口(${clash_tproxy_port})正常"
    else
        log "err: tproxy端口(${clash_tproxy_port})未监听"
        exit 1
    fi

    if [[ "${clash_ports}" =~ ${clash_dns_port} ]]; then
        log "info: DNS端口(${clash_dns_port})正常"
    else
        log "err: DNS端口(${clash_dns_port})未监听"
        exit 1
    fi

    exit 0
}

update_pre() {
    local flag=false

    if [ "${geo_auto_update}" != "true" ]; then
        if [ "${auto_update_geoip}" == "true" ]; then
            update_file "${clash_geoip_file}" "${geoip_url}" && flag=true
        fi
        if [ "${auto_update_geosite}" == "true" ]; then
            update_file "${clash_geosite_file}" "${geosite_url}" && flag=true
        fi
    fi

    if [ "${auto_update_clash}" == "true" ] || [ ! -f "${clash_bin_path}" ]; then
        if check_clash_ver; then
            flag=true
        fi
    fi

    if [ -f "${clash_pid_file}" ] && [ "${flag}" == true ]; then
        if [ "${restart_after_update}" == "true" ]; then
            restart_clash
        fi
    fi
}

reload_config() {
    local temporary_config="${clash_run_path}/config.temp.yaml"

    if [ ! -f "${clash_config_file}" ]; then
        log "err: 主配置文件不存在: ${clash_config_file}"
        return 1
    fi

    cp -f "${clash_config_file}" "${temporary_config}" || {
        log "err: 无法创建临时配置文件"
        return 1
    }

    if ! curl -X PUT -d "{\"configs\": [\"${temporary_config}\"]}" \
              "http://127.0.0.1:${clash_ui_port}/configs?force=true" >/dev/null 2>&1; then
        log "err: 配置重载失败"
        return 1
    fi

    log "info: 配置重载成功"
    return 0
}

limit_clash() {
    if [ -z "${cgroup_memory_limit}" ]; then
        return
    fi

    if [ -z "${cgroup_memory_path}" ]; then
        cgroup_memory_path=$(mount | grep cgroup | awk '/memory/{print $3}' | head -1)
        if [ -z "${cgroup_memory_path}" ]; then
            log "err: 自动获取cgroup内存路径失败"
            return
        fi
    fi

    mkdir -p "${cgroup_memory_path}/clash" || {
        log "err: 无法创建cgroup目录"
        return
    }

    echo "$(cat ${clash_pid_file})" > "${cgroup_memory_path}/clash/cgroup.procs" && \
    echo "${cgroup_memory_limit}" > "${cgroup_memory_path}/clash/memory.limit_in_bytes" && \
    log "info: 已限制内存为: ${cgroup_memory_limit}"

    local applied_limit=$(cat "${cgroup_memory_path}/clash/memory.limit_in_bytes")
    if [ "${applied_limit}" != "${cgroup_memory_limit}" ]; then
        log "warn: 内存限制设置未生效 (预期: ${cgroup_memory_limit}, 实际: ${applied_limit})"
    fi
}

while getopts ":kfmpusl" option; do
    case "${option}" in
        u) update_pre ;;
        s) reload_config ;;
        k) keep_dns ;;
        f) find_packages_uid ;;
        m) monitor_local_ipv4 ;;
        p) port_detection ;;
        l) limit_clash ;;
        ?) log "warn: 无效选项: -${OPTARG}" ;;
    esac
done

exit 0