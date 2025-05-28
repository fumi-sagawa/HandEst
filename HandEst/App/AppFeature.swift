import ComposableArchitecture
import Foundation

@Reducer
struct AppFeature {
    @ObservableState
    struct State: Equatable {
        var isLoading = false
        var hasError = false
        var errorMessage: String?
        var currentError: AppError?
    }
    
    enum Action: Equatable {
        case onAppear
        case setLoading(Bool)
        case showError(AppError)
        case showErrorMessage(String)
        case dismissError
    }
    
    var body: some ReducerOf<Self> {
        Reduce { state, action in
            switch action {
            case .onAppear:
                AppLogger.shared.info("アプリケーション開始")
                return .none
                
            case let .setLoading(isLoading):
                state.isLoading = isLoading
                return .none
                
            case let .showError(error):
                state.hasError = true
                state.errorMessage = error.userMessage
                state.currentError = error
                state.isLoading = false
                AppLogger.shared.error(error.description, category: error.category)
                return .none
                
            case let .showErrorMessage(message):
                state.hasError = true
                state.errorMessage = message
                state.currentError = nil
                state.isLoading = false
                return .none
                
            case .dismissError:
                state.hasError = false
                state.errorMessage = nil
                state.currentError = nil
                return .none
            }
        }
    }
}