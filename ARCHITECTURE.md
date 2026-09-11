# Architecture — ClaudeIPBar

> 详细架构说明。配套 [PLAN.md](PLAN.md)。

## 1. 系统视图

```
┌─────────────────────────────────────────────────────────────┐
│                    macOS 14+ Desktop                          │
│                                                              │
│  ┌──────────────────┐            ┌──────────────────────┐  │
│  │  ClaudeIPBar.app │            │ Widget Extension      │  │
│  │  (Host App)      │            │ (.appex)              │  │
│  │                  │            │                       │  │
│  │  - ContentView   │ ──reload── │  - TimelineProvider  │  │
│  │  - SettingsView  │            │  - 3 EntryView        │  │
│  │  - Fetcher       │            │  - WidgetReloadIntent │  │
│  └────────┬─────────┘            └──────────┬────────────┘  │
│           │                                 │                │
│           │       App Group                 │                │
│           │   (group.me.blacksweaters.      │                │
│           │       claudeipbar)              │                │
│           ▼                                 ▼                │
│  ┌──────────────────────────────────────────────────────┐   │
│  │  App Group Container                                  │   │
│  │  - current-report.json (IPReport)                    │   │
│  │  - last-fetched-at (UserDefaults)                    │   │
│  │  - settings.json (refresh interval etc.)             │   │
│  └──────────────────────────────────────────────────────┘   │
└─────────────────────────────────────────────────────────────┘
           │
           │  URLSession
           ▼
   ┌────────────────────────────────────────────┐
   │  https://ip.net.coffee/claude/             │
   │    → HTML                                  │
   │  https://ip.net.coffee/claude/status.json  │
   │    → JSON (Claude 服务状态)                │
   └────────────────────────────────────────────┘
```

## 2. 关键设计决策

### 2.1 为什么双 target 而不是单 target？

| 维度 | 单 target | 双 target（推荐）|
|---|---|---|
| Widget 独立运行 | ❌ 必须打开 App | ✅ 独立后台 |
| 沙盒限制 | 共享 | 各自独立 + App Group 通信 |
| App Store 上架 | 复杂 | 标准做法 |
| 后台刷新 | 受限 | Host App 主动 trigger |

### 2.2 为什么 App Group + UserDefaults + JSON 文件？

- **UserDefaults** 存轻量配置（刷新频率、最后 fetch 时间）
- **JSON 文件** 存结构化数据（IPReport），可读、可迁移、易调试
- **App Group** 让两个 target 共享容器路径

### 2.3 为什么 TimelineProvider 默认 30 min？

- WidgetKit 系统硬性下限：15 min
- 30 min 是"用户感知不到过期"和"省电省流量"的平衡
- 用户点 widget 触发的主动 reload 不受此限

### 2.4 为什么用 SwiftSoup 而不是 WKWebView / 正则？

| 方案 | 优点 | 缺点 |
|---|---|---|
| SwiftSoup | 体积小、解析快、对 DOM 顺序变化宽容 | 额外 SPM 依赖 |
| WKWebView | 内置、能跑 JS | 启动慢、widget 进程无法用 |
| 正则 | 零依赖 | 脆、改版即崩 |

SwiftSoup 胜。

## 3. 模块依赖

```
ClaudeIPBar.app (Host)
    ├── Shared/Models           ◄─────┐
    ├── Shared/Networking       ◄──┐  │
    ├── Shared/UI               ◄─┐│  │
    │                              ││  │
    └── App/                       ││  │
        ContentView                ││  │
        SettingsView               ││  │
                                  ││  │
ClaudeIPBarWidget.appex (Widget)  ││  │
    ├── Shared/Models ────────────┘│  │
    ├── Shared/UI ─────────────────┘  │
    ├── Widget/                       │
    │   ClaudeIPBarWidget             │
    │   Provider                      │
    │   EntryViews/                   │
    │   WidgetReloadIntent            │
    └─────────────────────────────┘───┘
```

## 4. 数据契约：App Group 协议

```swift
// 写入方：Host App
struct AppGroupStore {
    static let suiteName = "group.me.blacksweaters.claudeipbar"

    // 当前报告
    static func saveReport(_ report: IPReport) throws
    static func loadReport() -> IPReport?

    // 配置
    static var refreshIntervalMinutes: Int { get set }   // 默认 30
    static var lastFetchedAt: Date? { get set }
}
```

## 5. 错误处理矩阵

| 场景 | 表现 | 兜底 |
|---|---|---|
| 网络断 | Host App: "网络错误"+重试 | Widget 读 last good report + 显示 stale |
| HTML 改版 | 解析失败，parseError 非空 | Widget 显示 "数据格式变更" + "打开网页"按钮 |
| status.json 404 | serviceStatus = nil | 不影响 IP 数据展示 |
| App Group 损坏 | 解析 JSON 失败 | 清空，写入日志，Host App 重新拉 |
| 沙盒拒网络 | 启动时 entitlements 缺失 | README 提示检查 Capability |

## 6. 安全 / 隐私

- App Sandbox：开启（默认）
- 网络出站：仅 `ip.net.coffee` 域（声明在 entitlements）
- 不收集用户数据
- 不上传任何东西
- 解析逻辑开源，可审计
- 解析失败时不上报（避免信息泄露给第三方）

## 7. 未来扩展位

- `Shared/Networking/` 可加新的 fetcher（多 IP 情报源）
- `App/ContentView.swift` 可加 tab（IP / 状态 / 历史）
- `Widget/EntryViews/` 可加 `accessoryRectangular`（锁屏 / Now Playing 风格）
- `Shared/Models/` 可加 `IPReportHistory`（多天对比）
