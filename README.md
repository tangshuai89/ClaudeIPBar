# ClaudeIPBar

> macOS 桌面小组件，实时显示 [ip.net.coffee](https://ip.net.coffee/claude/) 的 Claude IP 报告核心指标（默认 + Cloudflare 出口 IP、地理位置、ASN、ISP、时区、Claude 服务状态）。

## 它能做什么

桌面右侧放一个小组件，实时显示：

- **默认出口 IP**（`1.1.1.1/cdn-cgi/trace` 视角）
- **Cloudflare 出口 IP**（`claude.ai/cdn-cgi/trace` 视角）
- **地理位置**（国家 / 省 / 市 / 时区，`ipinfo.io`）
- **ASN / ISP**（`ipinfo.io` org 字段解析）
- **Claude 服务状态**（`/claude/status.json`）
- 点击 widget → 跳原网页查看 **Trust Score / 风险 / Tor** 等高级数据

> **关于 Trust Score**：原作者在客户端用 **IPinfo + ipapi.is 商业 API** 计算，**未公开**。本项目不抓 trust score，点击 widget 跳原网页看。

## 截图

> 等待你的截图

## 安装

### 从源码 build（推荐，最简单）

需要：macOS 14+、Xcode 15+、免费 Apple ID。

```bash
git clone https://github.com/blacksweaters/ClaudeIPBar.git
cd ClaudeIPBar
open ClaudeIPBar.xcodeproj
# Xcode → Signing & Capabilities → Team = 你的 Apple ID
# 选择 ClaudeIPBar scheme → Cmd+R
# 桌面右键 → Edit Widgets → 搜索 ClaudeIPBar → 添加
```

### 重新生成 Xcode 工程

`ClaudeIPBar.xcodeproj` 是用 `xcodegen` 从 `project.yml` 生成的。如果你改了 `project.yml`，运行：

```bash
brew install xcodegen   # 一次性
xcodegen generate
```

## 使用

- **添加 widget**：桌面右键 → Edit Widgets → 搜索 `ClaudeIPBar` → 选尺寸
- **立即刷新**：打开 Host App → 点 ↻ 按钮（或 ⌘R）
- **改刷新频率**：Host App → ⚙ → 选 15/30/60/120/240 分钟

## 工作原理

```
1.1.1.1/cdn-cgi/trace    ──► 默认出口 IP
claude.ai/cdn-cgi/trace  ──► Cloudflare 出口 IP
ipinfo.io/{ip}/json      ──► ASN / ISP / 地理位置（两个 IP 各查一次）
ip.net.coffee/claude/status.json  ──► Claude 服务状态
                                  │
                                  ▼
                          App Group (JSON)
                                  │
                                  ▼
                            Widget 渲染
```

详见 [PLAN.md](PLAN.md) / [ARCHITECTURE.md](ARCHITECTURE.md)。

## 开发

```bash
# 跑 core 库单元测试（16 个，含 trace 解析、ipinfo 模型、JSON roundtrip）
swift test

# 跑 live 网络测试（需网络）
CLAUDEIPBAR_LIVE=1 swift test --filter testLiveFetch

# build Xcode 工程
xcodebuild -project ClaudeIPBar.xcodeproj -scheme ClaudeIPBar \
  -configuration Debug -destination 'platform=macOS' build
```

## FAQ

### 为什么用 cdn-cgi/trace 拿 IP？

Cloudflare 边缘节点 `cdn-cgi/trace` 文本端点返回 `ip=...` 字段，**无需鉴权、无需 CORS 担忧、极快**。两个不同 host（`1.1.1.1` 和 `claude.ai`）能区分默认 vs CF 出口 IP。

### 为什么不用 HTML 解析？

实测 `https://ip.net.coffee/claude/` 的 IP 区域是 **JS 动态加载**的（HTML 里只有 `loading-bar` 占位符），Trust Score 是前端用 IPinfo + ipapi.is 算的。HTML 解析抓不到数据。

### Trust Score 怎么拿？

需要 IPinfo / ipapi.is 商业 API key。本项目**不集成**——你点 widget 跳原网页看。

### 数据隐私？

- 所有抓取、解析、存储都在本机
- 不上传任何数据
- App Group 数据只在你自己的 Mac 上
- 开源，可审计

### 签名问题？

免费 Apple ID 签的 app 7 天过期（开发期）。本机自用 / GitHub release 都够；正式分发给他人需要 Apple Developer Program（$99/年）。

## 致谢

- 数据源：[ip.net.coffee](https://ip.net.coffee/claude/) by bbj
- IP 情报：[ipinfo.io](https://ipinfo.io)
- IP / 服务状态：[Cloudflare cdn-cgi/trace](https://developers.cloudflare.com/fundamentals/reference/cdn-cgi-trace/)

## License

MIT
