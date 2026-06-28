#!/bin/bash
# 软件包下载和更新

# 智能更新：先删 feeds 里的旧版，再 clone 新版，避免冲突
UPDATE_PACKAGE() {
	local PKG_NAME=$1
	local PKG_REPO=$2
	local PKG_BRANCH=$3
	local PKG_SPECIAL=$4
	local PKG_LIST=("$PKG_NAME" $5)
	local REPO_NAME=${PKG_REPO#*/}

	echo " "

	for NAME in "${PKG_LIST[@]}"; do
		echo "Search directory: $NAME"
		local FOUND_DIRS=$(find ../feeds/luci/ ../feeds/packages/ -maxdepth 3 -type d -iname "*$NAME*" 2>/dev/null)
		if [ -n "$FOUND_DIRS" ]; then
			while read -r DIR; do
				rm -rf "$DIR"
				echo "Delete directory: $DIR"
			done <<< "$FOUND_DIRS"
		else
			echo "Not found directory: $NAME"
		fi
	done

	git clone --depth=1 --single-branch --branch $PKG_BRANCH "https://github.com/$PKG_REPO.git"

	if [[ "$PKG_SPECIAL" == "pkg" ]]; then
		find ./$REPO_NAME/*/ -maxdepth 3 -type d -iname "*$PKG_NAME*" -prune -exec cp -rf {} ./ \;
		rm -rf ./$REPO_NAME/
	elif [[ "$PKG_SPECIAL" == "name" ]]; then
		mv -f $REPO_NAME $PKG_NAME
	fi
}

# ============ 主题 ============
UPDATE_PACKAGE "argon" "jerrykuku/luci-theme-argon" "master"
UPDATE_PACKAGE "luci-app-argon-config" "jerrykuku/luci-app-argon-config" "master"
UPDATE_PACKAGE "aurora" "eamonxg/luci-theme-aurora" "master"
UPDATE_PACKAGE "aurora-config" "eamonxg/luci-app-aurora-config" "master"

# ============ golang (laipeng668 源) ============
rm -rf ../feeds/packages/lang/golang
git clone --depth=1 -b master --single-branch --filter=blob:none --sparse https://github.com/laipeng668/packages.git /tmp/laipeng-golang
cd /tmp/laipeng-golang && git sparse-checkout set lang/golang
mv -f lang/golang $GITHUB_WORKSPACE/wrt/feeds/packages/lang/golang
cd $GITHUB_WORKSPACE/wrt/package/ && rm -rf /tmp/laipeng-golang

# ============ 你的软件 ============
# Lucky 多功能
git clone --depth=1 https://github.com/gdy666/luci-app-lucky package/luci-app-lucky

# 集客无线AC控制器
git clone --depth=1 https://github.com/laipeng668/luci-app-gecoosac package/luci-app-gecoosac

# 带宽监控
git clone --depth=1 https://github.com/timsaya/openwrt-bandix package/openwrt-bandix
git clone --depth=1 https://github.com/timsaya/luci-app-bandix package/luci-app-bandix

# athena-led: VIKINGYFY 源码自带 package/emortal/luci-app-athena-led，无需 clone

# ============ OpenClash ============
# 移除 feeds 自带的旧版核心库
rm -rf ../feeds/packages/net/{xray-core,v2ray-geodata,sing-box,chinadns-ng,dns2socks,hysteria,ipt2socks,microsocks,naiveproxy,shadowsocks-libev,shadowsocks-rust,shadowsocksr-libev,simple-obfs,tcping,trojan-plus,tuic-client,v2ray-plugin,xray-plugin,geoview,shadow-tls}
rm -rf ../feeds/luci/applications/luci-app-openclash
git clone --depth=1 https://github.com/vernesong/OpenClash package/luci-app-openclash

# 下载 clash_meta 核心
echo "更新 clash_meta ..."
mkdir -p $GITHUB_WORKSPACE/wrt/files/etc/openclash/core
CLASH_META_URL="https://raw.githubusercontent.com/vernesong/OpenClash/core/master/meta/clash-linux-arm64.tar.gz"
wget -qO- $CLASH_META_URL | tar xOvz > $GITHUB_WORKSPACE/wrt/files/etc/openclash/core/clash_meta
chmod +x $GITHUB_WORKSPACE/wrt/files/etc/openclash/core/clash*
