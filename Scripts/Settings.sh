#!/bin/bash
# 固件个性化设置

WRT_PATH="$GITHUB_WORKSPACE/wrt"

# 修改固件版本签名
sed -i "s#_('Firmware Version'), (L\\.isObject(boardinfo\\.release) ? boardinfo\\.release\\.description + ' / ' : '') + (luciversion || ''),# \\
_('Firmware Version'), \\
(L.isObject(boardinfo.release) ? boardinfo.release.description + ' / ' : '') + \\
'Built by SONG88 $(date \"+%Y-%m-%d\")',#" $WRT_PATH/feeds/luci/modules/luci-mod-status/htdocs/luci-static/resources/view/status/include/10_system.js

# 移除要替换的包（避免和 Packages.sh 里 clone 的版本冲突）
rm -rf $WRT_PATH/feeds/luci/applications/luci-app-argon-config
rm -rf $WRT_PATH/feeds/luci/applications/luci-app-appfilter
rm -rf $WRT_PATH/feeds/luci/themes/luci-theme-argon
rm -rf $WRT_PATH/feeds/packages/net/open-app-filter
rm -rf $WRT_PATH/feeds/packages/net/frp
rm -rf $WRT_PATH/feeds/packages/lang/golang

# 清理不需要的 feeds 包（减小编译体积）
rm -rf $WRT_PATH/feeds/luci/applications/luci-app-ssr-plus
rm -rf $WRT_PATH/feeds/packages/net/{adguardhome,dns2tcp,dnstap,dpdk,haproxy,mwan3,ndppd,netcat,nginx,pcap-dnsproxy,pdnsd,redsocks,stubby}
