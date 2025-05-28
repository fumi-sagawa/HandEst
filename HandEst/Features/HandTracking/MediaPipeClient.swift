import ComposableArchitecture
import Foundation
import MediaPipeTasksVision

/// MediaPipeのHandLandmarkerを管理するクライアント
public struct MediaPipeClient: DependencyKey {
    public var initializeHandLandmarker: @Sendable () async throws -> Void
    public var isInitialized: @Sendable () -> Bool
    
    public static let liveValue = Self(
        initializeHandLandmarker: {
            // TODO: HandLandmarkerの初期化処理を実装
            // 現時点では基本的なimportの確認のみ
            _ = HandLandmarkerOptions()
        },
        isInitialized: {
            // TODO: 初期化状態の管理を実装
            return false
        }
    )
    
    public static let testValue = Self(
        initializeHandLandmarker: { },
        isInitialized: { true }
    )
}

public extension DependencyValues {
    var mediaPipeClient: MediaPipeClient {
        get { self[MediaPipeClient.self] }
        set { self[MediaPipeClient.self] = newValue }
    }
}