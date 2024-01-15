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
CLANG ?= clang-14
CFLAGS := -O2 -g -Wall -Werror $(CFLAGS)
BUILD=CGO_ENABLED=0 go build -tags with_gvisor -trimpath -ldflags '-X "github.com/metacubex/mihomo/constant.Version=$(VERSION)" \
		-X "github.com/metacubex/mihomo/constant.BuildTime=$(BUILDTIME)" \
		-w -s -buildid='
CHAT_ID ?= 0
TELEGRAM_BOT_TOKEN ?= 0
all: android-arm64-v8a android-armeabi-v7a \
	pack

pack:
	echo "id=Clash_For_Magisk\nname=akashaProxy\nversion=v0.1-"$(shell git rev-parse --short HEAD)"\nversionCode="$(shell date '+%s')"\nauthor=heinu\ndescription=akasha terminal transparent proxy module that supports tproxy and tun and adds many easy-to-use features. Compatible with Magisk/KernelSU">module/module.prop
	bash build.sh
	cd module && zip -r ../$(NAME)-$(shell git rev-parse --short HEAD).zip *

android-arm64-v8a:
	GOOS=android GOARCH=arm64 cd Clash.Meta && $(BUILD) -o ../module/bin/clashMeta-$@
	cd module/bin && tar -vcjf clashMeta-$@.tar.bz2 clashMeta-$@
	rm -rf ./module/bin/clashMeta-$@


android-armeabi-v7a:
	GOOS=android GOARCH=arm cd Clash.Meta && $(BUILD) -o ../module/bin/clashMeta-$@
	cd module/bin && tar -vcjf clashMeta-$@.tar.bz2 clashMeta-$@
	rm -rf ./module/bin/clashMeta-$@


default:
	cd Clash.Meta && $(BUILD) -o ../module/bin/clashMeta-android-$@
	cd module/bin && tar -vcjf clashMeta-android-$@.tar.bz2 clashMeta-android-$@
	rm -rf ./module/bin/clashMeta-android-$@
	cd module && zip -r ../$(NAME)-$(shell git rev-parse --short HEAD).zip *


clean:
	rm -rf ./module/*.sha256
	rm -rf ./module/*/*.sha256
	rm -rf ./module/*/*/*.sha256
	rm -rf ./module/*/*/*/*.sha256
	rm -rf ./module/*/*/*/*/*.sha256
	rm -rf ./module/*/*/*/*/*/*.sha256
	rm -rf ./module/bin
	rm -rf ./module/module.prop
	rm -rf $(NAME)-$(shell git rev-parse --short HEAD).zip
