#!/bin/bash
# 软件包修复和补丁

PKG_PATH="$GITHUB_WORKSPACE/wrt/package/"

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
