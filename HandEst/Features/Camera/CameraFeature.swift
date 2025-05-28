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
        
        static func == (lhs: State, rhs: State) -> Bool {
            lhs.authorizationStatus == rhs.authorizationStatus &&
            lhs.isCameraActive == rhs.isCameraActive &&
            lhs.currentCameraPosition == rhs.currentCameraPosition &&
            lhs.error == rhs.error &&
            lhs.isVideoDataOutputActive == rhs.isVideoDataOutputActive &&
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
                guard state.isCameraActive, !state.isVideoDataOutputActive else { return .none }
                
                return .run { send in
                    do {
                        try await cameraManager.startVideoDataOutput { pixelBuffer in
                            Task {
                                await send(.frameReceived(pixelBuffer))
                            }
                        }
                        await send(.videoDataOutputStarted)
                    } catch {
                        await send(.errorOccurred(.camera(.videoDataOutputFailed(error.localizedDescription))))
                    }
                }
                
            case .stopVideoDataOutput:
                guard state.isVideoDataOutputActive else { return .none }
                
                return .run { send in
                    await cameraManager.stopVideoDataOutput()
                    await send(.videoDataOutputStopped)
                }
                
            case .frameReceived:
                // フレームを受信したが、CameraFeature自体では処理しない
                // AppFeatureで処理するため、ここではnoneを返す
                return .none
                
            case .videoDataOutputStarted:
                state.isVideoDataOutputActive = true
                return .none
                
            case .videoDataOutputStopped:
                state.isVideoDataOutputActive = false
                return .none
            }
        }
    }
}