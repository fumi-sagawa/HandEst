import Foundation

/// デバッグ情報を管理する構造体
public struct DebugInfo: Equatable, Codable {
    /// 検出された手の数
    public var detectedHandsCount: Int
    
    /// 左手の信頼度
    public var leftHandConfidence: Float?
    
    /// 右手の信頼度
    public var rightHandConfidence: Float?
    
    /// 主要ランドマーク情報
    public var primaryLandmarks: [LandmarkDebugInfo]
    
    public init(
        detectedHandsCount: Int = 0,
        leftHandConfidence: Float? = nil,
        rightHandConfidence: Float? = nil,
        primaryLandmarks: [LandmarkDebugInfo] = []
    ) {
        self.detectedHandsCount = detectedHandsCount
        self.leftHandConfidence = leftHandConfidence
        self.rightHandConfidence = rightHandConfidence
        self.primaryLandmarks = primaryLandmarks
    }
}

/// ランドマークのデバッグ情報
public struct LandmarkDebugInfo: Equatable, Codable {
    /// ランドマークの種類
    public var type: LandmarkType
    
    /// 画面上の位置
    public var position: CGPoint
    
    /// 信頼度
    public var confidence: Float
    
    public init(type: LandmarkType, position: CGPoint, confidence: Float) {
        self.type = type
        self.position = position
        self.confidence = confidence
    }
}