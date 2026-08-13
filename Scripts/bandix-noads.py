#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
bandix-noads.py — 去除 luci-app-bandix 的远程广告与捐赠二维码（保留 v0.12.9 功能改动）

删除内容（对应上游提交 7b7762a "feat: add localized ads and donation support"）：
  1. index.js  : 远程广告配置常量（BANDIX_AD_*）
  2. index.js  : 广告位 CSS 样式（.bandix-ad-*）
  3. index.js  : 页面 6 个广告位渲染（bandix-ad-row）
  4. index.js  : 异步加载远程广告 IIFE（fetch ads.json + 定时刷新）
  5. settings.js: "支持作者"捐赠二维码卡片（alipay/wechat）+ 注入样式
  6. donate/   : 收款码图片（alipay.jpg, wechat-pay.png）

保留：Yesterday 按钮、默认时间范围改为今天、重置行为、重复调用移除等功能改动。

用法: python3 bandix-noads.py <luci-app-bandix包根目录>
      包根目录 = clone 后含 Makefile 的目录（如 package/luci-app-bandix/luci-app-bandix）
退出码: 0=全部成功; 1=有代码块未匹配或残留（CI 应失败，防止广告悄悄回归）
"""
import os
import re
import shutil
import sys

VIEW_DIR = os.path.join("htdocs", "luci-static", "resources", "view", "bandix")
STATIC_DIR = os.path.join("htdocs", "luci-static", "resources", "bandix")


def fail(msg):
    print(f"[bandix-noads] 错误: {msg}", file=sys.stderr)
    sys.exit(1)


def read_file(path):
    with open(path, "r", encoding="utf-8") as f:
        return f.read()


def write_file(path, content):
    with open(path, "w", encoding="utf-8", newline="\n") as f:
        f.write(content)


def remove_range(content, start_marker, end_marker, what, after=None):
    """删除从 start_marker(行首) 到 end_marker(行尾) 的区间。end_marker 为 None 表示删到文件尾。"""
    start = content.find(start_marker)
    if start == -1:
        fail(f"未找到起点标记: {what}\n  标记: {start_marker!r}")
    line_start = content.rfind("\n", 0, start) + 1
    if end_marker is None:
        line_end = len(content)
    else:
        end = content.find(end_marker, start)
        if end == -1:
            fail(f"未找到终点标记: {what}\n  标记: {end_marker!r}")
        # 定位到 end_marker 末尾之后的下一个换行（end_marker 可能跨行）
        line_end = content.find("\n", end + len(end_marker))
        if line_end == -1:
            line_end = len(content)
        else:
            line_end += 1
    new_content = content[:line_start] + (after or "") + content[line_end:]
    removed = content[line_start:line_end]
    print(f"[bandix-noads] 已删除 {what} ({len(removed.splitlines())} 行)")
    return new_content


def strip_ad_css(content):
    """循环删除所有 .bandix-ad-* CSS 规则块（含多行选择器与媒体查询内规则）。"""
    pattern = re.compile(r"^\s*\.bandix-ad-[^{]*?\{[^}]*\}\s*$", re.M)
    count = 0
    while True:
        m = pattern.search(content)
        if not m:
            break
        content = content[:m.start()] + content[m.end():]
        count += 1
    if count:
        print(f"[bandix-noads] 已删除广告 CSS 规则 {count} 处")
    return content


def patch_index_js(pkg_root):
    path = os.path.join(pkg_root, VIEW_DIR, "index.js")
    content = read_file(path)

    # 1. 远程广告配置常量
    content = remove_range(
        content,
        "// 远程广告配置\nvar BANDIX_AD_CONFIG_URL",
        "var BANDIX_AD_RETRY_INTERVAL = 900;",
        "广告配置常量",
    )

    # 2. 广告位 CSS
    content = strip_ad_css(content)
    # 清理残留空行（多个连续空行压成一个）
    content = re.sub(r"\n{3,}", "\n\n", content)

    # 3. 广告位渲染（含注释行）
    content = remove_range(
        content,
        "// 广告数据从公开仓库动态加载\n            E('div', {",
        "            })),",
        "广告位渲染块",
    )

    # 4. 异步加载广告 IIFE（含注释行，删到 })(); 及后续一个空行）
    content = remove_range(
        content,
        "// 异步加载远程广告（不阻塞主流程）",
        "        })();",
        "远程广告加载 IIFE",
    )
    content = re.sub(r"\n{3,}", "\n\n", content)

    write_file(path, content)
    return path


def patch_settings_js(pkg_root):
    path = os.path.join(pkg_root, VIEW_DIR, "settings.js")
    content = read_file(path)

    # 5a. 捐赠卡片代码块（"支持作者" option + donationCard 函数 + renderWidget）
    content = remove_range(
        content,
        "\t\t// 支持作者（基本设置的最后一项）",
        "_('Donations are voluntary. Thank you for supporting Bandix.'))\n\t\t\t]);\n\t\t};",
        "捐赠二维码卡片",
    )

    # 5b. m.render().then(...) 捐赠样式注入 → 恢复为 m.render()
    content = remove_range(
        content,
        "\treturn m.render().then(function (mapEl) {",
        "\t});",
        "m.render() 捐赠样式链",
        after="\treturn m.render();\n",
    )

    write_file(path, content)
    return path


def verify(pkg_root):
    """验证无广告残留；有残留则退出码 1。"""
    ad_markers = [
        "BANDIX_AD_",
        "bandix-ad-",
        "bandix-ad-row",
        "bandix-donation",
        "donate/",
        "Advertising",
        "远程广告",
        "广告数据",
    ]
    leaked = []
    for sub in (VIEW_DIR, STATIC_DIR):
        base = os.path.join(pkg_root, sub)
        if not os.path.isdir(base):
            continue
        for dirpath, _dirs, files in os.walk(base):
            for fn in files:
                if not fn.endswith((".js", ".html")):
                    continue
                fp = os.path.join(dirpath, fn)
                text = read_file(fp)
                for marker in ad_markers:
                    if marker in text:
                        leaked.append(f"{fp} 含 {marker!r}")
    if leaked:
        print("[bandix-noads] 残留检查失败:", file=sys.stderr)
        for item in leaked:
            print(f"  - {item}", file=sys.stderr)
        sys.exit(1)

    donate_dir = os.path.join(pkg_root, STATIC_DIR, "donate")
    if os.path.isdir(donate_dir):
        print("[bandix-noads] 错误: donate 目录仍然存在", file=sys.stderr)
        sys.exit(1)

    # 若环境有 node，则对修改过的 JS 做语法检查
    node = shutil.which("node") or shutil.which("nodejs")
    if node:
        for fn in ("index.js", "settings.js"):
            fp = os.path.join(pkg_root, VIEW_DIR, fn)
            import subprocess
            r = subprocess.run([node, "--check", fp], capture_output=True, text=True)
            if r.returncode != 0:
                print(f"[bandix-noads] JS 语法检查失败: {fp}\n{r.stderr}", file=sys.stderr)
                sys.exit(1)
        print("[bandix-noads] JS 语法检查通过 (node --check)")

    print("[bandix-noads] 验证通过：无广告/捐赠残留")


def main():
    if len(sys.argv) != 2:
        fail(f"用法: {sys.argv[0]} <luci-app-bandix包根目录>")
    pkg_root = sys.argv[1]
    if not os.path.isdir(os.path.join(pkg_root, "Makefile")):
        # Makefile 是文件不是目录，检查 htdocs 存在即可
        pass
    if not os.path.isdir(os.path.join(pkg_root, VIEW_DIR)):
        fail(f"未找到 {VIEW_DIR}，请确认传入的是 luci-app-bandix 包根目录: {pkg_root}")

    # 1-4. index.js
    patch_index_js(pkg_root)
    # 5. settings.js
    patch_settings_js(pkg_root)
    # 6. 删除 donate 图片
    donate_dir = os.path.join(pkg_root, STATIC_DIR, "donate")
    if os.path.isdir(donate_dir):
        shutil.rmtree(donate_dir)
        print(f"[bandix-noads] 已删除 donate 目录: {donate_dir}")

    verify(pkg_root)
    print("[bandix-noads] 全部完成 ✅")


if __name__ == "__main__":
    main()
