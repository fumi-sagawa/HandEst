import ComposableArchitecture
import Foundation

@Reducer
struct AppFeature {
    @ObservableState
    struct State: Equatable {
        // 共通状態
        var isLoading = false
        var hasError = false
        var errorMessage: String?
        var currentError: AppError?
        
        // 各Feature状態
        var camera = CameraFeature.State()
        var handTracking = HandTrackingFeature.State()
        var rendering = RenderingFeature.State()
        var settings = SettingsFeature.State()
    }
    
    enum Action: Equatable {
        // 共通アクション
        case onAppear
        case setLoading(Bool)
        case showError(AppError)
        case showErrorMessage(String)
        case dismissError
        
        // 子Featureアクション
        case camera(CameraFeature.Action)
        case handTracking(HandTrackingFeature.Action)
        case rendering(RenderingFeature.Action)
        case settings(SettingsFeature.Action)
    }
    
    var body: some ReducerOf<Self> {
        Scope(state: \.camera, action: \.camera) {
            CameraFeature()
        }
        Scope(state: \.handTracking, action: \.handTracking) {
            HandTrackingFeature()
        }
        Scope(state: \.rendering, action: \.rendering) {
            RenderingFeature()
        }
        Scope(state: \.settings, action: \.settings) {
            SettingsFeature()
        }
        
        Reduce { state, action in
            switch action {
            case .onAppear:
                AppLogger.shared.info("アプリケーション開始")
                return .merge(
                    .send(.camera(.onAppear)),
                    .send(.settings(.loadSettings))
                )
                
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
                
            // 子Featureアクションの処理
            case .camera, .handTracking, .rendering, .settings:
                return .none
            }
        }
    }
}