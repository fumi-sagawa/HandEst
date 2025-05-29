import Foundation

/// 照明環境の状態を表す列挙型
public enum LightingCondition: String, CaseIterable, Equatable {
    case excellent = "優秀"    // ISO < 100, 露出時間 < 1/60
    case good = "良好"         // ISO < 400, 露出時間 < 1/30
    case fair = "普通"         // ISO < 800, 露出時間 < 1/15
    case poor = "暗い"         // ISO < 1600, 露出時間 < 1/8
    case veryPoor = "とても暗い" // それ以上
    
    /// 手の認識に適した照明環境かどうか
    public var isSuitableForHandTracking: Bool {
        switch self {
        case .excellent, .good, .fair:
            return true
        case .poor, .veryPoor:
            return false
        }
    }
    
    /// 警告を表示すべきかどうか
    public var shouldShowWarning: Bool {
        switch self {
        case .excellent, .good, .fair:
            return false
        case .poor, .veryPoor:
            return true
        }
    }
    
    /// UI表示用の色
    public var displayColor: String {
        switch self {
        case .excellent:
            return "green"
        case .good:
            return "blue"
        case .fair:
            return "yellow"
        case .poor:
            return "orange"
        case .veryPoor:
            return "red"
        }
    }
    
    /// ユーザー向けメッセージ
    public var userMessage: String {
        switch self {
        case .excellent, .good:
            return ""
        case .fair:
            return "照明が少し暗いですが、手の認識は可能です"
        case .poor:
            return "照明が暗いため、手の認識精度が低下する可能性があります。より明るい場所での使用をお勧めします。"
        case .veryPoor:
            return "照明がとても暗いため、手の認識が困難です。明るい場所に移動してください。"
        }
    }
}

/// カメラの露出情報を管理する構造体
public struct ExposureInfo: Equatable {
    /// ISO感度
    public let iso: Float
    
    /// 露出時間（秒）
    public let exposureDuration: Double
    
    /// 露出バイアス
    public let exposureBias: Float
    
    /// 照明環境の評価
    public let lightingCondition: LightingCondition
    
    public init(iso: Float, exposureDuration: Double, exposureBias: Float) {
        self.iso = iso
        self.exposureDuration = exposureDuration
        self.exposureBias = exposureBias
        self.lightingCondition = Self.evaluateLightingCondition(iso: iso, exposureDuration: exposureDuration)
    }
    
    /// ISO感度と露出時間から照明環境を評価
    private static func evaluateLightingCondition(iso: Float, exposureDuration: Double) -> LightingCondition {
        // ISO感度ベースの評価
        let isoScore: Int
        switch iso {
        case ..<100:
            isoScore = 4 // excellent
        case ..<400:
            isoScore = 3 // good
        case ..<800:
            isoScore = 2 // fair
        case ..<1600:
            isoScore = 1 // poor
        default:
            isoScore = 0 // veryPoor
        }
        
        // 露出時間ベースの評価
        let exposureScore: Int
        switch exposureDuration {
        case ..<(1.0/60.0):
            exposureScore = 4 // excellent
        case ..<(1.0/30.0):
            exposureScore = 3 // good
        case ..<(1.0/15.0):
            exposureScore = 2 // fair
        case ..<(1.0/8.0):
            exposureScore = 1 // poor
        default:
            exposureScore = 0 // veryPoor
        }
        
        // 総合評価（より厳しい方を採用）
        let finalScore = min(isoScore, exposureScore)
        
        switch finalScore {
        case 4:
            return .excellent
        case 3:
            return .good
        case 2:
            return .fair
        case 1:
            return .poor
        default:
            return .veryPoor
        }
    }
}