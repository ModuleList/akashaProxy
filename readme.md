## akashaProxy

[中文](./readme_zh.md) | English


akashaProxy is a Magisk/KernelSU module derived from ~~mihomo~~clashMeta

The name comes from the AkashaSystem of [clashMeta documentation](https://wiki.metacubex.one) modified
---

**99% of the problems in this module basically come from the clash configuration error or the plug-in configuration error**

**Please make good use of clash logs and search engines**

## Module path:

**Work path: /data/clash/**

`clash.config` : Module start config

`clash.yaml` : Clash config(global configuration and dns configuration)

`config.yaml` : Clash config(other)

`packages.list` : proxy black/white list packages list

Admin panel: 127.0.0.1:9090/ui (default)


```
├── adguard
│   ├── AdGuardHome // AdGuardHome bin
├── clash.config
├── clash.yaml
├── clashkernel
│   ├── clashMeta //clash kernel
├── config.yaml
├── packages.list
├── mosdns
│   ├── mosdns // mosdns bin
├── scripts // clash start script
│   ├── clash.inotify
│   ├── clash.iptables
│   ├── clash.service
│   └── clash.tool 
├── yacd
│   ├── //yacd-Meta page
└── DeleteCache.sh
```

clashMeta Tutorial:
https://wiki.metacubex.one
https://clash-meta.wiki

## start and stop

start:
```
/data/clash/script/clash.service -s && /data/clash/script/clash.iptables -s
```

stop:
```
/data/clash/script/clash.service -k && /data/clash/script/clash.iptables -k
```

You can also use [dashboard](https://t.me/MagiskChangeKing)

## build

run `make` Compile and package the module
```
make
```
> The armeabi-v7a architecture and arm64-v8a architecture are built by default under the android platform.