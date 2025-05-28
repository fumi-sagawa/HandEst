import ComposableArchitecture
import CoreVideo
import Foundation

@Reducer
struct HandTrackingFeature {
    @ObservableState
    struct State: Equatable {
        // トラッキング状態
        var isTracking = false
        var isPoseLocked = false
        var handedness: Handedness = .right
        
        // MediaPipe統合
        var isMediaPipeInitialized = false
        var currentResult: HandTrackingResult?
        var trackingHistory = HandTrackingHistory(maxFrames: 30)
        
        // パフォーマンス監視
        var performanceMetrics = PerformanceMetrics()
        
        // エラー管理
        var error: MediaPipeError?
        
        // デバッグ情報
        var isDebugMode = false
        var debugInfo: DebugInfo?
    }
    
    enum Action: Equatable {
        // 基本制御
        case onAppear
        case onDisappear
        case startTracking
        case stopTracking
        case togglePoseLock
        case setHandedness(Handedness)
        
        // MediaPipe関連
        case initializeMediaPipe
        case mediaPipeInitialized(Bool)
        case processFrame(CVPixelBuffer)
        case trackingResult(HandTrackingResult)
        case trackingError(MediaPipeError)
        
        // パフォーマンス
        case updatePerformanceMetrics
        
        // デバッグ
        case toggleDebugMode
        case clearError
    }
    
    @Dependency(\.mediaPipeClient) var mediaPipeClient
    
    var body: some ReducerOf<Self> {
        Reduce { state, action in
            switch action {
            case .onAppear:
                return .run { send in
                    await send(.initializeMediaPipe)
                }
                
            case .onDisappear:
                return .merge(
                    .send(.stopTracking),
                    .run { _ in
                        await mediaPipeClient.shutdown()
                    }
                )
                
            case .initializeMediaPipe:
                return .run { send in
                    do {
                        try await mediaPipeClient.initialize()
                        let isInitialized = await mediaPipeClient.isInitialized()
                        await send(.mediaPipeInitialized(isInitialized))
                    } catch {
                        let mediaPipeError = error as? MediaPipeError ?? .unknown(error.localizedDescription)
                        await send(.trackingError(mediaPipeError))
                    }
                }
                
            case let .mediaPipeInitialized(isInitialized):
                state.isMediaPipeInitialized = isInitialized
                state.error = nil
                return .none
                
            case .startTracking:
                guard state.isMediaPipeInitialized else {
                    state.error = .notInitialized
                    return .none
                }
                state.isTracking = true
                state.error = nil
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
                
            case let .processFrame(pixelBuffer):
                guard state.isTracking, !state.isPoseLocked else {
                    return .none
                }
                
                return .run { send in
                    do {
                        if let result = try await mediaPipeClient.processFrame(pixelBuffer) {
                            await send(.trackingResult(result))
                        }
                    } catch {
                        let mediaPipeError = error as? MediaPipeError ?? .unknown(error.localizedDescription)
                        await send(.trackingError(mediaPipeError))
                    }
                }
                
            case let .trackingResult(result):
                // 結果を状態に反映
                state.currentResult = result
                state.trackingHistory.append(result)
                
                // パフォーマンスメトリクスを更新
                return .send(.updatePerformanceMetrics)
                
            case let .trackingError(error):
                state.error = error
                AppLogger.shared.error("手認識エラー: \(error.errorDescription ?? error.localizedDescription)", category: .handTracking)
                return .none
                
            case .updatePerformanceMetrics:
                // パフォーマンスメトリクスを計算
                if let result = state.currentResult {
                    state.performanceMetrics.currentFPS = result.estimatedFPS
                    state.performanceMetrics.processingTimeMs = result.processingTimeMs
                    state.performanceMetrics.totalFramesProcessed += 1
                }
                
                // 平均値を計算
                state.performanceMetrics.averageFPS = state.trackingHistory.averageFPS
                state.performanceMetrics.detectionRate = state.trackingHistory.detectionRate
                
                // デバッグ情報を更新
                if state.isDebugMode {
                    updateDebugInfo(&state)
                    logTrackingResult(state.currentResult)
                }
                
                return .none
                
            case .toggleDebugMode:
                state.isDebugMode.toggle()
                return .none
                
            case .clearError:
                state.error = nil
                return .none
            }
        }
    }
    
    /// デバッグ情報を更新
    private func updateDebugInfo(_ state: inout State) {
        guard let result = state.currentResult else {
            state.debugInfo = nil
            return
        }
        
        var debugInfo = DebugInfo()
        debugInfo.detectedHandsCount = result.detectedHandsCount
        
        // 左右手の信頼度を取得
        if let leftData = result.handednessData.hands.first(where: { $0.handType == .left }) {
            debugInfo.leftHandConfidence = leftData.confidence
        }
        if let rightData = result.handednessData.hands.first(where: { $0.handType == .right }) {
            debugInfo.rightHandConfidence = rightData.confidence
        }
        
        // 主要ランドマークを取得
        let primaryTypes: [LandmarkType] = [.wrist, .thumbTip, .indexTip, .middleTip]
        var primaryLandmarks: [LandmarkDebugInfo] = []
        
        for pose in result.poses {
            for type in primaryTypes {
                let landmark = pose[type]
                let position = CGPoint(
                    x: CGFloat(landmark.x) * result.frameSize.width,
                    y: CGFloat(landmark.y) * result.frameSize.height
                )
                primaryLandmarks.append(
                    LandmarkDebugInfo(
                        type: type,
                        position: position,
                        confidence: landmark.confidence
                    )
                )
            }
        }
        
        debugInfo.primaryLandmarks = primaryLandmarks
        state.debugInfo = debugInfo
    }
    
    /// トラッキング結果をログ出力
    private func logTrackingResult(_ result: HandTrackingResult?) {
        guard let result = result else { return }
        
        let logger = AppLogger.shared
        
        // 基本情報
        logger.info("検出された手の数: \(result.detectedHandsCount)", category: .handTracking)
        logger.info("FPS: \(String(format: "%.1f", result.estimatedFPS))", category: .handTracking)
        logger.info("処理時間: \(String(format: "%.1f", result.processingTimeMs))ms", category: .handTracking)
        
        // 各手の詳細情報
        if let leftHand = result.leftHandPose {
            let confidence = result.handednessData.hands.first(where: { $0.handType == .left })?.confidence ?? 0
            logger.info("左手 - 信頼度: \(String(format: "%.2f", confidence))", category: .handTracking)
            logPrimaryLandmarks(leftHand, handType: "左手")
        }
        
        if let rightHand = result.rightHandPose {
            let confidence = result.handednessData.hands.first(where: { $0.handType == .right })?.confidence ?? 0
            logger.info("右手 - 信頼度: \(String(format: "%.2f", confidence))", category: .handTracking)
            logPrimaryLandmarks(rightHand, handType: "右手")
        }
    }
    
    /// 主要ランドマークをログ出力
    private func logPrimaryLandmarks(_ pose: HandPose, handType: String) {
        let logger = AppLogger.shared
        
        // 主要ランドマークのみログ出力
        let primaryLandmarks: [LandmarkType] = [.wrist, .thumbTip, .indexTip, .middleTip]
        
        for landmarkType in primaryLandmarks {
            let landmark = pose[landmarkType]
            logger.debug(
                "\(handType) - \(landmarkType): (\(String(format: "%.3f", landmark.x)), \(String(format: "%.3f", landmark.y)), \(String(format: "%.3f", landmark.z)))",
                category: .handTracking
            )
        }
    }
}

