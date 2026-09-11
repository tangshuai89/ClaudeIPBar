import SwiftUI
import ClaudeIPBarCore
import WidgetKit

@main
struct ClaudeIPBarApp: App {
    @StateObject private var store = ReportStore()

    var body: some Scene {
        WindowGroup("ClaudeIPBar") {
            ContentView()
                .environmentObject(store)
                .frame(minWidth: 520, minHeight: 600)
                .task {
                    // 启动时拉一次
                    await store.refresh()
                }
        }
        .windowResizability(.contentSize)
        .commands {
            CommandGroup(after: .newItem) {
                Button("立即刷新") {
                    Task { await store.refresh() }
                }
                .keyboardShortcut("r", modifiers: [.command])
            }
        }
    }
}

/// 全局状态：当前报告 + 加载态
@MainActor
final class ReportStore: ObservableObject {
    @Published private(set) var report: IPReport
    @Published private(set) var isLoading = false
    @Published private(set) var lastError: String?

    private let fetcher: IPPollutionFetcher
    private let dataStore: AppGroupDataStore
    private var refreshTask: Task<Void, Never>?

    init(
        fetcher: IPPollutionFetcher = IPPollutionFetcher(),
        dataStore: AppGroupDataStore = .shared
    ) {
        self.fetcher = fetcher
        self.dataStore = dataStore
        self.report = dataStore.loadReport() ?? .empty
    }

    /// 主动刷新
    func refresh() async {
        refreshTask?.cancel()
        refreshTask = Task { @MainActor in
            isLoading = true
            defer { isLoading = false }

            let new = await fetcher.fetch()
            self.report = new
            self.dataStore.saveReport(new)
            self.lastError = new.parseError

            // 触发 widget reload
            WidgetCenter.shared.reloadAllTimelines()
            AppLog.app.info("Refreshed; widget reloaded")
        }
        await refreshTask?.value
    }

    /// 启动定时刷新（按设置项）
    func startAutoRefresh() {
        Task { @MainActor in
            while !Task.isCancelled {
                let interval = TimeInterval(dataStore.refreshIntervalMinutes * 60)
                try? await Task.sleep(nanoseconds: UInt64(interval * 1_000_000_000))
                await refresh()
            }
        }
    }
}
