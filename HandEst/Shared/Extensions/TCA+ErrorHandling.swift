import ComposableArchitecture
import Foundation

extension Effect {
    /// エラーをキャッチしてAppErrorにラップするEffect拡張
    static func catching<T: Sendable>(
        _ operation: @escaping @Sendable () async throws -> T,
        errorMapper: @escaping @Sendable (Error) -> Action
    ) -> Effect<Action> {
        return .run { send in
            do {
                _ = try await operation()
            } catch {
                await send(errorMapper(error))
            }
        }
    }
    
    /// カメラエラーを処理するためのヘルパー
    static func handleCameraError<T: Sendable>(
        _ operation: @escaping @Sendable () async throws -> T,
        onError: @escaping @Sendable (CameraError) -> Action
    ) -> Effect<Action> {
        return .catching(operation) { error in
            if let cameraError = error as? CameraError {
                return onError(cameraError)
            } else {
                return onError(.unknown(error.localizedDescription))
            }
        }
    }
}

/// 共通のエラーハンドリングヘルパー関数
struct ErrorHandling {
    /// エラー状態をクリアするための関数
    static func clearError<State>(
        _ state: inout State,
        at path: WritableKeyPath<State, String?>
    ) {
        state[keyPath: path] = nil
    }
    
    /// エラー状態を設定するための関数
    static func setError<State>(
        _ state: inout State,
        at path: WritableKeyPath<State, String?>,
        error: String
    ) {
        state[keyPath: path] = error
    }
}