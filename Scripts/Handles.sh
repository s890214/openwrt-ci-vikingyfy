#!/bin/bash
# 基于 VIKINGYFY/OpenWRT-CI 的 Handles.sh

PKG_PATH="$GITHUB_WORKSPACE/wrt/package/"

# 预置 HomeProxy 数据
if [ -d *"homeproxy"* ]; then
	echo " "

	HP_RULE="surge"
	HP_PATH="homeproxy/root/etc/homeproxy"

	rm -rf ./$HP_PATH/resources/*

	git clone -q --depth=1 --single-branch --branch "release" "https://github.com/Loyalsoldier/surge-rules.git" ./$HP_RULE/
	cd ./$HP_RULE/ && RES_VER=$(git log -1 --pretty=format:'%s' | grep -o "[0-9]*")

	echo $RES_VER | tee china_ip4.ver china_ip6.ver china_list.ver gfw_list.ver
	awk -F, '/^IP-CIDR,/{print $2 > "china_ip4.txt"} /^IP-CIDR6,/{print $2 > "china_ip6.txt"}' cncidr.txt
	sed 's/^\.//g' direct.txt > china_list.txt ; sed 's/^\.//g' gfw.txt > gfw_list.txt
	mv -f ./{china_*,gfw_list}.{ver,txt} ../$HP_PATH/resources/

	cd .. && rm -rf ./$HP_RULE/

	cd $PKG_PATH && echo "homeproxy date has been updated!"
fi

# 修改 argon 主题字体和颜色
if [ -d *"luci-theme-argon"* ]; then
	echo " " && cd ./luci-theme-argon/

	sed -i "s/primary '.*'/primary '#31a1a1'/; s/'0.2'/'0.5'/; s/'none'/'bing'/; s/'600'/'normal'/" ./luci-app-argon-config/root/etc/config/argon

	cd $PKG_PATH && echo "theme-argon has been fixed!"
fi

# 修改 aurora 菜单式样
if [ -d *"luci-app-aurora-config"* ]; then
	echo " " && cd ./luci-app-aurora-config/

	sed -i "s/nav_type '.*'/nav_type 'dropdown'/g" $(find ./root/usr/share/aurora/ -type f -name "*.template")

	cd $PKG_PATH && echo "theme-aurora has been fixed!"
fi

# 修改 mini-diskmanager 菜单位置（如果有的话）
if [ -d *"luci-app-mini-diskmanager"* ]; then
	echo " " && cd ./luci-app-mini-diskmanager/

	sed -i "s/services/system/g" ./luci-app-mini-diskmanager/root/usr/share/luci/menu.d/luci-app-mini-diskmanager.json

	cd $PKG_PATH && echo "mini-diskmanager has been fixed!"
fi

# 修复 TailScale 配置文件冲突
TS_FILE=$(find ../feeds/packages/ -maxdepth 3 -type f -wholename "*/tailscale/Makefile")
if [ -f "$TS_FILE" ]; then
	echo " "

	sed -i '/\/files/d' $TS_FILE

	cd $PKG_PATH && echo "tailscale has been fixed!"
fi

# 修复 Rust 编译失败
RUST_FILE=$(find ../feeds/packages/ -maxdepth 3 -type f -wholename "*/rust/Makefile")
if [ -f "$RUST_FILE" ]; then
	echo " "

	sed -i 's/ci-llvm=true/ci-llvm=false/g' $RUST_FILE

	cd $PKG_PATH && echo "rust has been fixed!"
fi

# NSS ECM 流量统计修复
echo "-------------------------------------------------------"
echo "正在执行 NSS 流量统计修复..."

ECM_FILE_LIST=$(find $GITHUB_WORKSPACE/wrt/ -name Makefile | grep "/qca-nss-ecm/Makefile")
if [ -z "$ECM_FILE_LIST" ]; then
	echo "警告：未找到任何 qca-nss-ecm/Makefile 文件，跳过修正！"
else
	echo "$ECM_FILE_LIST" | while read -r ecm_makefile; do
		[ -z "$ecm_makefile" ] && continue

		if grep -q "ECM_NON_PORTED_TOOLS_SUPPORT" "$ecm_makefile"; then
			echo "  -> [跳过] $ecm_makefile 已包含统计宏。"
		else
			echo "  -> [修正] $ecm_makefile"
			sed -i 's/EXTRA_CFLAGS+=/EXTRA_CFLAGS+= -DECM_NON_PORTED_TOOLS_SUPPORT -DECM_STATE_OUTPUT_ENABLE -DECM_DB_CONNECTION_CROSS_REFERENCING_ENABLE -DECM_INTERFACE_VLAN_ENABLE -DECM_INTERFACE_SIT_ENABLE -DECM_INTERFACE_TUNIPIP6_ENABLE /g' "$ecm_makefile"
			echo "     确认: 宏注入完成。"
		fi
	done
fi
echo "-------------------------------------------------------"
