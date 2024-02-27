## akashaProxy

**Clash configuration issues affect 99% of your experience using this module**

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
/data/clash/clash.service -s && /data/clash/clash.iptables -s
```

stop:
```
/data/clash/clash.service -k && /data/clash/clash.iptables -k
```

You can also use [dashboard](https://t.me/MagiskChangeKing)

## build

run `make` Compile and package the magisk module
```
make
```
