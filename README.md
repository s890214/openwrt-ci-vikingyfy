# OpenWrt CI - VIKINGYFY 6.18 Kernel

基于 [VIKINGYFY/OpenWRT-CI](https://github.com/VIKINGYFY/OpenWRT-CI) 修改，使用 [VIKINGYFY/immortalwrt](https://github.com/VIKINGYFY/immortalwrt) (6.18 内核) 编译 JDCloud RE-CS-02 专用固件。

## 特性

- 全功能 NSS 硬件加速 (12.5)
- 6.18 内核
- Argon 主题（默认）
- OpenClash 代理 + clash_meta 内核
- luci-app-lucky （端口转发/DDNS/WebHook）
- luci-app-bandix （网络速度测试）
- athena-led LED 控制
- zram-swap 内存压缩

## 配置文件

| 文件 | 说明 |
|------|------|
| `Config/IPQ60XX-JDCLOUD.txt` | JDCloud 设备选择 |
| `Config/GENERAL.txt` | 通用软件包和内核模块配置 |

## 脚本说明

| 文件 | 说明 |
|------|------|
| `Scripts/Packages.sh` | 第三方软件包下载、更新和清理（OpenClash、lucky、bandix 等） |
| `Scripts/Settings.sh` | 固件个性化设置（固件版本签名、默认IP、默认主题 argon、WiFi 配置） |
| `Scripts/Handles.sh` | 软件包修复和补丁 |
| `Scripts/992_set-wifi-uci.sh` | WiFi 首次启动自动配置脚本 |

## 编译

手动触发 GitHub Actions Workflow `IPQ60XX-JDCLOUD-6.18` 即可。

支持两种上传方式：
- **release**（默认）：上传到 GitHub Release，可直接下载 .bin 文件
- **artifact**：上传到 Actions 构建产物

## 固件信息

- 默认 IP：`192.168.1.1`
- 默认密码：无
- WiFi 名称：`XIAOMI-SONG` / `XIAOMI5G-SONG`
- 源码：`VIKINGYFY/immortalwrt` (main 分支)
- 内核：6.18

## 注意事项

- 修改配置文件后需重新编译
- 切换内核版本（6.12↔6.18）需要不同的 NSS 固件版本，不可混用
