import ComposableArchitecture
import Foundation

@Reducer
struct HandTrackingFeature {
    @ObservableState
    struct State: Equatable {
        var isTracking = false
        var isPoseLocked = false
        var handedness: Handedness = .right
        var error: String?
    }
    
    enum Action: Equatable {
        case startTracking
        case stopTracking
        case togglePoseLock
        case setHandedness(Handedness)
        case errorOccurred(String)
    }
    
    var body: some ReducerOf<Self> {
        Reduce { state, action in
            switch action {
            case .startTracking:
                state.isTracking = true
                return .none
                
            case .stopTracking:
                state.isTracking = false
                return .none
                
            case .togglePoseLock:
                state.isPoseLocked.toggle()
                return .none
                
            case let .setHandedness(handedness):
                state.handedness = handedness
                return .none
                
            case let .errorOccurred(error):
                state.error = error
                return .none
            }
        }
    }
}

enum Handedness: String, CaseIterable, Equatable {
    case left = "左手"
    case right = "右手"
}