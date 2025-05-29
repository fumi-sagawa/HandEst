import Foundation

/// 手のトラッキング結果を統合したデータモデル
public struct HandTrackingResult: Equatable, Codable {
    /// 検出された手のポーズデータ
    public let poses: [HandPose]
    
    /// 手の左右判別データ
    public let handednessData: MultiHandednessData
    
    /// フレームの処理時間（ミリ秒）
    public let processingTimeMs: Double
    
    /// フレームのタイムスタンプ
    public let timestamp: Date
    
    /// フレームの画像サイズ
    public let frameSize: CGSize
    
    public init(
        poses: [HandPose],
        handednessData: MultiHandednessData,
        processingTimeMs: Double,
        frameSize: CGSize,
        timestamp: Date = Date()
    ) {
        self.poses = poses
        self.handednessData = handednessData
        self.processingTimeMs = processingTimeMs
        self.frameSize = frameSize
        self.timestamp = timestamp
    }
    
    /// 左手のポーズを取得
    public var leftHandPose: HandPose? {
        guard let leftHandIndex = handednessData.hands.firstIndex(where: { $0.handType == .left }),
              leftHandIndex < poses.count else {
            return nil
        }
        return poses[leftHandIndex]
    }
    
    /// 右手のポーズを取得
    public var rightHandPose: HandPose? {
        guard let rightHandIndex = handednessData.hands.firstIndex(where: { $0.handType == .right }),
              rightHandIndex < poses.count else {
            return nil
        }
        return poses[rightHandIndex]
    }
    
    /// 検出された手の数
    public var detectedHandsCount: Int {
        return poses.count
    }
    
    /// 両手が検出されているか
    public var hasBothHands: Bool {
        return leftHandPose != nil && rightHandPose != nil
    }
    
    /// フレームレート（FPS）を計算
    public var estimatedFPS: Double {
        return processingTimeMs > 0 ? 1_000.0 / processingTimeMs : 0
    }
    
    /// 最も信頼度の高い手のポーズを取得
    public var mostConfidentPose: HandPose? {
        return poses.max { $0.overallConfidence < $1.overallConfidence }
    }
    
    /// 特定の手のポーズとハンドネスデータをペアで取得
    public func handData(for handType: HandType) -> (pose: HandPose, handednessData: HandednessData)? {
        guard let handIndex = handednessData.hands.firstIndex(where: { $0.handType == handType }),
              handIndex < poses.count else {
            return nil
        }
        return (poses[handIndex], handednessData.hands[handIndex])
    }
}

/// トラッキング結果の履歴を管理する構造体
public struct HandTrackingHistory: Equatable, Codable {
    /// 履歴に保持する最大フレーム数
    public let maxFrames: Int
    
    /// トラッキング結果の履歴
    public private(set) var results: [HandTrackingResult]
    
    public init(maxFrames: Int = 30) {
        self.maxFrames = maxFrames
        self.results = []
    }
    
    /// 新しい結果を追加
    public mutating func append(_ result: HandTrackingResult) {
        results.append(result)
        if results.count > maxFrames {
            results.removeFirst()
        }
    }
    
    /// 履歴をクリア
    public mutating func clear() {
        results.removeAll()
    }
    
    /// 平均処理時間を計算
    public var averageProcessingTimeMs: Double {
        guard !results.isEmpty else { return 0 }
        let totalTime = results.map { $0.processingTimeMs }.reduce(0, +)
        return totalTime / Double(results.count)
    }
    
    /// 平均FPSを計算
    public var averageFPS: Double {
        return averageProcessingTimeMs > 0 ? 1_000.0 / averageProcessingTimeMs : 0
    }
    
    /// 最新の結果を取得
    public var latest: HandTrackingResult? {
        return results.last
    }
    
    /// 手の検出率を計算
    public var detectionRate: Double {
        guard !results.isEmpty else { return 0 }
        let detectedCount = results.filter { $0.detectedHandsCount > 0 }.count
        return Double(detectedCount) / Double(results.count)
    }
}