import ComposableArchitecture
import Foundation
import RealityKit

@Reducer
struct RenderingFeature {
    @ObservableState
    struct State: Equatable {
        // RealityKit関連
        var isInitialized: Bool = false
        var currentHandLandmarks: [HandLandmark]?
        var modelType: ModelType = .simple
        var renderingError: RenderingError?
        
        // 変換・表示関連
        var focalLength: FocalLength = .normal50mm
        var rotation: Float = 0
        var scale: Float = 1.0
        var isRendering = false
        
        // その他
        var error: String?
    }
    
    enum Action: Equatable {
        // 初期化関連
        case initializeRealityKit
        case realityKitInitialized
        case initializationFailed(RenderingError)
        
        // レンダリング制御
        case startRendering
        case stopRendering
        
        // モデル更新
        case updateHandLandmarks([HandLandmark])
        case setModelType(ModelType)
        
        // 変換・表示制御
        case setFocalLength(FocalLength)
        case updateRotation(Float)
        case updateScale(Float)
        
        // エラー処理
        case errorOccurred(String)
        case renderingErrorOccurred(RenderingError)
        case clearError
    }
    
    @Dependency(\.renderingClient) var renderingClient
    
    var body: some ReducerOf<Self> {
        Reduce { state, action in
            switch action {
            // 初期化関連
            case .initializeRealityKit:
                return .run { send in
                    do {
                        try await renderingClient.initializeScene()
                        await send(.realityKitInitialized)
                    } catch {
                        let renderingError = error as? RenderingError ?? .initializationFailed(error.localizedDescription)
                        await send(.initializationFailed(renderingError))
                    }
                }
                
            case .realityKitInitialized:
                state.isInitialized = true
                state.renderingError = nil
                return .none
                
            case let .initializationFailed(error):
                state.isInitialized = false
                state.renderingError = error
                return .none
                
            // レンダリング制御
            case .startRendering:
                state.isRendering = true
                return .none
                
            case .stopRendering:
                state.isRendering = false
                return .none
                
            // モデル更新
            case let .updateHandLandmarks(landmarks):
                state.currentHandLandmarks = landmarks
                return .none
                
            case let .setModelType(modelType):
                state.modelType = modelType
                return .none
                
            // 変換・表示制御
            case let .setFocalLength(focalLength):
                state.focalLength = focalLength
                return .none
                
            case let .updateRotation(rotation):
                state.rotation = rotation
                return .none
                
            case let .updateScale(scale):
                state.scale = scale
                return .none
                
            // エラー処理
            case let .errorOccurred(error):
                state.error = error
                return .none
                
            case let .renderingErrorOccurred(error):
                state.renderingError = error
                state.error = error.localizedDescription
                return .none
                
            case .clearError:
                state.error = nil
                state.renderingError = nil
                return .none
            }
        }
    }
}