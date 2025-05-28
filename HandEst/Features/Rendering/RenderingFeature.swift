import ComposableArchitecture
import Foundation

@Reducer
struct RenderingFeature {
    @ObservableState
    struct State: Equatable {
        var focalLength: FocalLength = .normal50mm
        var rotation: Float = 0
        var scale: Float = 1.0
        var isRendering = false
        var error: String?
    }
    
    enum Action: Equatable {
        case startRendering
        case stopRendering
        case setFocalLength(FocalLength)
        case updateRotation(Float)
        case updateScale(Float)
        case errorOccurred(String)
    }
    
    var body: some ReducerOf<Self> {
        Reduce { state, action in
            switch action {
            case .startRendering:
                state.isRendering = true
                return .none
                
            case .stopRendering:
                state.isRendering = false
                return .none
                
            case let .setFocalLength(focalLength):
                state.focalLength = focalLength
                return .none
                
            case let .updateRotation(rotation):
                state.rotation = rotation
                return .none
                
            case let .updateScale(scale):
                state.scale = scale
                return .none
                
            case let .errorOccurred(error):
                state.error = error
                return .none
            }
        }
    }
}

enum FocalLength: String, CaseIterable, Equatable {
    case fisheye = "魚眼"
    case wide24mm = "24mm"
    case normal50mm = "50mm"
    case tele85mm = "85mm"
    case parallel = "平行投影"
}