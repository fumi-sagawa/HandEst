import Foundation

/// 手の左右判別データを表す構造体
public struct HandednessData: Equatable, Codable {
    /// 手の左右
    public let handType: HandType
    
    /// 判別の信頼度スコア（0.0-1.0）
    public let confidence: Float
    
    public init(handType: HandType, confidence: Float) {
        self.handType = handType
        self.confidence = min(max(confidence, 0), 1) // 0-1の範囲にクランプ
    }
    
    /// 高い信頼度で判別できているかを判定
    /// - Parameter threshold: 信頼度の閾値（デフォルト: 0.8）
    /// - Returns: 閾値以上の信頼度の場合true
    public func isReliable(threshold: Float = 0.8) -> Bool {
        return confidence >= threshold
    }
}

/// 手の左右を表す列挙型
public enum HandType: String, CaseIterable, Codable {
    case left = "左手"
    case right = "右手"
    case unknown = "不明"
    
    /// 反対の手を取得
    public var opposite: HandType {
        switch self {
        case .left:
            return .right
        case .right:
            return .left
        case .unknown:
            return .unknown
        }
    }
    
    /// 英語表記を取得
    public var englishName: String {
        switch self {
        case .left:
            return "Left"
        case .right:
            return "Right"
        case .unknown:
            return "Unknown"
        }
    }
}

/// 複数の手の判別結果を管理する構造体
public struct MultiHandednessData: Equatable, Codable {
    /// 検出された手の判別データ配列
    public let hands: [HandednessData]
    
    public init(hands: [HandednessData]) {
        self.hands = hands
    }
    
    /// 左手のデータを取得
    public var leftHand: HandednessData? {
        return hands.first { $0.handType == .left }
    }
    
    /// 右手のデータを取得
    public var rightHand: HandednessData? {
        return hands.first { $0.handType == .right }
    }
    
    /// 両手が検出されているかを判定
    public var hasBothHands: Bool {
        return leftHand != nil && rightHand != nil
    }
    
    /// 検出された手の数
    public var detectedHandsCount: Int {
        return hands.count
    }
    
    /// 最も信頼度の高い手のデータを取得
    public var mostConfidentHand: HandednessData? {
        return hands.max { $0.confidence < $1.confidence }
    }
}