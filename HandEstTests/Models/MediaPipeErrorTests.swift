import XCTest
@testable import HandEst

final class MediaPipeErrorTests: XCTestCase {
    
    /// 動作: 各エラータイプのerrorDescriptionを確認
    /// 期待結果: 適切な日本語エラーメッセージが返される
    func testErrorDescriptions() {
        XCTAssertEqual(
            MediaPipeError.initializationFailed("設定エラー").errorDescription,
            "MediaPipeの初期化に失敗しました: 設定エラー"
        )
        
        XCTAssertEqual(
            MediaPipeError.modelNotFound("hand_landmarker.task").errorDescription,
            "モデルファイルが見つかりません: hand_landmarker.task"
        )
        
        XCTAssertEqual(
            MediaPipeError.invalidInput("フォーマットエラー").errorDescription,
            "無効な入力データ: フォーマットエラー"
        )
        
        XCTAssertEqual(
            MediaPipeError.processingFailed("推論エラー").errorDescription,
            "処理中にエラーが発生しました: 推論エラー"
        )
        
        XCTAssertEqual(
            MediaPipeError.timeout.errorDescription,
            "処理がタイムアウトしました"
        )
        
        XCTAssertEqual(
            MediaPipeError.outOfMemory.errorDescription,
            "メモリが不足しています"
        )
        
        XCTAssertEqual(
            MediaPipeError.cameraAccessDenied.errorDescription,
            "カメラへのアクセスが拒否されました"
        )
        
        XCTAssertEqual(
            MediaPipeError.lowFrameRate(fps: 15.5).errorDescription,
            "フレームレートが低下しています: 15.5 FPS"
        )
        
        XCTAssertEqual(
            MediaPipeError.noHandDetected.errorDescription,
            "手が検出されませんでした"
        )
        
        XCTAssertEqual(
            MediaPipeError.multipleHandsDetected(count: 3).errorDescription,
            "3個の手が検出されました（単一手モードでは1つのみ対応）"
        )
        
        XCTAssertEqual(
            MediaPipeError.lowConfidence(confidence: 0.35).errorDescription,
            "検出の信頼度が低いです: 0.35"
        )
        
        XCTAssertEqual(
            MediaPipeError.unknown("予期しないエラー").errorDescription,
            "不明なエラー: 予期しないエラー"
        )
    }
    
    /// 動作: 各エラータイプのrecoverySuggestionを確認
    /// 期待結果: 適切な回復提案が返される
    func testRecoverySuggestions() {
        XCTAssertEqual(
            MediaPipeError.initializationFailed("").recoverySuggestion,
            "アプリを再起動してください"
        )
        
        XCTAssertEqual(
            MediaPipeError.modelNotFound("").recoverySuggestion,
            "アプリを再インストールしてください"
        )
        
        XCTAssertEqual(
            MediaPipeError.invalidInput("").recoverySuggestion,
            "カメラ設定を確認してください"
        )
        
        XCTAssertEqual(
            MediaPipeError.processingFailed("").recoverySuggestion,
            "もう一度お試しください"
        )
        
        XCTAssertEqual(
            MediaPipeError.timeout.recoverySuggestion,
            "処理負荷を軽減してください"
        )
        
        XCTAssertEqual(
            MediaPipeError.outOfMemory.recoverySuggestion,
            "他のアプリを終了してメモリを解放してください"
        )
        
        XCTAssertEqual(
            MediaPipeError.cameraAccessDenied.recoverySuggestion,
            "設定アプリでカメラへのアクセスを許可してください"
        )
        
        XCTAssertEqual(
            MediaPipeError.lowFrameRate(fps: 15).recoverySuggestion,
            "明るい場所で使用するか、処理品質を下げてください"
        )
        
        XCTAssertEqual(
            MediaPipeError.noHandDetected.recoverySuggestion,
            "手をカメラの範囲内に入れてください"
        )
        
        XCTAssertEqual(
            MediaPipeError.multipleHandsDetected(count: 2).recoverySuggestion,
            "1つの手のみをカメラに映してください"
        )
        
        XCTAssertEqual(
            MediaPipeError.lowConfidence(confidence: 0.3).recoverySuggestion,
            "手をはっきりとカメラに映してください"
        )
        
        XCTAssertEqual(
            MediaPipeError.unknown("").recoverySuggestion,
            "アプリを再起動してください"
        )
    }
    
    /// 動作: 各エラータイプのseverityを確認
    /// 期待結果: 適切な重要度が返される
    func testErrorSeverity() {
        // Critical
        XCTAssertEqual(MediaPipeError.initializationFailed("").severity, .critical)
        XCTAssertEqual(MediaPipeError.modelNotFound("").severity, .critical)
        XCTAssertEqual(MediaPipeError.outOfMemory.severity, .critical)
        XCTAssertEqual(MediaPipeError.cameraAccessDenied.severity, .critical)
        
        // High
        XCTAssertEqual(MediaPipeError.processingFailed("").severity, .high)
        XCTAssertEqual(MediaPipeError.timeout.severity, .high)
        XCTAssertEqual(MediaPipeError.unknown("").severity, .high)
        
        // Medium
        XCTAssertEqual(MediaPipeError.invalidInput("").severity, .medium)
        XCTAssertEqual(MediaPipeError.lowFrameRate(fps: 15).severity, .medium)
        XCTAssertEqual(MediaPipeError.multipleHandsDetected(count: 2).severity, .medium)
        
        // Low
        XCTAssertEqual(MediaPipeError.noHandDetected.severity, .low)
        XCTAssertEqual(MediaPipeError.lowConfidence(confidence: 0.3).severity, .low)
    }
    
    /// 動作: 各エラータイプのisRetryableを確認
    /// 期待結果: リトライ可能性が正しく判定される
    func testIsRetryable() {
        // Retryable
        XCTAssertTrue(MediaPipeError.processingFailed("").isRetryable)
        XCTAssertTrue(MediaPipeError.timeout.isRetryable)
        XCTAssertTrue(MediaPipeError.noHandDetected.isRetryable)
        XCTAssertTrue(MediaPipeError.lowConfidence(confidence: 0.3).isRetryable)
        
        // Not Retryable
        XCTAssertFalse(MediaPipeError.initializationFailed("").isRetryable)
        XCTAssertFalse(MediaPipeError.modelNotFound("").isRetryable)
        XCTAssertFalse(MediaPipeError.outOfMemory.isRetryable)
        XCTAssertFalse(MediaPipeError.cameraAccessDenied.isRetryable)
        XCTAssertFalse(MediaPipeError.invalidInput("").isRetryable)
        XCTAssertFalse(MediaPipeError.lowFrameRate(fps: 15).isRetryable)
        XCTAssertFalse(MediaPipeError.multipleHandsDetected(count: 2).isRetryable)
        XCTAssertFalse(MediaPipeError.unknown("").isRetryable)
    }
    
    /// 動作: ErrorSeverityの表示色を確認
    /// 期待結果: 各重要度に対して適切な色が返される
    func testErrorSeverityDisplayColor() {
        XCTAssertEqual(ErrorSeverity.low.displayColor, "blue")
        XCTAssertEqual(ErrorSeverity.medium.displayColor, "orange")
        XCTAssertEqual(ErrorSeverity.high.displayColor, "red")
        XCTAssertEqual(ErrorSeverity.critical.displayColor, "purple")
    }
    
    /// 動作: MediaPipeErrorのEquatable準拠をテスト
    /// 期待結果: 同じエラータイプとパラメータを持つインスタンスが等しいと判定される
    func testMediaPipeErrorEquatable() {
        XCTAssertEqual(
            MediaPipeError.initializationFailed("エラー1"),
            MediaPipeError.initializationFailed("エラー1")
        )
        
        XCTAssertNotEqual(
            MediaPipeError.initializationFailed("エラー1"),
            MediaPipeError.initializationFailed("エラー2")
        )
        
        XCTAssertEqual(
            MediaPipeError.timeout,
            MediaPipeError.timeout
        )
        
        XCTAssertNotEqual(
            MediaPipeError.timeout,
            MediaPipeError.outOfMemory
        )
        
        XCTAssertEqual(
            MediaPipeError.lowFrameRate(fps: 15.5),
            MediaPipeError.lowFrameRate(fps: 15.5)
        )
        
        XCTAssertNotEqual(
            MediaPipeError.lowFrameRate(fps: 15.5),
            MediaPipeError.lowFrameRate(fps: 20.0)
        )
    }
    
    /// 動作: LocalizedError準拠を確認
    /// 期待結果: MediaPipeErrorがLocalizedErrorプロトコルに準拠している
    func testLocalizedErrorConformance() {
        let error: LocalizedError = MediaPipeError.noHandDetected
        
        XCTAssertEqual(error.errorDescription, "手が検出されませんでした")
        XCTAssertEqual(error.recoverySuggestion, "手をカメラの範囲内に入れてください")
    }
}