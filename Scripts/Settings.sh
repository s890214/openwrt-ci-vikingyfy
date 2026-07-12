#!/bin/bash
# 固件个性化设置

WRT_PATH="$GITHUB_WORKSPACE/wrt"

# 修改固件版本签名
sed -i "s#_('Firmware Version'), (L\\.isObject(boardinfo\\.release) ? boardinfo\\.release\\.description + ' / ' : '') + (luciversion || ''),# \\
_('Firmware Version'), \\
(L.isObject(boardinfo.release) ? boardinfo.release.description + ' / ' : '') + \\
'Built by SONG88 $(date "+%Y-%m-%d")',#" $WRT_PATH/feeds/luci/modules/luci-mod-status/htdocs/luci-static/resources/view/status/include/10_system.js

# 修改默认IP（保持默认主机名 ImmortalWRT）
CFG_FILE="$WRT_PATH/package/base-files/files/bin/config_generate"
sed -i "s/192\\.168\\.[0-9]*\\.[0-9]*/$WRT_IP/g" $CFG_FILE

# 设置默认主题为 argon
sed -i "s/luci-theme-bootstrap/luci-theme-argon/g" $(find $WRT_PATH/feeds/luci/collections/ -type f -name "Makefile")
# 删除 aurora 的 uci-defaults（防止被 feed 依赖拉进来覆盖 argon 设置）
rm -f $WRT_PATH/package/base-files/files/etc/uci-defaults/30_luci-theme-aurora

# 修复 argon 主题 brand 文字换行（TypoGraphica 字体在窄侧边栏会折行）
sed -i 's/font-size: 1\.8rem/font-size: 1.2rem; white-space: nowrap/' \
  $(find $WRT_PATH/package/luci-theme-argon $WRT_PATH/feeds/luci/themes/luci-theme-argon \
    -name "cascade.css" 2>/dev/null | head -1)

# 安装 WiFi uci-defaults 脚本（首次启动自动配置，已配置过不覆盖）
install -Dm544 $GITHUB_WORKSPACE/Scripts/992_set-wifi-uci.sh $WRT_PATH/package/base-files/files/etc/uci-defaults/992_set-wifi-uci.sh
