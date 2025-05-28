import ComposableArchitecture
import CoreVideo
import Foundation
import MediaPipeTasksVision

/// MediaPipeのHandLandmarkerを管理するクライアントプロトコル
public protocol MediaPipeClientProtocol: Sendable {
    /// HandLandmarkerの初期化
    func initialize() async throws
    
    /// フレームを処理して手の位置を検出
    func processFrame(_ pixelBuffer: CVPixelBuffer) async throws -> HandTrackingResult?
    
    /// クライアントのシャットダウン
    func shutdown() async
    
    /// 初期化状態の確認
    var isInitialized: Bool { get async }
}

/// MediaPipeクライアントの設定オプション
public struct MediaPipeClientOptions: Equatable {
    /// 最大検出手数（1または2）
    public let maxNumHands: Int
    
    /// 最小検出信頼度（0.0-1.0）
    public let minDetectionConfidence: Float
    
    /// 最小トラッキング信頼度（0.0-1.0）
    public let minTrackingConfidence: Float
    
    /// 手の左右判別の最小信頼度閾値（0.0-1.0）
    public let minHandednessConfidence: Float
    
    /// 目標フレームレート（fps）
    public let targetFPS: Double
    
    /// デリゲートキュー（デフォルト: .main）
    public let runningMode: RunningMode
    
    public enum RunningMode: Equatable {
        case image
        case video
        case liveStream
    }
    
    public init(
        maxNumHands: Int = 2,
        minDetectionConfidence: Float = 0.5,
        minTrackingConfidence: Float = 0.5,
        minHandednessConfidence: Float = 0.8,
        targetFPS: Double = 30.0,
        runningMode: RunningMode = .liveStream
    ) {
        self.maxNumHands = min(max(1, maxNumHands), 2)
        self.minDetectionConfidence = min(max(0, minDetectionConfidence), 1)
        self.minTrackingConfidence = min(max(0, minTrackingConfidence), 1)
        self.minHandednessConfidence = min(max(0, minHandednessConfidence), 1)
        self.targetFPS = min(max(1, targetFPS), 120)
        self.runningMode = runningMode
    }
}

/// TCA Dependencyキー
public struct MediaPipeClient: DependencyKey {
    public var initialize: @Sendable () async throws -> Void
    public var processFrame: @Sendable (CVPixelBuffer) async throws -> HandTrackingResult?
    public var shutdown: @Sendable () async -> Void
    public var isInitialized: @Sendable () async -> Bool
    
    public static let liveValue = Self(
        initialize: {
            try await LiveMediaPipeClient.shared.initialize()
        },
        processFrame: { pixelBuffer in
            try await LiveMediaPipeClient.shared.processFrame(pixelBuffer)
        },
        shutdown: {
            await LiveMediaPipeClient.shared.shutdown()
        },
        isInitialized: {
            await LiveMediaPipeClient.shared.isInitialized
        }
    )
    
    public static let testValue = Self(
        initialize: { },
        processFrame: { _ in
            // テスト用のモックデータを返す
            HandTrackingResult.mockData()
        },
        shutdown: { },
        isInitialized: { true }
    )
}

public extension DependencyValues {
    var mediaPipeClient: MediaPipeClient {
        get { self[MediaPipeClient.self] }
        set { self[MediaPipeClient.self] = newValue }
    }
}

/// ライブ実装用のMediaPipeクライアント
actor LiveMediaPipeClient: MediaPipeClientProtocol {
    static let shared = LiveMediaPipeClient()
    
    private var handLandmarker: HandLandmarker?
    private let options: MediaPipeClientOptions
    private var lastProcessingTime: Date?
    private var processingQueue = DispatchQueue(label: "com.handest.mediapipe.processing", qos: .userInitiated)
    private var isProcessing = false
    
    nonisolated var isInitialized: Bool {
        get async {
            await handLandmarker != nil
        }
    }
    
    private init(options: MediaPipeClientOptions = MediaPipeClientOptions()) {
        self.options = options
    }
    
    func initialize() async throws {
        // HandLandmarkerのオプション設定
        let options = HandLandmarkerOptions()
        options.baseOptions.modelAssetPath = Bundle.main.path(forResource: "hand_landmarker", ofType: "task") ?? ""
        options.runningMode = mapRunningMode(self.options.runningMode)
        options.numHands = self.options.maxNumHands
        options.minHandDetectionConfidence = self.options.minDetectionConfidence
        options.minHandPresenceConfidence = self.options.minTrackingConfidence
        options.minTrackingConfidence = self.options.minTrackingConfidence
        
        do {
            handLandmarker = try HandLandmarker(options: options)
        } catch {
            throw MediaPipeError.initializationFailed(error.localizedDescription)
        }
    }
    
    func processFrame(_ pixelBuffer: CVPixelBuffer) async throws -> HandTrackingResult? {
        guard let handLandmarker = handLandmarker else {
            throw MediaPipeError.notInitialized
        }
        
        // フレームレート制御
        if let lastTime = lastProcessingTime {
            let minimumInterval = 1.0 / options.targetFPS
            let elapsedTime = Date().timeIntervalSince(lastTime)
            
            // 目標FPSを超えている場合はフレームをスキップ
            if elapsedTime < minimumInterval {
                return nil
            }
        }
        
        // 既に処理中の場合はスキップ（フレームドロップ）
        guard !isProcessing else {
            return nil
        }
        
        isProcessing = true
        defer { isProcessing = false }
        
        // 処理開始時刻を記録
        let startTime = Date()
        lastProcessingTime = startTime
        
        // MediaPipe用のイメージを作成
        let image = try createMPImage(from: pixelBuffer)
        
        // HandLandmarkerで処理を実行
        let result: HandLandmarkerResult
        do {
            switch options.runningMode {
            case .image, .video:
                result = try handLandmarker.detect(image: image)
            case .liveStream:
                // ライブストリームモードでは、現在のタイムスタンプを使用
                let timestampMs = Int(Date().timeIntervalSince1970 * 1000)
                result = try handLandmarker.detect(
                    videoFrame: image,
                    timestampInMilliseconds: timestampMs
                )
            }
        } catch {
            throw MediaPipeError.processingFailed(error.localizedDescription)
        }
        
        // 処理時間を計算
        let processingTime = Date().timeIntervalSince(startTime) * 1000 // ミリ秒に変換
        
        // 結果をHandTrackingResultに変換
        return convertToHandTrackingResult(result, processingTimeMs: processingTime, pixelBuffer: pixelBuffer)
    }
    
    private func createMPImage(from pixelBuffer: CVPixelBuffer) throws -> MPImage {
        do {
            return try MPImage(pixelBuffer: pixelBuffer)
        } catch {
            throw MediaPipeError.imageConversionFailed(error.localizedDescription)
        }
    }
    
    private func convertToHandTrackingResult(_ result: HandLandmarkerResult, processingTimeMs: Double, pixelBuffer: CVPixelBuffer) -> HandTrackingResult? {
        guard !result.landmarks.isEmpty else {
            return nil
        }
        
        var poses: [HandPose] = []
        var handednessDataArray: [HandednessData] = []
        
        for (index, landmarks) in result.landmarks.enumerated() {
            guard index < result.handedness.count else {
                continue
            }
            
            // Handednessデータを先にチェック
            guard let handedness = result.handedness[index].first else {
                continue
            }
            
            let handType: HandType = handedness.categoryName == "Left" ? .left : .right
            let score = handedness.score
            
            // 信頼度閾値をチェック
            guard score >= options.minHandednessConfidence else {
                continue
            }
            
            // ランドマークを変換（21個のランドマークに対応するtype付き）
            let handLandmarks = landmarks.enumerated().map { (landmarkIndex, landmark) in
                HandLandmark(
                    x: landmark.x,
                    y: landmark.y,
                    z: landmark.z,
                    confidence: Float(truncating: landmark.visibility ?? 0),
                    type: LandmarkType(rawValue: landmarkIndex) ?? .wrist
                )
            }
            
            // 21個のランドマークが揃っているか確認
            guard handLandmarks.count == 21 else {
                continue
            }
            
            // HandPoseを作成
            let handPose = HandPose(landmarks: handLandmarks)
            poses.append(handPose)
            
            // Handednessデータを追加
            handednessDataArray.append(HandednessData(handType: handType, confidence: score))
        }
        
        guard !poses.isEmpty else {
            return nil
        }
        
        // CVPixelBufferから実際のフレームサイズを取得
        let width = CVPixelBufferGetWidth(pixelBuffer)
        let height = CVPixelBufferGetHeight(pixelBuffer)
        let frameSize = CGSize(width: width, height: height)
        
        return HandTrackingResult(
            poses: poses,
            handednessData: MultiHandednessData(hands: handednessDataArray),
            processingTimeMs: processingTimeMs,
            frameSize: frameSize
        )
    }
    
    func shutdown() async {
        handLandmarker = nil
    }
    
    private func mapRunningMode(_ mode: MediaPipeClientOptions.RunningMode) -> RunningMode {
        switch mode {
        case .image:
            return .image
        case .video:
            return .video
        case .liveStream:
            return .liveStream
        }
    }
}

// MARK: - Test Helpers
private extension HandTrackingResult {
    static func mockData() -> HandTrackingResult {
        let landmarks = (0..<21).map { index in
            HandLandmark(
                x: Float.random(in: 0...1),
                y: Float.random(in: 0...1),
                z: Float.random(in: -0.1...0.1),
                confidence: 0.9,
                type: LandmarkType(rawValue: index)!
            )
        }
        
        let leftHandPose = HandPose(landmarks: landmarks)
        let handednessData = MultiHandednessData(
            hands: [HandednessData(handType: .left, confidence: 0.95)]
        )
        
        return HandTrackingResult(
            poses: [leftHandPose],
            handednessData: handednessData,
            processingTimeMs: 16.7,
            frameSize: CGSize(width: 640, height: 480)
        )
    }
}