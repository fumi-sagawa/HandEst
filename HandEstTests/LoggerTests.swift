import XCTest
@testable import HandEst

final class LoggerTests: XCTestCase {
    
    /// 動作: AppLogger.sharedを複数回呼び出し
    /// 期待結果: 同一インスタンスが返される（シングルトンパターン）
    func testLoggerSharedInstance() {
        let logger1 = AppLogger.shared
        let logger2 = AppLogger.shared
        
        XCTAssertTrue(logger1 === logger2, "Logger should be a singleton")
    }
    
    /// 動作: LogCategory.allCasesで全カテゴリを取得
    /// 期待結果: 必要な6つのカテゴリ（app/camera/handTracking/rendering/ui/error）が存在
    func testLogCategoriesExist() {
        let categories = LogCategory.allCases
        
        XCTAssertTrue(categories.contains(.app))
        XCTAssertTrue(categories.contains(.camera))
        XCTAssertTrue(categories.contains(.handTracking))
        XCTAssertTrue(categories.contains(.rendering))
        XCTAssertTrue(categories.contains(.ui))
        XCTAssertTrue(categories.contains(.error))
    }
    
    /// 動作: 各ログレベルのemojiプロパティを確認
    /// 期待結果: debug=🔍, info=ℹ️, warning=⚠️, error=❌の絵文字が設定されている
    func testLogLevelsHaveCorrectEmojis() {
        XCTAssertEqual(LogLevel.debug.emoji, "🔍")
        XCTAssertEqual(LogLevel.info.emoji, "ℹ️")
        XCTAssertEqual(LogLevel.warning.emoji, "⚠️")
        XCTAssertEqual(LogLevel.error.emoji, "❌")
    }
    
    /// 動作: ログレベルのrawValue（優先度）を比較
    /// 期待結果: debug < info < warning < error の順序で優先度が設定されている
    func testLogLevelsHaveCorrectOrder() {
        XCTAssertLessThan(LogLevel.debug.rawValue, LogLevel.info.rawValue)
        XCTAssertLessThan(LogLevel.info.rawValue, LogLevel.warning.rawValue)
        XCTAssertLessThan(LogLevel.warning.rawValue, LogLevel.error.rawValue)
    }
}