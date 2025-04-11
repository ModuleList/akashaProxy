#!/system/bin/sh

until [ "$(getprop init.svc.bootanim)" = "stopped" ]; do
    sleep 5
done

if [[ $(magisk -v | grep "delta") ]] || [[ $(magisk -v | grep "kitsune") ]]; then
    echo "" > remove
    exit 1
fi

service_path="$(realpath "$0")"
module_dir="$(dirname "$service_path")"
clash_data_dir="/data/clash"
scripts_dir="${clash_data_dir}/scripts"
clash_run_path="${clash_data_dir}/run"
clash_pid_file="${clash_run_path}/clash.pid"

. /data/clash/clash.config

if [ -f "${clash_pid_file}" ]; then
    rm -rf "${clash_pid_file}"
fi

crond -c "${clash_run_path}"
chmod -R 6755 "${clash_data_dir}/clashkernel"

if [ "${self_start}" = "true" ]; then
    nohup "${scripts_dir}/clash.service" -s &
    "${scripts_dir}/clash.iptables" -s
fi