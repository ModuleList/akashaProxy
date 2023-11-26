#!/system/bin/sh
Clash_data_dir="/data/clash"

rm_data() {
    rm -rf ${Clash_data_dir}
    rm -rf ${Clash_data_dir}.old
}

rm_data