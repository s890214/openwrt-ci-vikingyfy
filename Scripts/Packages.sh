#!/bin/bash
# 基于 VIKINGYFY/OpenWRT-CI 的 Packages.sh 框架
# 保留你的软件源偏好 + VIKINGYFY 的 UPDATE_PACKAGE 智能更新机制

# 安装和更新软件包
UPDATE_PACKAGE() {
	local PKG_NAME=$1
	local PKG_REPO=$2
	local PKG_BRANCH=$3
	local PKG_SPECIAL=$4
	local PKG_LIST=("$PKG_NAME" $5)
	local REPO_NAME=${PKG_REPO#*/}

	echo " "

	# 删除本地可能存在的不同名称的软件包
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

	# 克隆 GitHub 仓库
	git clone --depth=1 --single-branch --branch $PKG_BRANCH "https://github.com/$PKG_REPO.git"

	# 处理克隆的仓库
	if [[ "$PKG_SPECIAL" == "pkg" ]]; then
		find ./$REPO_NAME/*/ -maxdepth 3 -type d -iname "*$PKG_NAME*" -prune -exec cp -rf {} ./ \;
		rm -rf ./$REPO_NAME/
	elif [[ "$PKG_SPECIAL" == "name" ]]; then
		mv -f $REPO_NAME $PKG_NAME
	fi
}

# 主题（用你习惯的 jerrykuku 版 argon，aurora 用 VIKINGYFY 的）
UPDATE_PACKAGE "argon" "jerrykuku/luci-theme-argon" "master"
UPDATE_PACKAGE "luci-app-argon-config" "jerrykuku/luci-app-argon-config" "master"
UPDATE_PACKAGE "aurora" "eamonxg/luci-theme-aurora" "master"
UPDATE_PACKAGE "aurora-config" "eamonxg/luci-app-aurora-config" "master"

# 代理（你的偏好：OpenClash + VIKINGYFY 的 homeproxy）
UPDATE_PACKAGE "homeproxy" "VIKINGYFY/homeproxy" "main"
UPDATE_PACKAGE "openclash" "vernesong/OpenClash" "dev" "pkg"

# 磁盘管理
UPDATE_PACKAGE "diskman" "sbwml/luci-app-diskman" "main"

# 你习惯的软件源（保留 laipeng668 的 frp/golang/ariang）
# frp
rm -rf ../feeds/packages/net/frp
git clone --depth=1 -b frp-binary-toml --single-branch --filter=blob:none --sparse https://github.com/laipeng668/packages.git /tmp/laipeng-frp
cd /tmp/laipeng-frp && git sparse-checkout set net/frp
mv -f net/frp $GITHUB_WORKSPACE/wrt/package/frp
cd $GITHUB_WORKSPACE/wrt/package/ && rm -rf /tmp/laipeng-frp

# golang
rm -rf ../feeds/packages/lang/golang
git clone --depth=1 -b master --single-branch --filter=blob:none --sparse https://github.com/laipeng668/packages.git /tmp/laipeng-golang
cd /tmp/laipeng-golang && git sparse-checkout set lang/golang
mv -f lang/golang $GITHUB_WORKSPACE/wrt/package/golang
cd $GITHUB_WORKSPACE/wrt/package/ && rm -rf /tmp/laipeng-golang

# ariang
git clone --depth=1 -b ariang --single-branch --filter=blob:none --sparse https://github.com/laipeng668/packages.git /tmp/laipeng-ariang
cd /tmp/laipeng-ariang && git sparse-checkout set net/ariang
mv -f net/ariang $GITHUB_WORKSPACE/wrt/package/ariang
cd $GITHUB_WORKSPACE/wrt/package/ && rm -rf /tmp/laipeng-ariang

# 你的其他软件
git clone --depth=1 https://github.com/sbwml/luci-app-openlist2 package/openlist2
git clone --depth=1 https://github.com/gdy666/luci-app-lucky package/luci-app-lucky
git clone --depth=1 https://github.com/tty228/luci-app-wechatpush package/luci-app-wechatpush
git clone --depth=1 https://github.com/destan19/OpenAppFilter.git package/OpenAppFilter
git clone --depth=1 https://github.com/laipeng668/luci-app-gecoosac package/luci-app-gecoosac
git clone --depth=1 https://github.com/timsaya/openwrt-bandix package/openwrt-bandix
git clone --depth=1 https://github.com/timsaya/luci-app-bandix package/luci-app-bandix

# athena-led: VIKINGYFY 源码自带 package/emortal/luci-app-athena-led
# 无需额外 clone

# OpenClash 核心库替换
rm -rf ../feeds/packages/net/{xray-core,v2ray-geodata,sing-box,chinadns-ng,dns2socks,hysteria,ipt2socks,microsocks,naiveproxy,shadowsocks-libev,shadowsocks-rust,shadowsocksr-libev,simple-obfs,tcping,trojan-plus,tuic-client,v2ray-plugin,xray-plugin,geoview,shadow-tls}
rm -rf ../feeds/luci/applications/luci-app-openclash
git clone --depth=1 https://github.com/vernesong/OpenClash package/luci-app-openclash

# 下载 clash_meta 核心
echo "更新 clash_meta ..."
mkdir -p $GITHUB_WORKSPACE/wrt/files/etc/openclash/core
CLASH_META_URL="https://raw.githubusercontent.com/vernesong/OpenClash/core/master/meta/clash-linux-arm64.tar.gz"
wget -qO- $CLASH_META_URL | tar xOvz > $GITHUB_WORKSPACE/wrt/files/etc/openclash/core/clash_meta
chmod +x $GITHUB_WORKSPACE/wrt/files/etc/openclash/core/clash*

# 更新 sing-box 版本
UPDATE_VERSION() {
	local PKG_NAME=$1
	local PKG_MARK=${2:-false}
	local PKG_FILES=$(find ./ ../feeds/packages/ -maxdepth 3 -type f -wholename "*/$PKG_NAME/Makefile")

	if [ -z "$PKG_FILES" ]; then
		echo "$PKG_NAME not found!"
		return
	fi

	echo -e "\n$PKG_NAME version update has started!"

	for PKG_FILE in $PKG_FILES; do
		local PKG_REPO=$(grep -Po "PKG_SOURCE_URL:=https://.*github.com/\K[^/]+/[^/]+(?=.*)" $PKG_FILE)
		local PKG_TAG=$(curl -sL "https://api.github.com/repos/$PKG_REPO/releases" | jq -r "map(select(.prerelease == $PKG_MARK)) | first | .tag_name")

		local OLD_VER=$(grep -Po "PKG_VERSION:=\K.*" "$PKG_FILE")
		local OLD_URL=$(grep -Po "PKG_SOURCE_URL:=\K.*" "$PKG_FILE")
		local OLD_FILE=$(grep -Po "PKG_SOURCE:=\K.*" "$PKG_FILE")
		local OLD_HASH=$(grep -Po "PKG_HASH:=\K.*" "$PKG_FILE")

		local PKG_URL=$([[ "$OLD_URL" == *"releases"* ]] && echo "${OLD_URL%/}/$OLD_FILE" || echo "${OLD_URL%/}")

		local NEW_VER=$(echo $PKG_TAG | sed -E 's/[^0-9]+/\./g; s/^\.|\.$//g')
		local NEW_URL=$(echo $PKG_URL | sed "s/\$(PKG_VERSION)/$NEW_VER/g; s/\$(PKG_NAME)/$PKG_NAME/g")
		local NEW_HASH=$(curl -sL "$NEW_URL" | sha256sum | cut -d ' ' -f 1)

		echo "old version: $OLD_VER $OLD_HASH"
		echo "new version: $NEW_VER $NEW_HASH"

		if [[ "$NEW_VER" =~ ^[0-9].* ]] && dpkg --compare-versions "$OLD_VER" lt "$NEW_VER"; then
			sed -i "s/PKG_VERSION:=.*/PKG_VERSION:=$NEW_VER/g" "$PKG_FILE"
			sed -i "s/PKG_HASH:=.*/PKG_HASH:=$NEW_HASH/g" "$PKG_FILE"
			echo "$PKG_FILE version has been updated!"
		else
			echo "$PKG_FILE version is already the latest!"
		fi
	done
}

UPDATE_VERSION "sing-box"
