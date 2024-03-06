NAME=akashaProxy
BUILDTIME=$(shell date -u)
BRANCH=$(shell cd Clash.Meta && git branch --show-current)
ifeq ($(BRANCH),Alpha)
VERSION=alpha-$(shell cd Clash.Meta && git rev-parse --short HEAD)
else ifeq ($(BRANCH),Beta)
VERSION=beta-$(shell cd Clash.Meta && git rev-parse --short HEAD)
else ifeq ($(BRANCH),)
VERSION=$(shell cd Clash.Meta && git describe --tags)
else
VERSION=$(shell cd Clash.Meta && git rev-parse --short HEAD)
endif
CC ?= clang
BUILD=CGO_ENABLED=0 CC=$(CC) go build -tags with_gvisor -trimpath -ldflags '-X "github.com/metacubex/mihomo/constant.Version=$(VERSION)" \
		-X "github.com/metacubex/mihomo/constant.BuildTime=$(BUILDTIME)" \
		-w -s -buildid='

all: default \
	build-webui pack

pack:
	echo "id=Clash_For_Magisk\nname=akashaProxy\nversion="$(shell TZ=Asia/Shanghai date "+%Y%m%d%H%M%S")"-"$(shell git rev-parse --short HEAD)"\nversionCode="$(shell TZ=Asia/Shanghai date "+%Y%m%d%H%M%S")"\nauthor=heinu\ndescription=akasha terminal transparent proxy module that supports tproxy and tun and adds many easy-to-use features. Compatible with Magisk/KernelSU">module/module.prop
	cd module && zip -r ../$(NAME).zip *

default:
	cd Clash.Meta && $(BUILD) -o ../module/bin/clashMeta-android-$@
	cd module/bin && tar -vcjf clashMeta-android-$@.tar.bz2 clashMeta-android-$@
	rm -rf ./module/bin/clashMeta-android-$@
	build-webui pack

build-webui:
	cd webui && yarn --frozen-lockfile && yarn build
	mv -f ./webui/out ./module/webroot

clean-cache-build:
	rm -rf ./module/bin
	rm -rf ./module/module.prop
	rm -rf $(NAME).zip

clean-cache-webui:
	rm -rf ./webui/node_modules
	rm -rf ./module/webroot

clean: clean-cache-build clean-cache-webui