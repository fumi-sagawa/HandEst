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
        runningMode: RunningMode = .liveStream
    ) {
        self.maxNumHands = min(max(1, maxNumHands), 2)
        self.minDetectionConfidence = min(max(0, minDetectionConfidence), 1)
        self.minTrackingConfidence = min(max(0, minTrackingConfidence), 1)
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
        
        // 結果をHandTrackingResultに変換
        return convertToHandTrackingResult(result)
    }
    
    private func createMPImage(from pixelBuffer: CVPixelBuffer) throws -> MPImage {
        do {
            return try MPImage(pixelBuffer: pixelBuffer)
        } catch {
            throw MediaPipeError.imageConversionFailed(error.localizedDescription)
        }
    }
    
    private func convertToHandTrackingResult(_ result: HandLandmarkerResult) -> HandTrackingResult? {
        guard !result.landmarks.isEmpty else {
            return nil
        }
        
        var poses: [HandPose] = []
        var handednessDataArray: [HandednessData] = []
        
        for (index, landmarks) in result.landmarks.enumerated() {
            guard index < result.handedness.count else {
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
            
            // Handednessデータを取得
            if let handedness = result.handedness[index].first {
                let handType: HandType = handedness.categoryName == "Left" ? .left : .right
                let score = handedness.score
                handednessDataArray.append(HandednessData(handType: handType, confidence: score))
            }
        }
        
        guard !poses.isEmpty else {
            return nil
        }
        
        let processingTime = Date().timeIntervalSince(Date()) * 1000 // 仮の処理時間
        
        return HandTrackingResult(
            poses: poses,
            handednessData: MultiHandednessData(hands: handednessDataArray),
            processingTimeMs: processingTime,
            frameSize: CGSize(width: 640, height: 480) // TODO: 実際のフレームサイズを取得
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