import AVFoundation
import ComposableArchitecture
import CoreVideo
import Foundation
import SwiftUI

@Reducer
struct CameraFeature {
    @ObservableState
    struct State: Equatable {
        var authorizationStatus: AVAuthorizationStatus = .notDetermined
        var isCameraActive = false
        var currentCameraPosition: AVCaptureDevice.Position = .back
        var error: AppError?
        var captureSession: AVCaptureSession?
        var isVideoDataOutputActive = false
        
        // 露出情報と照明環境
        var currentExposureInfo: ExposureInfo? = nil
        var lightingCondition: LightingCondition = .good
        var shouldShowLightingWarning: Bool = false
        
        static func == (lhs: State, rhs: State) -> Bool {
            lhs.authorizationStatus == rhs.authorizationStatus &&
            lhs.isCameraActive == rhs.isCameraActive &&
            lhs.currentCameraPosition == rhs.currentCameraPosition &&
            lhs.error == rhs.error &&
            lhs.isVideoDataOutputActive == rhs.isVideoDataOutputActive &&
            lhs.currentExposureInfo == rhs.currentExposureInfo &&
            lhs.lightingCondition == rhs.lightingCondition &&
            lhs.shouldShowLightingWarning == rhs.shouldShowLightingWarning &&
            ObjectIdentifier(lhs.captureSession as AnyObject) == ObjectIdentifier(rhs.captureSession as AnyObject)
        }
        
        var isAuthorized: Bool {
            authorizationStatus == .authorized
        }
        
        var shouldShowPermissionAlert: Bool {
            authorizationStatus == .denied
        }
        
        var canStartCamera: Bool {
            isAuthorized && !isCameraActive
        }
    }
    
    enum Action: Equatable {
        case onAppear
        case checkAuthorizationStatus
        case authorizationStatusReceived(AVAuthorizationStatus)
        case requestPermission
        case permissionReceived(Bool)
        case startCamera
        case stopCamera
        case switchCamera
        case cameraStarted(AVCaptureSession)
        case cameraStopped
        case cameraSwitched(AVCaptureDevice.Position)
        case errorOccurred(AppError)
        case clearError
        case scenePhaseChanged(ScenePhase)
        
        // ビデオデータ出力関連
        case startVideoDataOutput
        case stopVideoDataOutput
        case frameReceived(CVPixelBuffer)
        case videoDataOutputStarted
        case videoDataOutputStopped
        
        // 露出情報関連
        case exposureInfoReceived(ExposureInfo)
        case lightingConditionChanged(LightingCondition)
        case dismissLightingWarning
    }
    
    @Dependency(\.cameraManager) var cameraManager
    
    var body: some ReducerOf<Self> {
        Reduce { state, action in
            switch action {
            case .onAppear:
                return .run { send in
                    await send(.checkAuthorizationStatus)
                }
                
            case .checkAuthorizationStatus:
                return .run { send in
                    let status = await cameraManager.checkAuthorizationStatus()
                    await send(.authorizationStatusReceived(status))
                }
                
            case let .authorizationStatusReceived(status):
                state.authorizationStatus = status
                if status == .authorized && !state.isCameraActive {
                    return .run { send in
                        await send(.startCamera)
                    }
                }
                return .none
                
            case .requestPermission:
                return .run { send in
                    let granted = await cameraManager.requestPermission()
                    await send(.permissionReceived(granted))
                }
                
            case let .permissionReceived(granted):
                state.authorizationStatus = granted ? .authorized : .denied
                if granted {
                    return .run { send in
                        await send(.startCamera)
                    }
                }
                return .none
                
            case .startCamera:
                guard state.canStartCamera else { return .none }
                
                return .run { send in
                    do {
                        try await cameraManager.startSession()
                        if let session = await cameraManager.getCaptureSession() {
                            await send(.cameraStarted(session))
                        }
                    } catch let error as AppError {
                        await send(.errorOccurred(error))
                    } catch {
                        await send(.errorOccurred(.camera(.unknown(error.localizedDescription))))
                    }
                }
                
            case let .cameraStarted(session):
                state.isCameraActive = true
                state.captureSession = session
                state.error = nil
                return .none
                
            case .stopCamera:
                return .run { send in
                    await cameraManager.stopSession()
                    await send(.cameraStopped)
                }
                
            case .cameraStopped:
                state.isCameraActive = false
                state.captureSession = nil
                return .none
                
            case .switchCamera:
                guard state.isCameraActive else { return .none }
                
                return .run { send in
                    do {
                        try await cameraManager.switchCamera()
                        let position = await cameraManager.getCurrentCameraPosition()
                        await send(.cameraSwitched(position))
                    } catch let error as AppError {
                        await send(.errorOccurred(error))
                    } catch {
                        await send(.errorOccurred(.camera(.unknown(error.localizedDescription))))
                    }
                }
                
            case let .cameraSwitched(position):
                state.currentCameraPosition = position
                return .none
                
            case let .errorOccurred(error):
                state.error = error
                state.isCameraActive = false
                state.captureSession = nil
                return .none
                
            case .clearError:
                state.error = nil
                return .none
                
            case let .scenePhaseChanged(phase):
                switch phase {
                case .background, .inactive:
                    if state.isCameraActive {
                        return .run { send in
                            await send(.stopCamera)
                        }
                    }
                case .active:
                    if state.isAuthorized && !state.isCameraActive {
                        return .run { send in
                            await send(.startCamera)
                        }
                    }
                @unknown default:
                    return .none
                }
                return .none
                
            // ビデオデータ出力関連
            case .startVideoDataOutput:
                AppLogger.shared.info("ビデオデータ出力開始リクエスト - カメラアクティブ: \(state.isCameraActive), 出力アクティブ: \(state.isVideoDataOutputActive)", category: .camera)
                guard state.isCameraActive, !state.isVideoDataOutputActive else { 
                    AppLogger.shared.warning("ビデオデータ出力開始できません - カメラアクティブ: \(state.isCameraActive), 出力アクティブ: \(state.isVideoDataOutputActive)", category: .camera)
                    return .none 
                }
                
                // ビデオデータストリーミング用の長時間実行Effect（IDを付けて管理）
                struct VideoDataOutputID: Hashable {}
                
                return .run { send in
                    do {
                        AppLogger.shared.info("ビデオデータ出力を開始中...", category: .camera)
                        
                        // 露出情報監視付きのビデオデータ出力を開始
                        let stream = AsyncStream<CVPixelBuffer> { continuation in
                            Task {
                                do {
                                    try await cameraManager.startVideoDataOutputWithExposureMonitoring(
                                        { pixelBuffer in
                                            // ストリームにフレームを送信
                                            continuation.yield(pixelBuffer)
                                        },
                                        { exposureInfo in
                                            // 露出情報を受信したEffectを通じて送信
                                            Task {
                                                await send(.exposureInfoReceived(exposureInfo))
                                            }
                                        }
                                    )
                                } catch {
                                    AppLogger.shared.error("ビデオデータ出力エラー: \(error)", category: .camera)
                                    continuation.finish()
                                }
                            }
                        }
                        
                        await send(.videoDataOutputStarted)
                        
                        // ストリームからフレームを受信し続ける
                        for await pixelBuffer in stream {
                            // コールバックが呼ばれたことをログ（頻度を制限）
                            if Int.random(in: 0..<30) == 0 {  // 30フレームに1回ログ
                                AppLogger.shared.debug("CameraFeature: フレーム受信", category: .camera)
                            }
                            await send(.frameReceived(pixelBuffer))
                        }
                        
                    } catch {
                        AppLogger.shared.error("ビデオデータ出力開始失敗: \(error)", category: .camera)
                        await send(.errorOccurred(.camera(.videoDataOutputFailed(error.localizedDescription))))
                    }
                }
                .cancellable(id: VideoDataOutputID())
                
            case .stopVideoDataOutput:
                guard state.isVideoDataOutputActive else { return .none }
                
                struct VideoDataOutputID: Hashable {}
                
                return .concatenate(
                    // 既存のビデオデータ出力Effectをキャンセル
                    .cancel(id: VideoDataOutputID()),
                    // その後、stopVideoDataOutputを実行
                    .run { send in
                        await cameraManager.stopVideoDataOutput()
                        await send(.videoDataOutputStopped)
                    }
                )
                
            case .frameReceived:
                // フレームを受信したが、CameraFeature自体では処理しない
                // AppFeatureで処理するため、ここではnoneを返す
                if Int.random(in: 0..<30) == 0 {  // 30フレームに1回ログ
                    AppLogger.shared.debug("CameraFeature: フレーム受信", category: .camera)
                }
                return .none
                
            case .videoDataOutputStarted:
                AppLogger.shared.info("ビデオデータ出力が開始されました", category: .camera)
                state.isVideoDataOutputActive = true
                return .none
                
            case .videoDataOutputStopped:
                state.isVideoDataOutputActive = false
                return .none
                
            // 露出情報関連の処理
            case let .exposureInfoReceived(exposureInfo):
                state.currentExposureInfo = exposureInfo
                let newCondition = exposureInfo.lightingCondition
                
                // 照明環境が変わった場合のみ警告を更新
                if state.lightingCondition != newCondition {
                    return .run { send in
                        await send(.lightingConditionChanged(newCondition))
                    }
                }
                return .none
                
            case let .lightingConditionChanged(condition):
                state.lightingCondition = condition
                
                // 警告を表示すべきか判定
                let shouldWarn = condition.shouldShowWarning
                if shouldWarn != state.shouldShowLightingWarning {
                    state.shouldShowLightingWarning = shouldWarn
                    
                    if shouldWarn {
                        AppLogger.shared.warning("低照度環境を検出: \(condition.rawValue)", category: .camera)
                    } else {
                        AppLogger.shared.info("照明環境が改善: \(condition.rawValue)", category: .camera)
                    }
                }
                return .none
                
            case .dismissLightingWarning:
                state.shouldShowLightingWarning = false
                return .none
            }
        }
    }
}