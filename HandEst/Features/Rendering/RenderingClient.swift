import ComposableArchitecture
import Foundation
import RealityKit

/// RealityKitレンダリング機能のDependencyクライアント
@DependencyClient
struct RenderingClient {
    /// RealityKitシーンを初期化する
    var initializeScene: @Sendable () async throws -> Void
    
    /// モデルプロバイダーを取得する
    var getModelProvider: @Sendable (ModelType) -> HandModelProvider = { _ in SimpleHandModelProvider() }
    
    /// ライティングを設定する
    var setupLighting: @Sendable () async throws -> Void
    
    /// レンダリングエラーを取得する
    var getCurrentError: @Sendable () -> RenderingError?
}

extension RenderingClient: DependencyKey {
    static let liveValue = Self(
        initializeScene: {
            // 実際のRealityKitシーン初期化処理
            // RealityViewで処理するため、ここでは基本的な設定のみ
        },
        getModelProvider: { modelType in
            switch modelType {
            case .simple:
                return SimpleHandModelProvider()
            case .mesh:
                // 将来実装
                return SimpleHandModelProvider()
            case .realistic:
                // 将来実装
                return SimpleHandModelProvider()
            }
        },
        setupLighting: {
            // 基本的なライティング設定
            // RealityViewで処理
        },
        getCurrentError: {
            return nil
        }
    )
    
    static let testValue = Self()
}

extension DependencyValues {
    var renderingClient: RenderingClient {
        get { self[RenderingClient.self] }
        set { self[RenderingClient.self] = newValue }
    }
}