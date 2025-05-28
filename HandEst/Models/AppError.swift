import Foundation

enum AppError: Error, Equatable, CustomStringConvertible {
    case camera(CameraError)
    case handTracking(HandTrackingError)
    case rendering(RenderingError)
    case permission(PermissionError)
    case unknown(String)
    
    var description: String {
        switch self {
        case .camera(let error):
            return "カメラエラー: \(error.localizedDescription)"
        case .handTracking(let error):
            return "手トラッキングエラー: \(error.localizedDescription)"
        case .rendering(let error):
            return "レンダリングエラー: \(error.localizedDescription)"
        case .permission(let error):
            return "権限エラー: \(error.localizedDescription)"
        case .unknown(let message):
            return "予期しないエラー: \(message)"
        }
    }
    
    var userMessage: String {
        switch self {
        case .camera(let error):
            return error.userMessage
        case .handTracking(let error):
            return error.userMessage
        case .rendering(let error):
            return error.userMessage
        case .permission(let error):
            return error.userMessage
        case .unknown:
            return "予期しないエラーが発生しました。アプリを再起動してお試しください。"
        }
    }
    
    var category: LogCategory {
        switch self {
        case .camera:
            return .camera
        case .handTracking:
            return .handTracking
        case .rendering:
            return .rendering
        case .permission, .unknown:
            return .error
        }
    }
}

enum CameraError: Error, Equatable {
    case permissionDenied
    case configurationFailed
    case captureSessionFailed
    case deviceNotAvailable
    case unknown(String)
    
    var localizedDescription: String {
        switch self {
        case .permissionDenied:
            return "カメラへのアクセス許可が拒否されました"
        case .configurationFailed:
            return "カメラの設定に失敗しました"
        case .captureSessionFailed:
            return "カメラのキャプチャセッションの開始に失敗しました"
        case .deviceNotAvailable:
            return "カメラデバイスが利用できません"
        case .unknown(let message):
            return message
        }
    }
    
    var userMessage: String {
        switch self {
        case .permissionDenied:
            return "カメラの使用を許可してください。設定アプリからHandEstのカメラ権限を有効にしてください。"
        case .configurationFailed, .captureSessionFailed:
            return "カメラの初期化に失敗しました。アプリを再起動してお試しください。"
        case .deviceNotAvailable:
            return "カメラが利用できません。デバイスを確認してください。"
        case .unknown:
            return "カメラで予期しないエラーが発生しました。"
        }
    }
}

enum HandTrackingError: Error, Equatable {
    case initializationFailed
    case modelLoadFailed
    case processingFailed
    case noHandsDetected
    case unknown(String)
    
    var localizedDescription: String {
        switch self {
        case .initializationFailed:
            return "手トラッキングの初期化に失敗しました"
        case .modelLoadFailed:
            return "手トラッキングモデルの読み込みに失敗しました"
        case .processingFailed:
            return "手トラッキング処理に失敗しました"
        case .noHandsDetected:
            return "手が検出されませんでした"
        case .unknown(let message):
            return message
        }
    }
    
    var userMessage: String {
        switch self {
        case .initializationFailed, .modelLoadFailed:
            return "手トラッキング機能の初期化に失敗しました。アプリを再起動してお試しください。"
        case .processingFailed:
            return "手トラッキング処理でエラーが発生しました。"
        case .noHandsDetected:
            return "手が検出されませんでした。カメラに手をかざしてください。"
        case .unknown:
            return "手トラッキングで予期しないエラーが発生しました。"
        }
    }
}

enum RenderingError: Error, Equatable {
    case sceneSetupFailed
    case modelLoadFailed
    case animationFailed
    case unknown(String)
    
    var localizedDescription: String {
        switch self {
        case .sceneSetupFailed:
            return "3Dシーンの設定に失敗しました"
        case .modelLoadFailed:
            return "3Dモデルの読み込みに失敗しました"
        case .animationFailed:
            return "3Dモデルのアニメーション処理に失敗しました"
        case .unknown(let message):
            return message
        }
    }
    
    var userMessage: String {
        switch self {
        case .sceneSetupFailed, .modelLoadFailed:
            return "3Dレンダリングの初期化に失敗しました。アプリを再起動してお試しください。"
        case .animationFailed:
            return "3Dモデルのアニメーション処理でエラーが発生しました。"
        case .unknown:
            return "3Dレンダリングで予期しないエラーが発生しました。"
        }
    }
}

enum PermissionError: Error, Equatable {
    case cameraNotAuthorized
    case cameraRestricted
    case unknown(String)
    
    var localizedDescription: String {
        switch self {
        case .cameraNotAuthorized:
            return "カメラの使用が許可されていません"
        case .cameraRestricted:
            return "カメラの使用が制限されています"
        case .unknown(let message):
            return message
        }
    }
    
    var userMessage: String {
        switch self {
        case .cameraNotAuthorized:
            return "カメラの使用を許可してください。設定アプリからHandEstのカメラ権限を有効にしてください。"
        case .cameraRestricted:
            return "このデバイスではカメラの使用が制限されています。"
        case .unknown:
            return "権限で予期しないエラーが発生しました。"
        }
    }
}