#!/bin/bash
# 固件个性化设置

WRT_PATH="$GITHUB_WORKSPACE/wrt"

# 修改固件版本签名
sed -i "s#_('Firmware Version'), (L\\.isObject(boardinfo\\.release) ? boardinfo\\.release\\.description + ' / ' : '') + (luciversion || ''),# \\
_('Firmware Version'), \\
(L.isObject(boardinfo.release) ? boardinfo.release.description + ' / ' : '') + \\
'Built by SONG88 $(date \"+%Y-%m-%d\")',#" $WRT_PATH/feeds/luci/modules/luci-mod-status/htdocs/luci-static/resources/view/status/include/10_system.js

# 修改默认IP（保持默认主机名 ImmortalWRT）
CFG_FILE="$WRT_PATH/package/base-files/files/bin/config_generate"
sed -i "s/192\.168\.[0-9]*\.[0-9]*/$WRT_IP/g" $CFG_FILE

# 安装 WiFi uci-defaults 脚本（首次启动自动配置，已配置过不覆盖）
install -Dm544 $GITHUB_WORKSPACE/Scripts/992_set-wifi-uci.sh $WRT_PATH/package/base-files/files/etc/uci-defaults/992_set-wifi-uci.sh

# 移除要替换的包（避免和 Packages.sh 里 clone 的版本冲突）
rm -rf $WRT_PATH/feeds/luci/applications/luci-app-argon-config
rm -rf $WRT_PATH/feeds/luci/applications/luci-app-appfilter
rm -rf $WRT_PATH/feeds/luci/themes/luci-theme-argon
rm -rf $WRT_PATH/feeds/packages/net/open-app-filter
rm -rf $WRT_PATH/feeds/packages/net/frp

# 清理冗余文件
rm -rf $WRT_PATH/feeds/luci/applications/luci-app-ssr-plus
rm -rf $WRT_PATH/feeds/packages/net/{adguardhome,dns2tcp,dnstap,dpdk,haproxy,mwan3,ndppd,netcat,nginx,pcap-dnsproxy,pdnsd,redsocks,stubby}
