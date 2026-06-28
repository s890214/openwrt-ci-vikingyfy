#!/bin/bash
# 基于 VIKINGYFY/OpenWRT-CI 的 Settings.sh

WRT_PATH="$GITHUB_WORKSPACE/wrt"

# 修改默认IP
# sed -i 's/192.168.1.1/192.168.2.1/g' $WRT_PATH/package/base-files/files/bin/config_generate

# 修改主机名
# sed -i "s/hostname='.*'/hostname='Roc'/g" $WRT_PATH/package/base-files/files/bin/config_generate

# 修改固件版本签名
sed -i "s#_('Firmware Version'), (L\\.isObject(boardinfo\\.release) ? boardinfo\\.release\\.description + ' / ' : '') + (luciversion || ''),# \\
_('Firmware Version'), \\
(L.isObject(boardinfo.release) ? boardinfo.release.description + ' / ' : '') + \\
'Built by SONG88 $(date \"+%Y-%m-%d\")',#" $WRT_PATH/feeds/luci/modules/luci-mod-status/htdocs/luci-static/resources/view/status/include/10_system.js

# 修改默认主题
sed -i "s/mediaurlimg\/iphone\/background.jpg/mediaurlimg\/iphone\/dark.jpg/g" $(find $WRT_PATH/feeds/luci/ -maxdepth 5 -type f -wholename "*/luci-theme-argon/htdocs/luci-static/resources/view/system/system.js")

# 修改默认 WiFi 设置
if [ -f $WRT_PATH/package/kernel/mac80211/files/lib/wifi/mac80211.sh ]; then
	sed -i "/wifi-iface\[0\]/,/}/ s/option ssid.*/option ssid '$WRT_SSID'/g; /wifi-iface\[0\]/,/}/ s/option encryption.*/option encryption 'psk2'/g; /wifi-iface\[0\]/,/}/ s/option key.*/option key '$WRT_WORD'/g" $WRT_PATH/package/kernel/mac80211/files/lib/wifi/mac80211.sh
fi

# 修改默认密码
if [ -f $WRT_PATH/package/base-files/files/etc/shadow ]; then
	sed -i "s/root:.*/root::0:0:99999:7:::/g" $WRT_PATH/package/base-files/files/etc/shadow
fi

# 移除要替换的包（避免和 Packages.sh 里 clone 的版本冲突）
rm -rf $WRT_PATH/feeds/luci/applications/luci-app-argon-config
rm -rf $WRT_PATH/feeds/luci/applications/luci-app-wechatpush
rm -rf $WRT_PATH/feeds/luci/applications/luci-app-appfilter
rm -rf $WRT_PATH/feeds/luci/themes/luci-theme-argon
rm -rf $WRT_PATH/feeds/packages/net/open-app-filter
rm -rf $WRT_PATH/feeds/packages/net/ariang
rm -rf $WRT_PATH/feeds/packages/net/frp
rm -rf $WRT_PATH/feeds/packages/lang/golang

# 清理冗余文件
rm -rf $WRT_PATH/feeds/luci/applications/luci-app-ssr-plus
rm -rf $WRT_PATH/feeds/luci/applications/luci-app-homeproxy
rm -rf $WRT_PATH/feeds/packages/net/{adguardhome,dns2tcp,dnstap,dpdk,haproxy,mwan3,ndppd,netcat,nginx,pcap-dnsproxy,pdnsd,redsocks,shadowsocks-libev,shadowsocks-rust,shadowsocksr-libev,simple-obfs,stubby,tcping,trojan-plus,v2ray-core,v2ray-plugin,xray-core,xray-plugin}
