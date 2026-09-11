# ClaudeIPBar — 实施 Plan（v2 调整版）

> **v2 调整**：原 plan 假设 HTML 抓取 + SwiftSoup 解析。**实测发现**目标页 IP 区域是 JS 动态加载，Trust Score 是前端用商业 IP 情报 API（IPinfo + ipapi.is）计算的。HTML 解析走不通。
>
> **调整后方案**：跳过 HTML 解析层，用 4 个 JSON/文本端点组合数据。Trust Score 走"点 widget 跳网页"路径。
>
> v1 plan 保留作为历史记录。v2 为当前实施方案。

## 1. 关键决策

| 维度 | 选择 | 理由 |
|---|---|---|
| 平台 | macOS 14 Sonoma+ | 桌面 WidgetKit 从 14 开始原生支持 |
| 语言 | Swift 5.9+ | Apple 平台官方 |
| UI | SwiftUI | Widget 渲染层只能用 SwiftUI |
| 小组件 | WidgetKit | 系统级桌面小组件 |
| **数据源 v2** | `1.1.1.1/cdn-cgi/trace` + `claude.ai/cdn-cgi/trace` + `ipinfo.io/{ip}/json` + `/claude/status.json` | 4 个 JSON/文本端点，无 HTML 解析 |
| HTML 解析 | **不需要**（v1 SwiftSoup 已移除） | 目标页 IP 是 JS 动态加载 |
| 跨进程数据共享 | App Group + UserDefaults + JSON | 标准做法 |
| 刷新策略 | TimelineProvider 默认 30 min；用户点 widget / Host App 主动 reload | 平衡时效与省电 |
| 本地签名 | 免费 Apple ID | 本机用 / GitHub release 都够 |
| 项目名 | `ClaudeIPBar` | 简洁、记忆点强 |
| GitHub repo | `blacksweaters/ClaudeIPBar` | 与个人 ID 一致 |
| Bundle ID 前缀 | `me.blacksweaters.claudeipbar` | 与个人域名一致 |

## 2. 架构

### 2.1 数据流（v2）

```
┌─────────────────────────────────────────────────┐
│            IPPollutionFetcher.fetch()            │
│                                                  │
│  async let defaultTrace = fetch("1.1.1.1")     │
│  async let cfTrace      = fetch("claude.ai")    │
│  async let status       = fetch("status.json") │
│  async let defaultInfo  = ipInfo(defaultTrace)  │
│  async let cfInfo       = ipInfo(cfTrace)       │
│                                                  │
│  5 个请求并行 ──► 拼装 IPReport                  │
└────────────────────┬────────────────────────────┘
                     │
                     ▼
              App Group (JSON)
                     │
                ┌────┴────┐
                ▼         ▼
            Host App    Widget
```

### 2.2 双 target

```
ClaudeIPBar.app (Host)
  - ContentView  / SettingsView
  - ReportStore (@MainActor ObservableObject)
  - 主动拉数据 + 写 App Group + WidgetCenter.shared.reloadAllTimelines()
  - UserDefaults 存 refreshIntervalMinutes

ClaudeIPBarWidget.appex (Widget)
  - TimelineProvider (30 min 默认)
  - 3 尺寸 EntryView（Small / Medium / Large）
  - 读 App Group
```

## 3. 数据源细节

| 端点 | 拿什么 | 限速 |
|---|---|---|
| `https://1.1.1.1/cdn-cgi/trace` | 默认出口 IP（`ip=` 字段） | Cloudflare 边缘，无明确限额 |
| `https://claude.ai/cdn-cgi/trace` | CF 出口 IP（`ip=` 字段） | 同上 |
| `https://ipinfo.io/{ip}/json` | ASN / ISP / 国家 / 省 / 市 / 经纬度 / 时区 / 邮编 | 50k req/月（免费层） |
| `https://ip.net.coffee/claude/status.json` | Claude 服务状态（4 个组件） | 未限速 |

**频率估算**：每 30 min 刷新一次 = 一天 48 次 × 2 IP（trace）= 96 次 ipinfo ≈ 2880 次/月，远低于 50k 限额。

## 4. 目录结构

```
ClaudeIPBar/
├── App/                                  # Host App (Xcode target)
│   ├── ClaudeIPBarApp.swift
│   ├── ContentView.swift
│   ├── SettingsView.swift
│   ├── Info.plist
│   ├── ClaudeIPBar.entitlements
│   └── Assets.xcassets/
├── Widget/                               # Widget Extension (Xcode target)
│   ├── ClaudeIPBarWidget.swift
│   ├── Provider.swift
│   ├── EntryViews/
│   │   ├── SmallWidgetView.swift
│   │   ├── MediumWidgetView.swift
│   │   └── LargeWidgetView.swift
│   ├── Info.plist
│   └── ClaudeIPBarWidget.entitlements
├── Sources/ClaudeIPBarCore/              # SPM 包
│   ├── Models/
│   │   ├── IPReport.swift
│   │   ├── ClaudeServiceStatus.swift
│   │   └── AppGroup.swift
│   ├── Networking/
│   │   ├── CDNTrace.swift                # 解析 1.1.1.1/claude.ai cdn-cgi/trace
│   │   ├── IPInfoClient.swift            # 调 ipinfo.io
│   │   └── IPPollutionFetcher.swift      # 顶层编排
│   ├── Storage/
│   │   └── AppGroupDataStore.swift
│   └── Logging/
│       └── Logger.swift
├── Tests/ClaudeIPBarCoreTests/           # 单元测试（16 个，全过）
│   ├── CDNTraceParserTests.swift
│   ├── IPInfoClientTests.swift
│   ├── IPPollutionFetcherIntegrationTests.swift  # live 测试
│   ├── ModelsTests.swift
│   ├── StatusJSONDecodingTests.swift
│   └── Fixtures/
│       └── status.json
├── project.yml                            # xcodegen 配置
├── Package.swift                          # SPM 包定义
├── ClaudeIPBar.xcodeproj                  # xcodegen 产物
├── LICENSE                                # MIT
├── README.md
├── PLAN.md                                # 本文件
└── ARCHITECTURE.md
```

## 5. 开发阶段（已完成 ✅）

- [x] **Phase 0** — 初始化（xcodegen 安装、project.yml、SPM 包）
- [x] **Phase 1** — 抓取 + 解析（CDNTrace、IPInfoClient、IPPollutionFetcher + 16 单测）
- [x] **Phase 2** — Host App（ContentView / SettingsView / ReportStore）
- [x] **Phase 3** — Widget Extension（Provider / 3 尺寸 EntryView）
- [x] **Phase 4** — 打磨（暗色 / 错误兜底 / AppIcon 占位）
- [x] **Phase 5** — 编译验证（xcodebuild build → BUILD SUCCEEDED）

## 6. Live 验证（已跑通）

```
================ ClaudeIPBar Live Report ================
defaultExitIP:    188.253.121.93
defaultExitGeo:   Singapore, SG
cloudflareExitIP: 202.156.27.237
cloudflareExitGeo:Choa Chu Kang New Town, Singapore, SG
asn:              AS38136
isp:              Akari Networks
timezone:         Asia/Singapore
---
claude:           轻微故障 [minor]
  • claude.ai → 正常运行
  • Claude Console (platform.claude.com) → 正常运行
  • Claude API (api.anthropic.com) → 正常运行
  • Claude Code → 正常运行
==========================================================
```

## 7. 风险 & 缓解（v2）

| 风险 | 缓解 |
|---|---|
| ipinfo.io 限速 / 挂掉 | 失败时 widget 显示"数据过期"+ parseError；下次刷新自动重试 |
| cdn-cgi/trace 不可达 | 单边 trace 失败仍能用另一边；parseError 标记 |
| ipinfo.io 免费层降级 | 未来可加 token 支持（设置项预留） |
| 域名变更（ip.net.coffee） | status.json 失败不影响 IP 数据 |

## 8. 本地 build & run

```bash
git clone https://github.com/blacksweaters/ClaudeIPBar.git
cd ClaudeIPBar
open ClaudeIPBar.xcodeproj
# Xcode: Signing & Capabilities → Team = 你的 Apple ID
# 选 ClaudeIPBar scheme → Cmd+R
# 桌面右键 → Edit Widgets → 搜 ClaudeIPBar → 添加
```

## 9. v1 → v2 的关键差异

| 项 | v1（plan） | v2（实施） |
|---|---|---|
| HTML 解析 | SwiftSoup 解析 server-rendered HTML | 删除（HTML 是 JS 渲染） |
| Trust Score | 解析 `.gauge-score` | 删除（原作者用商业 API 算） |
| IP 拿取 | 解析 `.ip-hero .ip-addr` | `cdn-cgi/trace`（2 个 host） |
| ASN / ISP | 解析 `.risk-row` | ipinfo.io `/json` |
| 依赖 | SwiftSoup | 无 |
| 单测 | HTML parser 解析固化 HTML | trace 文本 + ipinfo JSON + 16 测试 |
