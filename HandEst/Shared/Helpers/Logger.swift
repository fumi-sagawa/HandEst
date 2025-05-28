import Foundation
import os.log

enum LogCategory: String, CaseIterable {
    case app = "App"
    case camera = "Camera"
    case handTracking = "HandTracking"
    case rendering = "Rendering"
    case ui = "UI"
    case error = "Error"
}

enum LogLevel: Int, CaseIterable {
    case debug = 0
    case info = 1
    case warning = 2
    case error = 3
    
    var osLogType: OSLogType {
        switch self {
        case .debug:
            return .debug
        case .info:
            return .info
        case .warning:
            return .default
        case .error:
            return .error
        }
    }
    
    var emoji: String {
        switch self {
        case .debug:
            return "🔍"
        case .info:
            return "ℹ️"
        case .warning:
            return "⚠️"
        case .error:
            return "❌"
        }
    }
}

final class AppLogger {
    private let subsystem = "com.fumiyasagawa.HandEst"
    
    static let shared = AppLogger()
    
    private init() {}
    
    func log(
        _ message: String,
        category: LogCategory = .app,
        level: LogLevel = .info,
        file: String = #file,
        function: String = #function,
        line: Int = #line
    ) {
        let osLog = OSLog(subsystem: subsystem, category: category.rawValue)
        let fileName = URL(fileURLWithPath: file).lastPathComponent
        
        #if DEBUG
        let formattedMessage = "\(level.emoji) [\(category.rawValue)] \(fileName):\(line) \(function) - \(message)"
        os_log("%{public}@", log: osLog, type: level.osLogType, formattedMessage)
        #else
        os_log("%{public}@", log: osLog, type: level.osLogType, message)
        #endif
    }
    
    func debug(
        _ message: String,
        category: LogCategory = .app,
        file: String = #file,
        function: String = #function,
        line: Int = #line
    ) {
        log(message, category: category, level: .debug, file: file, function: function, line: line)
    }
    
    func info(
        _ message: String,
        category: LogCategory = .app,
        file: String = #file,
        function: String = #function,
        line: Int = #line
    ) {
        log(message, category: category, level: .info, file: file, function: function, line: line)
    }
    
    func warning(
        _ message: String,
        category: LogCategory = .app,
        file: String = #file,
        function: String = #function,
        line: Int = #line
    ) {
        log(message, category: category, level: .warning, file: file, function: function, line: line)
    }
    
    func error(
        _ message: String,
        category: LogCategory = .app,
        file: String = #file,
        function: String = #function,
        line: Int = #line
    ) {
        log(message, category: category, level: .error, file: file, function: function, line: line)
    }
}