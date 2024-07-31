##akashaProxy

English | [中文](./readme_zh.md)


akashaProxy is a Magisk/KernelSU module derived from ~~mihomo~~clashMeta

The name is modified from the void terminal of [clashMeta document](https://wiki.metacubex.one)

~~The Chinese name should be called `Void Agent`~~

---

**99% of the problems with this module basically come from clash configuration errors or plug-in configuration errors**

**Please make good use of search engines and logs**

## Configuration:

**Working path:/data/clash/**

`clash.config` : module startup configuration

`config.yaml.`:clash configuration file

`packages.list` : Black/white list for proxying

yacd management panel: 127.0.0.1:9090/ui (default)

>Rename config.yaml.example to config.yaml and fill in the configuration file, or use your own configuration file

clash tutorial:
https://wiki.metacubex.one
https://clash-meta.wiki

## Start and stop

start:
````
/data/clash/script/clash.service -s && /data/clash/script/clash.iptables -s
````

stop:
````
/data/clash/script/clash.service -k && /data/clash/script/clash.iptables -k
````

You can also use [dashboard](https://t.me/MagiskChangeKing) to manage startup and shutdown or KernelSU webUI control

## Compile

Execute `make` to compile and package the module
````
make
````
> The armeabi-v7a architecture and arm64-v8a architecture are built by default under the android platform

## Publish

[Telegram](https://t.me/akashaProxy)
[Github workflow (requires decompression)](https://github.com/ModuleList/akashaProxy/actions)
