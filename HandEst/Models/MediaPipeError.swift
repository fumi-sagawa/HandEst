import Foundation

/// MediaPipe関連のエラーを表す列挙型
public enum MediaPipeError: Error, LocalizedError, Equatable {
    /// 初期化エラー
    case initializationFailed(String)
    
    /// モデルファイルが見つからない
    case modelNotFound(String)
    
    /// 無効な入力データ
    case invalidInput(String)
    
    /// 処理エラー
    case processingFailed(String)
    
    /// タイムアウトエラー
    case timeout
    
    /// メモリ不足
    case outOfMemory
    
    /// カメラアクセスエラー
    case cameraAccessDenied
    
    /// フレームレートエラー
    case lowFrameRate(fps: Double)
    
    /// 手が検出されない
    case noHandDetected
    
    /// 複数の手が検出された（単一手モードの場合）
    case multipleHandsDetected(count: Int)
    
    /// 信頼度が低い
    case lowConfidence(confidence: Float)
    
    /// 不明なエラー
    case unknown(String)
    
    public var errorDescription: String? {
        switch self {
        case .initializationFailed(let message):
            return "MediaPipeの初期化に失敗しました: \(message)"
        case .modelNotFound(let modelName):
            return "モデルファイルが見つかりません: \(modelName)"
        case .invalidInput(let message):
            return "無効な入力データ: \(message)"
        case .processingFailed(let message):
            return "処理中にエラーが発生しました: \(message)"
        case .timeout:
            return "処理がタイムアウトしました"
        case .outOfMemory:
            return "メモリが不足しています"
        case .cameraAccessDenied:
            return "カメラへのアクセスが拒否されました"
        case .lowFrameRate(let fps):
            return "フレームレートが低下しています: \(String(format: "%.1f", fps)) FPS"
        case .noHandDetected:
            return "手が検出されませんでした"
        case .multipleHandsDetected(let count):
            return "\(count)個の手が検出されました（単一手モードでは1つのみ対応）"
        case .lowConfidence(let confidence):
            return "検出の信頼度が低いです: \(String(format: "%.2f", confidence))"
        case .unknown(let message):
            return "不明なエラー: \(message)"
        }
    }
    
    public var recoverySuggestion: String? {
        switch self {
        case .initializationFailed:
            return "アプリを再起動してください"
        case .modelNotFound:
            return "アプリを再インストールしてください"
        case .invalidInput:
            return "カメラ設定を確認してください"
        case .processingFailed:
            return "もう一度お試しください"
        case .timeout:
            return "処理負荷を軽減してください"
        case .outOfMemory:
            return "他のアプリを終了してメモリを解放してください"
        case .cameraAccessDenied:
            return "設定アプリでカメラへのアクセスを許可してください"
        case .lowFrameRate:
            return "明るい場所で使用するか、処理品質を下げてください"
        case .noHandDetected:
            return "手をカメラの範囲内に入れてください"
        case .multipleHandsDetected:
            return "1つの手のみをカメラに映してください"
        case .lowConfidence:
            return "手をはっきりとカメラに映してください"
        case .unknown:
            return "アプリを再起動してください"
        }
    }
    
    /// エラーの重要度
    public var severity: ErrorSeverity {
        switch self {
        case .initializationFailed, .modelNotFound, .outOfMemory, .cameraAccessDenied:
            return .critical
        case .processingFailed, .timeout, .unknown:
            return .high
        case .invalidInput, .lowFrameRate, .multipleHandsDetected:
            return .medium
        case .noHandDetected, .lowConfidence:
            return .low
        }
    }
    
    /// リトライ可能かどうか
    public var isRetryable: Bool {
        switch self {
        case .processingFailed, .timeout, .noHandDetected, .lowConfidence:
            return true
        case .initializationFailed, .modelNotFound, .outOfMemory, .cameraAccessDenied, .invalidInput, .lowFrameRate, .multipleHandsDetected, .unknown:
            return false
        }
    }
}

/// エラーの重要度
public enum ErrorSeverity: String, CaseIterable {
    case low = "低"
    case medium = "中"
    case high = "高"
    case critical = "重大"
    
    /// UIでの表示色
    public var displayColor: String {
        switch self {
        case .low:
            return "blue"
        case .medium:
            return "orange"
        case .high:
            return "red"
        case .critical:
            return "purple"
        }
    }
}