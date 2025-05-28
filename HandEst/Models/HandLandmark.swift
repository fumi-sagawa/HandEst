import Foundation

/// MediaPipe Hand Landmarkerから取得される個々の関節点を表すデータモデル
public struct HandLandmark: Equatable, Codable {
    /// X座標（0.0-1.0の正規化座標）
    public let x: Float
    
    /// Y座標（0.0-1.0の正規化座標）
    public let y: Float
    
    /// Z座標（カメラからの相対的な深度）
    public let z: Float
    
    /// ランドマークの信頼度スコア（0.0-1.0）
    public let confidence: Float
    
    /// ランドマークのタイプ（関節の種類）
    public let type: LandmarkType
    
    public init(x: Float, y: Float, z: Float, confidence: Float = 1.0, type: LandmarkType) {
        self.x = x
        self.y = y
        self.z = z
        self.confidence = confidence
        self.type = type
    }
    
    /// 画面座標系への変換
    /// - Parameters:
    ///   - width: 画面の幅
    ///   - height: 画面の高さ
    /// - Returns: 画面座標系でのポイント
    public func toScreenCoordinates(width: CGFloat, height: CGFloat) -> CGPoint {
        return CGPoint(
            x: CGFloat(x) * width,
            y: CGFloat(y) * height
        )
    }
    
    /// 信頼度が閾値以上かどうかを判定
    /// - Parameter threshold: 閾値（デフォルト: 0.5）
    /// - Returns: 閾値以上の場合true
    public func isConfident(threshold: Float = 0.5) -> Bool {
        return confidence >= threshold
    }
}

/// 手の関節点タイプを表す列挙型
public enum LandmarkType: Int, CaseIterable, Codable {
    // 手首
    case wrist = 0
    
    // 親指
    case thumbCMC = 1
    case thumbMCP = 2
    case thumbIP = 3
    case thumbTip = 4
    
    // 人差し指
    case indexMCP = 5
    case indexPIP = 6
    case indexDIP = 7
    case indexTip = 8
    
    // 中指
    case middleMCP = 9
    case middlePIP = 10
    case middleDIP = 11
    case middleTip = 12
    
    // 薬指
    case ringMCP = 13
    case ringPIP = 14
    case ringDIP = 15
    case ringTip = 16
    
    // 小指
    case pinkyMCP = 17
    case pinkyPIP = 18
    case pinkyDIP = 19
    case pinkyTip = 20
    
    /// 関節点の日本語名を取得
    public var japaneseName: String {
        switch self {
        case .wrist: return "手首"
        case .thumbCMC: return "親指CM関節"
        case .thumbMCP: return "親指MP関節"
        case .thumbIP: return "親指IP関節"
        case .thumbTip: return "親指先端"
        case .indexMCP: return "人差し指MP関節"
        case .indexPIP: return "人差し指PIP関節"
        case .indexDIP: return "人差し指DIP関節"
        case .indexTip: return "人差し指先端"
        case .middleMCP: return "中指MP関節"
        case .middlePIP: return "中指PIP関節"
        case .middleDIP: return "中指DIP関節"
        case .middleTip: return "中指先端"
        case .ringMCP: return "薬指MP関節"
        case .ringPIP: return "薬指PIP関節"
        case .ringDIP: return "薬指DIP関節"
        case .ringTip: return "薬指先端"
        case .pinkyMCP: return "小指MP関節"
        case .pinkyPIP: return "小指PIP関節"
        case .pinkyDIP: return "小指DIP関節"
        case .pinkyTip: return "小指先端"
        }
    }
    
    /// 指の種類を取得
    public var finger: Finger? {
        switch self {
        case .wrist:
            return nil
        case .thumbCMC, .thumbMCP, .thumbIP, .thumbTip:
            return .thumb
        case .indexMCP, .indexPIP, .indexDIP, .indexTip:
            return .index
        case .middleMCP, .middlePIP, .middleDIP, .middleTip:
            return .middle
        case .ringMCP, .ringPIP, .ringDIP, .ringTip:
            return .ring
        case .pinkyMCP, .pinkyPIP, .pinkyDIP, .pinkyTip:
            return .pinky
        }
    }
}

/// 指の種類を表す列挙型
public enum Finger: String, CaseIterable, Codable {
    case thumb = "親指"
    case index = "人差し指"
    case middle = "中指"
    case ring = "薬指"
    case pinky = "小指"
}