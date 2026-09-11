import Foundation
import os.log

/// 统一 Logger
public enum AppLog {
    private static let subsystem = "me.blacksweaters.claudeipbar"

    public static let fetcher = Logger(subsystem: subsystem, category: "fetcher")
    public static let parser = Logger(subsystem: subsystem, category: "parser")
    public static let store = Logger(subsystem: subsystem, category: "store")
    public static let widget = Logger(subsystem: subsystem, category: "widget")
    public static let app = Logger(subsystem: subsystem, category: "app")
}
