import ComposableArchitecture
import Foundation

extension Effect {
    static func handleError<T: Error>(
        operation: @escaping () async throws -> Void,
        errorAction: @escaping (T) -> Action
    ) -> Effect<Action> {
        .run { send in
            do {
                try await operation()
            } catch let error as T {
                await send(errorAction(error))
            } catch {
                AppLogger.shared.error("Unexpected error: \(error)")
            }
        }
    }
    
    static func handleAppError(
        operation: @escaping () async throws -> Void,
        errorAction: @escaping (AppError) -> Action
    ) -> Effect<Action> {
        .run { send in
            do {
                try await operation()
            } catch let error as AppError {
                AppLogger.shared.error(error.description, category: error.category)
                await send(errorAction(error))
            } catch {
                let appError = AppError.unknown(error.localizedDescription)
                AppLogger.shared.error(
                    appError.description, 
                    category: appError.category
                )
                await send(errorAction(appError))
            }
        }
    }
}