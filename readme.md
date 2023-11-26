
**Clash configuration issues affect 99% of your experience using this module**

**Please make good use of clash logs and search engines**

## Module path:

**Work path: /data/clash/""
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
```

clashMeta Tutorial:
https://wiki.metacubex.one
https://clash-meta.wiki

clash Tutorial:
https://github.com/Dreamacro/clash/wiki/Configuration#introduction

## build

run `make` Compile and package the magisk module
```
make
```