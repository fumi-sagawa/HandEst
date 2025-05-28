import ComposableArchitecture
import Foundation

@Reducer
struct CameraFeature {
    @ObservableState
    struct State: Equatable {
        var isAuthorized = false
        var isCameraActive = false
        var error: String?
    }
    
    enum Action: Equatable {
        case onAppear
        case requestPermission
        case permissionGranted(Bool)
        case startCamera
        case stopCamera
        case errorOccurred(String)
    }
    
    var body: some ReducerOf<Self> {
        Reduce { state, action in
            switch action {
            case .onAppear:
                return .none
                
            case .requestPermission:
                return .none
                
            case let .permissionGranted(isGranted):
                state.isAuthorized = isGranted
                return .none
                
            case .startCamera:
                state.isCameraActive = true
                return .none
                
            case .stopCamera:
                state.isCameraActive = false
                return .none
                
            case let .errorOccurred(error):
                state.error = error
                return .none
            }
        }
    }
}