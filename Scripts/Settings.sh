#!/bin/bash
# 基于 VIKINGYFY/OpenWRT-CI 的 Settings.sh

WRT_PATH="$GITHUB_WORKSPACE/wrt"

# 修改固件版本签名
sed -i "s#_('Firmware Version'), (L\\.isObject(boardinfo\\.release) ? boardinfo\\.release\\.description + ' / ' : '') + (luciversion || ''),# \\
_('Firmware Version'), \\
(L.isObject(boardinfo.release) ? boardinfo.release.description + ' / ' : '') + \\
'Built by SONG88 $(date \"+%Y-%m-%d\")',#" $WRT_PATH/feeds/luci/modules/luci-mod-status/htdocs/luci-static/resources/view/status/include/10_system.js

# 修改默认IP（保持默认主机名 ImmortalWRT）
CFG_FILE="$WRT_PATH/package/base-files/files/bin/config_generate"
sed -i "s/192\.168\.[0-9]*\.[0-9]*/$WRT_IP/g" $CFG_FILE

# 修改WiFi名称和密码（6.18内核用 mac80211.uc）
WIFI_SH=$(find $WRT_PATH/target/linux/qualcommax/base-files/etc/uci-defaults/ -type f -name "*set-wireless.sh" 2>/dev/null)
WIFI_UC="$WRT_PATH/package/network/config/wifi-scripts/files/lib/wifi/mac80211.uc"
if [ -f "$WIFI_SH" ]; then
	sed -i "s/BASE_SSID='.*'/BASE_SSID='$WRT_SSID'/g" $WIFI_SH
	sed -i "s/BASE_WORD='.*'/BASE_WORD='$WRT_WORD'/g" $WIFI_SH
elif [ -f "$WIFI_UC" ]; then
	sed -i "s/ssid='.*'/ssid='$WRT_SSID'/g" $WIFI_UC
	sed -i "s/key='.*'/key='$WRT_WORD'/g" $WIFI_UC
	sed -i "s/country='.*'/country='CN'/g" $WIFI_UC
	sed -i "s/encryption='.*'/encryption='psk2+ccmp'/g" $WIFI_UC
fi

# 移除要替换的包（避免和 Packages.sh 里 clone 的版本冲突）
rm -rf $WRT_PATH/feeds/luci/applications/luci-app-argon-config
rm -rf $WRT_PATH/feeds/luci/applications/luci-app-appfilter
rm -rf $WRT_PATH/feeds/luci/themes/luci-theme-argon
rm -rf $WRT_PATH/feeds/packages/net/open-app-filter
rm -rf $WRT_PATH/feeds/packages/net/frp
rm -rf $WRT_PATH/feeds/packages/lang/golang

# 清理冗余文件
rm -rf $WRT_PATH/feeds/luci/applications/luci-app-ssr-plus
rm -rf $WRT_PATH/feeds/packages/net/{adguardhome,dns2tcp,dnstap,dpdk,haproxy,mwan3,ndppd,netcat,nginx,pcap-dnsproxy,pdnsd,redsocks,stubby}
