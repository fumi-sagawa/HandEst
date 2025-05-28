import XCTest
@testable import HandEst

final class LoggerTests: XCTestCase {
    
    func testLoggerSharedInstance() {
        let logger1 = AppLogger.shared
        let logger2 = AppLogger.shared
        
        XCTAssertTrue(logger1 === logger2, "Logger should be a singleton")
    }
    
    func testLogCategoriesExist() {
        let categories = LogCategory.allCases
        
        XCTAssertTrue(categories.contains(.app))
        XCTAssertTrue(categories.contains(.camera))
        XCTAssertTrue(categories.contains(.handTracking))
        XCTAssertTrue(categories.contains(.rendering))
        XCTAssertTrue(categories.contains(.ui))
        XCTAssertTrue(categories.contains(.error))
    }
    
    func testLogLevelsHaveCorrectEmojis() {
        XCTAssertEqual(LogLevel.debug.emoji, "🔍")
        XCTAssertEqual(LogLevel.info.emoji, "ℹ️")
        XCTAssertEqual(LogLevel.warning.emoji, "⚠️")
        XCTAssertEqual(LogLevel.error.emoji, "❌")
    }
    
    func testLogLevelsHaveCorrectOrder() {
        XCTAssertLessThan(LogLevel.debug.rawValue, LogLevel.info.rawValue)
        XCTAssertLessThan(LogLevel.info.rawValue, LogLevel.warning.rawValue)
        XCTAssertLessThan(LogLevel.warning.rawValue, LogLevel.error.rawValue)
    }
}