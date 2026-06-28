# OpenWrt CI - VIKINGYFY 6.18 Kernel

基于 [VIKINGYFY/immortalwrt](https://github.com/VIKINGYFY/immortalwrt) (6.18 内核) 编译 JDCloud RE-CS-02 固件。

## 特性

- 全功能 NSS 加速
- 6.18 内核
- Aurora 主题
- OpenClash 代理
- athena-led LED 控制

## 配置文件

| 文件 | 说明 |
|------|------|
| `Config/IPQ60XX-JDCLOUD.txt` | JDCloud 设备选择 |
| `Config/GENERAL.txt` | 通用软件包和内核模块配置 |

## 脚本

| 文件 | 说明 |
|------|------|
| `Scripts/Packages.sh` | 第三方软件包下载和更新 |
| `Scripts/Handles.sh` | 软件包修复和补丁 |
| `Scripts/Settings.sh` | 固件个性化设置 |

## 编译

手动触发 GitHub Actions 即可。
