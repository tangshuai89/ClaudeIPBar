# ClaudeIPBar

> macOS 桌面小组件，实时显示 Claude IP 报告的核心指标：默认 / Cloudflare 出口 IP、地理位置、ASN、ISP、Claude 服务状态。

[![Platform](https://img.shields.io/badge/macOS-14%2B-blue?logo=apple)](https://developer.apple.com/macos/)
[![Swift](https://img.shields.io/badge/Swift-5.9%2B-orange?logo=swift)](https://swift.org)
[![License](https://img.shields.io/badge/License-MIT-green)](LICENSE)
[![Xcode](https://img.shields.io/badge/Xcode-15%2B-1575F9?logo=xcode)](https://developer.apple.com/xcode/)

## 它能做什么

在 macOS 桌面右侧放一个小组件，每 30 分钟自动刷新（可调），实时显示：

- **默认出口 IP** —— 通过 `1.1.1.1/cdn-cgi/trace` 视角
- **Cloudflare 出口 IP** —— 通过 `claude.ai/cdn-cgi/trace` 视角
- **地理位置** —— 国家 / 省 / 市 / 时区
- **ASN / ISP** —— 由 `ipinfo.io` 提供
- **Claude 服务状态** —— claude.ai / Console / API / Code 四个组件

点 widget 跳原网页 `https://ip.net.coffee/claude/` 查看完整的 **Trust Score / 风险 / Tor / 滥用记录** 等高级数据。

## 数据源

| 端点 | 拿什么 | 频率 |
|---|---|---|
| `https://1.1.1.1/cdn-cgi/trace` | 默认出口 IP | Cloudflare 边缘，无明确限额 |
| `https://claude.ai/cdn-cgi/trace` | CF 出口 IP | 同上 |
| `https://ipinfo.io/{ip}/json` | ASN / ISP / 地理位置 / 时区 | 免费层 50k req/月 |
| `https://ip.net.coffee/claude/status.json` | Claude 服务状态 | 未限速 |

每 30 分钟一次刷新 = 一天 96 次 ipinfo 调用 ≈ 2880/月，远低于免费层限额。

## 安装

### 从源码 build

需要：macOS 14+、Xcode 15+、免费 Apple ID。

```bash
git clone https://github.com/tangshuai89/ClaudeIPBar.git
cd ClaudeIPBar
open ClaudeIPBar.xcodeproj
# Xcode → ClaudeIPBar target → Signing & Capabilities → Team = 你的 Apple ID
# 选择 ClaudeIPBar scheme → Cmd+R
```

### 添加 widget

桌面右键 → **Edit Widgets** → 搜索 `ClaudeIPBar` → 选择尺寸（Small / Medium / Large）→ 拖到桌面。

## 使用

- **刷新**：打开 Host App → 点 ↻（或 ⌘R）
- **改刷新频率**：Host App → ⚙ → 选 15 / 30 / 60 / 120 / 240 分钟
- **看 Trust Score**：点 widget → 自动打开原网页

## 开发

```bash
# 跑核心库单元测试（16 个，含 trace 解析 / ipinfo 模型 / JSON roundtrip）
swift test

# 跑 live 网络测试（需要环境能访问 ip.net.coffee / ipinfo.io）
CLAUDEIPBAR_LIVE=1 swift test --filter testLiveFetch

# 用 xcodebuild 编译（无需打开 Xcode）
xcodebuild -project ClaudeIPBar.xcodeproj -scheme ClaudeIPBar \
  -configuration Debug -destination 'platform=macOS' build

# 重新生成 .xcodeproj（如果你改了 project.yml）
brew install xcodegen   # 一次性
xcodegen generate
```

## 架构

```
1.1.1.1/cdn-cgi/trace     ──┐
claude.ai/cdn-cgi/trace   ──┤
ipinfo.io/{ip}/json       ──┼─► IPPollutionFetcher ─► IPReport
ip.net.coffee/.../status.json ──┘                            │
                                                              ▼
                                                       App Group (JSON)
                                                              │
                                                     ┌────────┴────────┐
                                                     ▼                 ▼
                                               Host App         Widget Extension
```

详细架构见 [ARCHITECTURE.md](ARCHITECTURE.md)，实施细节见 [PLAN.md](PLAN.md)。

## FAQ

### 为什么用 cdn-cgi/trace 拿 IP？

Cloudflare 边缘节点 `cdn-cgi/trace` 是公开的文本端点，返回 `ip=...` 字段。**无需鉴权、无 CORS 担忧、极快**。用两个不同 host（`1.1.1.1` 和 `claude.ai`）能区分默认 vs CF 出口 IP——后者就是 Claude 服务端看到的你。

### 为什么不用 HTML 解析？

实测 `https://ip.net.coffee/claude/` 的 IP 区域是 **JavaScript 动态加载**的（HTML 里只有 `loading-bar` 占位符），Trust Score 是前端用 **IPinfo + ipapi.is 商业 API** 算的。HTML 解析抓不到数据。

### Trust Score 怎么拿？

需要 IPinfo / ipapi.is 的 API key。**本项目不集成**——你点 widget 跳原网页看。如果以后想本地集成，告诉我 IPinfo token 或 ipapi.is key 怎么配就行。

### 数据隐私？

- 所有抓取、解析、存储都在**你本机**完成
- 不向任何第三方上传数据
- App Group 数据只在你自己的 Mac 上
- 代码开源，可审计

### 签名问题？

免费 Apple ID 签的 app 7 天过期（开发期）。本机自用 / GitHub release 都够。正式分发给他人需要 Apple Developer Program（$99/年）。

### 加新尺寸或新字段？

按 [ARCHITECTURE.md](ARCHITECTURE.md) 的"扩展位"章节提示加 widget family 或 IPReport 字段。

## 致谢

- 数据源：[ip.net.coffee/claude/](https://ip.net.coffee/claude/) by [bbj](https://www.nodeseek.com/post-679056-1)
- IP 情报：[ipinfo.io](https://ipinfo.io)
- IP 视角：[Cloudflare cdn-cgi/trace](https://developers.cloudflare.com/fundamentals/reference/cdn-cgi-trace/)

## License

[MIT](LICENSE)
