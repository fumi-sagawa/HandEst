import AVFoundation
import ComposableArchitecture
import Foundation

struct CameraManager {
    var checkAuthorizationStatus: @Sendable () async -> AVAuthorizationStatus
    var requestPermission: @Sendable () async -> Bool
    var startSession: @Sendable () async throws -> Void
    var stopSession: @Sendable () async -> Void
    var isSessionRunning: @Sendable () async -> Bool
    var getCaptureSession: @Sendable () async -> AVCaptureSession?
    var switchCamera: @Sendable () async throws -> Void
    var getCurrentCameraPosition: @Sendable () async -> AVCaptureDevice.Position
    var setFrameDelegate: @Sendable (AVCaptureVideoDataOutputSampleBufferDelegate?) async -> Void
    var startFrameCapture: @Sendable () async -> Void
    var stopFrameCapture: @Sendable () async -> Void
    var startVideoDataOutput: @Sendable (@escaping (CVPixelBuffer) -> Void) async throws -> Void
    var stopVideoDataOutput: @Sendable () async -> Void
    var startVideoDataOutputWithExposureMonitoring: @Sendable (@escaping (CVPixelBuffer) -> Void, @escaping (ExposureInfo) -> Void) async throws -> Void
    var getCurrentExposureInfo: @Sendable () async -> ExposureInfo?
}

extension CameraManager: DependencyKey {
    @MainActor
    static let liveValue: CameraManager = {
        let manager = LiveCameraManager.shared
        return CameraManager(
            checkAuthorizationStatus: {
                await manager.checkAuthorizationStatus()
            },
            requestPermission: {
                await manager.requestPermission()
            },
            startSession: {
                try await manager.startSession()
            },
            stopSession: {
                await manager.stopSession()
            },
            isSessionRunning: {
                await manager.isSessionRunning()
            },
            getCaptureSession: {
                await manager.getCaptureSession()
            },
            switchCamera: {
                try await manager.switchCamera()
            },
            getCurrentCameraPosition: {
                await manager.getCurrentCameraPosition()
            },
            setFrameDelegate: { delegate in
                await manager.setFrameDelegate(delegate)
            },
            startFrameCapture: {
                await manager.startFrameCapture()
            },
            stopFrameCapture: {
                await manager.stopFrameCapture()
            },
            startVideoDataOutput: { callback in
                try await manager.startVideoDataOutput(callback: callback)
            },
            stopVideoDataOutput: {
                await manager.stopVideoDataOutput()
            },
            startVideoDataOutputWithExposureMonitoring: { frameCallback, exposureCallback in
                try await manager.startVideoDataOutputWithExposureMonitoring(frameCallback: frameCallback, exposureCallback: exposureCallback)
            },
            getCurrentExposureInfo: {
                await manager.getCurrentExposureInfo()
            }
        )
    }()
    
    static let testValue = CameraManager(
        checkAuthorizationStatus: { .authorized },
        requestPermission: { true },
        startSession: { },
        stopSession: { },
        isSessionRunning: { false },
        getCaptureSession: { return nil },
        switchCamera: { },
        getCurrentCameraPosition: { .back },
        setFrameDelegate: { _ in },
        startFrameCapture: { },
        stopFrameCapture: { },
        startVideoDataOutput: { _ in },
        stopVideoDataOutput: { },
        startVideoDataOutputWithExposureMonitoring: { _, _ in },
        getCurrentExposureInfo: { return nil }
    )
}

extension DependencyValues {
    var cameraManager: CameraManager {
        get { self[CameraManager.self] }
        set { self[CameraManager.self] = newValue }
    }
}

@MainActor
private final class LiveCameraManager: NSObject, ObservableObject {
    static let shared = LiveCameraManager()
    
    private let captureSession = AVCaptureSession()
    private var videoInput: AVCaptureDeviceInput?
    private var videoOutput: AVCaptureVideoDataOutput?
    private let videoOutputQueue = DispatchQueue(label: "com.handest.videoOutput", qos: .userInitiated)
    private let sessionQueue = DispatchQueue(label: "com.handest.session", qos: .userInitiated)
    private var frameDelegate: AVCaptureVideoDataOutputSampleBufferDelegate?
    private let logger = AppLogger.shared
    private var isStartingSession = false
    
    override private init() {
        super.init()
        // 初期化時の自動設定を削除
        // configureSession()はstartSession()で呼ばれる
    }
    
    func checkAuthorizationStatus() async -> AVAuthorizationStatus {
        return AVCaptureDevice.authorizationStatus(for: .video)
    }
    
    func requestPermission() async -> Bool {
        logger.info("カメラ権限をリクエスト中", category: .camera)
        
        let status = await AVCaptureDevice.requestAccess(for: .video)
        logger.info("カメラ権限リクエスト結果: \(status)", category: .camera)
        return status
    }
    
    func startSession() async throws {
        logger.info("カメラセッション開始を試行", category: .camera)
        
        // 並行実行防止
        guard !isStartingSession else {
            logger.warning("セッション開始処理が既に実行中", category: .camera)
            return
        }
        isStartingSession = true
        defer { isStartingSession = false }
        
        let authStatus = await checkAuthorizationStatus()
        guard authStatus == .authorized else {
            let error = AppError.permission(.cameraNotAuthorized)
            logger.error("カメラ権限なし: \(error.description)", category: .camera)
            throw error
        }
        
        guard !captureSession.isRunning else {
            logger.warning("カメラセッションは既に実行中", category: .camera)
            return
        }
        
        do {
            try await configureSession()
        } catch {
            let cameraError = AppError.camera(.captureSessionFailed)
            logger.error("カメラセッション設定失敗: \(error)", category: .camera)
            throw cameraError
        }
        
        // 設定完了後にバックグラウンドスレッドでstartRunningを実行
        await withCheckedContinuation { continuation in
            sessionQueue.async { [weak self] in
                guard let self = self else {
                    continuation.resume()
                    return
                }
                self.captureSession.startRunning()
                self.logger.info("カメラセッション開始完了", category: .camera)
                continuation.resume()
            }
        }
    }
    
    func stopSession() async {
        logger.info("カメラセッション停止", category: .camera)
        guard captureSession.isRunning else { return }
        
        // バックグラウンドスレッドでstopRunningを実行
        await withCheckedContinuation { continuation in
            sessionQueue.async { [weak self] in
                guard let self = self else {
                    continuation.resume()
                    return
                }
                self.captureSession.stopRunning()
                self.logger.info("カメラセッション停止完了", category: .camera)
                continuation.resume()
            }
        }
    }
    
    func isSessionRunning() async -> Bool {
        return captureSession.isRunning
    }
    
    func getCaptureSession() async -> AVCaptureSession? {
        return captureSession
    }
    
    func switchCamera() async throws {
        logger.info("カメラ切り替えを試行", category: .camera)
        
        guard let currentInput = videoInput else {
            throw AppError.camera(.configurationFailed)
        }
        
        let currentPosition = currentInput.device.position
        let newPosition: AVCaptureDevice.Position = currentPosition == .back ? .front : .back
        
        guard let newDevice = getCamera(for: newPosition) else {
            throw AppError.camera(.deviceNotAvailable)
        }
        
        do {
            let newInput = try AVCaptureDeviceInput(device: newDevice)
            
            captureSession.beginConfiguration()
            captureSession.removeInput(currentInput)
            
            if captureSession.canAddInput(newInput) {
                captureSession.addInput(newInput)
                videoInput = newInput
                logger.info("カメラ切り替え完了: \(newPosition)", category: .camera)
            } else {
                captureSession.addInput(currentInput)
                throw AppError.camera(.configurationFailed)
            }
            
            captureSession.commitConfiguration()
        } catch {
            captureSession.commitConfiguration()
            logger.error("カメラ切り替え失敗: \(error)", category: .camera)
            throw AppError.camera(.configurationFailed)
        }
    }
    
    func getCurrentCameraPosition() async -> AVCaptureDevice.Position {
        return videoInput?.device.position ?? .back
    }
    
    private func configureSession() async throws {
        logger.info("カメラセッション設定開始", category: .camera)
        
        captureSession.beginConfiguration()
        defer { captureSession.commitConfiguration() }
        
        // 既存の入力を削除
        captureSession.inputs.forEach { captureSession.removeInput($0) }
        
        if captureSession.canSetSessionPreset(.high) {
            captureSession.sessionPreset = .high
        }
        
        do {
            guard let camera = getCamera(for: .back) else {
                logger.error("バックカメラが見つかりません", category: .camera)
                throw AppError.camera(.configurationFailed)
            }
            
            let input = try AVCaptureDeviceInput(device: camera)
            
            if captureSession.canAddInput(input) {
                captureSession.addInput(input)
                videoInput = input
                logger.info("カメラ入力設定完了", category: .camera)
            } else {
                logger.error("カメラ入力の追加に失敗", category: .camera)
                throw AppError.camera(.configurationFailed)
            }
            
            // ビデオ出力の設定
            configureVideoOutput()
            
        } catch {
            logger.error("カメラ入力設定エラー: \(error)", category: .camera)
            throw error
        }
        
        logger.info("カメラセッション設定完了", category: .camera)
    }
    
    private func configureVideoOutput() {
        let output = AVCaptureVideoDataOutput()
        output.videoSettings = [
            kCVPixelBufferPixelFormatTypeKey as String: kCVPixelFormatType_32BGRA
        ]
        output.alwaysDiscardsLateVideoFrames = true
        
        if captureSession.canAddOutput(output) {
            captureSession.addOutput(output)
            videoOutput = output
            logger.info("ビデオ出力設定完了", category: .camera)
        } else {
            logger.error("ビデオ出力の追加に失敗", category: .camera)
        }
    }
    
    private func getCamera(for position: AVCaptureDevice.Position) -> AVCaptureDevice? {
        let discoverySession = AVCaptureDevice.DiscoverySession(
            deviceTypes: [.builtInWideAngleCamera],
            mediaType: .video,
            position: position
        )
        return discoverySession.devices.first
    }
    
    func setFrameDelegate(_ delegate: AVCaptureVideoDataOutputSampleBufferDelegate?) async {
        frameDelegate = delegate
        videoOutput?.setSampleBufferDelegate(delegate, queue: videoOutputQueue)
        logger.info("フレームデリゲート設定: \(delegate != nil ? "設定" : "解除")", category: .camera)
    }
    
    func startFrameCapture() async {
        guard let output = videoOutput else {
            logger.warning("ビデオ出力が設定されていません", category: .camera)
            return
        }
        
        if frameDelegate != nil {
            output.setSampleBufferDelegate(frameDelegate, queue: videoOutputQueue)
            logger.info("フレームキャプチャ開始", category: .camera)
        }
    }
    
    func stopFrameCapture() async {
        videoOutput?.setSampleBufferDelegate(nil, queue: nil)
        logger.info("フレームキャプチャ停止", category: .camera)
    }
    
    private var frameCallback: ((CVPixelBuffer) -> Void)?
    
    func startVideoDataOutput(callback: @escaping (CVPixelBuffer) -> Void) async throws {
        frameCallback = callback
        
        // デリゲートとしてself（LiveCameraManager）を設定
        let delegate = VideoDataOutputDelegate(callback: callback, cameraManager: self)
        await setFrameDelegate(delegate)
        // startFrameCaptureはsetFrameDelegateで既にデリゲートが設定されているため不要
        // await startFrameCapture()
        
        logger.info("ビデオデータ出力開始", category: .camera)
    }
    
    func startVideoDataOutputWithExposureMonitoring(frameCallback: @escaping (CVPixelBuffer) -> Void, exposureCallback: @escaping (ExposureInfo) -> Void) async throws {
        self.frameCallback = frameCallback
        
        // 露出情報監視付きのデリゲートを設定
        let delegate = VideoDataOutputDelegate(callback: frameCallback, exposureCallback: exposureCallback, cameraManager: self)
        await setFrameDelegate(delegate)
        
        logger.info("露出情報監視付きビデオデータ出力開始", category: .camera)
    }
    
    func stopVideoDataOutput() async {
        frameCallback = nil
        await setFrameDelegate(nil)
        await stopFrameCapture()
        
        logger.info("ビデオデータ出力停止", category: .camera)
    }
    
    func getCurrentExposureInfo() async -> ExposureInfo? {
        guard let device = videoInput?.device else {
            logger.warning("カメラデバイスが設定されていません", category: .camera)
            return nil
        }
        
        let iso = device.iso
        let exposureDuration = device.exposureDuration.seconds
        let exposureBias = device.exposureTargetBias
        
        let exposureInfo = ExposureInfo(
            iso: iso,
            exposureDuration: exposureDuration,
            exposureBias: exposureBias
        )
        
        // デバッグ情報をログ出力（頻度を制限）
        if Int.random(in: 0..<60) == 0 {  // 60回に1回ログ
            logger.debug("露出情報 - ISO: \(iso), 露出時間: \(String(format: "%.6f", exposureDuration))s, 照明環境: \(exposureInfo.lightingCondition.rawValue)", category: .camera)
        }
        
        return exposureInfo
    }
}

// ビデオデータ出力用のデリゲート
private class VideoDataOutputDelegate: NSObject, AVCaptureVideoDataOutputSampleBufferDelegate {
    private let callback: (CVPixelBuffer) -> Void
    private let exposureCallback: ((ExposureInfo) -> Void)?
    private weak var cameraManager: LiveCameraManager?
    
    init(callback: @escaping (CVPixelBuffer) -> Void, exposureCallback: ((ExposureInfo) -> Void)? = nil, cameraManager: LiveCameraManager? = nil) {
        self.callback = callback
        self.exposureCallback = exposureCallback
        self.cameraManager = cameraManager
    }
    
    func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        guard let pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else { 
            AppLogger.shared.warning("ピクセルバッファの取得に失敗", category: .camera)
            return 
        }
        // フレーム受信をログ（頻度を制限）
        if Int.random(in: 0..<30) == 0 {  // 30フレームに1回ログ
            AppLogger.shared.debug("フレーム受信", category: .camera)
        }
        
        // 露出情報を取得してコールバック（頻度を制限）
        if let exposureCallback = exposureCallback, Int.random(in: 0..<60) == 0 {  // 60フレームに1回
            Task {
                if let exposureInfo = await cameraManager?.getCurrentExposureInfo() {
                    exposureCallback(exposureInfo)
                }
            }
        }
        
        callback(pixelBuffer)
    }
}