## akashaProxy

中文 | [English](./readme.md)


akashaProxy 是 ~~mihomo~~clashMeta 衍生的Magisk/KernelSU模块

名字来源于[clashMeta文档](https://wiki.metacubex.one)的虚空终端修改而来

~~中文名应该叫`虚空代理`~~

---

**此模块99%的问题基本上都来自clash配置错误或插件配置错误**

**请善用搜索引擎和日志**

## 模块路径：

**工作路径：/data/clash/**

`clash.config` : 模块启动配置

`clash.yaml` : Clash 配置（全局配置和 dns 配置）

`config.yaml` ：clash配置（其他）

`packages.list` : 进行代理的黑/白名单列表

yacd管理面板：127.0.0.1:9090/ui（默认）

```
├── adguard // AdGuardHome插件核心目录
│   ├── AdGuardHome
├── clashkernel //模块核心目录
│   ├── clashMeta 
├── scripts // 模块启动脚本
│   ├── clash.inotify
│   ├── clash.iptables
│   ├── clash.service
│   └── clash.tool
├── tools
│   ├── DeleteCache.sh // 清除Google系app等缓存
│   ├── DownloadAdGuardHome.sh // 下载安装AdGuardHome插件
│   ├── reload.sh // 重载配置
│   ├── start.sh // 启动模块
│   └── stop.sh // 停止模块
├── yacd
│   ├── // yacd-Meta面板源码
├── run
│   ├── // 模块运行目录
├── bin
│   ├── // 模块内部工具目录
├── GeoSite.dat
├── GeoIP.dat
├── clash.config
├── clash.yaml
├── config.yaml
└── packages.list
```

clash教程：
https://wiki.metacubex.one
https://clash-meta.wiki

## 启动和停止

开始：
````
/data/clash/script/clash.service -s && /data/clash/script/clash.iptables -s
````

停止：
````
/data/clash/script/clash.service -k && /data/clash/script/clash.iptables -k
````

您还可以使用[dashboard](https://t.me/MagiskChangeKing)管理启停

## 编译

执行 `make` 编译并打包模块
````
make
````
> 默认构建android平台下armeabi-v7a架构和arm64-v8a架构

## 发布

[Telegram](https://t.me/akashaProxy)
[Github工作流(需要解压)](https://github.com/ModuleList/akashaProxy/actions)
