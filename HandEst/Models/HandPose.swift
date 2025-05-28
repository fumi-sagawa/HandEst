import Foundation

/// 手の姿勢を表すデータモデル（21個の関節点を含む）
public struct HandPose: Equatable, Codable {
    /// 21個の関節点データ
    public let landmarks: [HandLandmark]
    
    /// 手の姿勢の信頼度スコア（全ランドマークの平均）
    public let overallConfidence: Float
    
    /// タイムスタンプ
    public let timestamp: Date
    
    public init(landmarks: [HandLandmark], timestamp: Date = Date()) {
        guard landmarks.count == 21 else {
            fatalError("HandPose must have exactly 21 landmarks, but got \(landmarks.count)")
        }
        self.landmarks = landmarks
        self.overallConfidence = landmarks.map { $0.confidence }.reduce(0, +) / Float(landmarks.count)
        self.timestamp = timestamp
    }
    
    /// インデックスからランドマークを取得
    public subscript(index: Int) -> HandLandmark {
        return landmarks[index]
    }
    
    /// ランドマークタイプからランドマークを取得
    public subscript(type: LandmarkType) -> HandLandmark {
        return landmarks[type.rawValue]
    }
    
    /// 特定の指の全ランドマークを取得
    public func landmarks(for finger: Finger) -> [HandLandmark] {
        return landmarks.filter { $0.type.finger == finger }
    }
    
    /// 手首からの相対座標に変換
    public func toWristRelativeCoordinates() -> [HandLandmark] {
        let wrist = self[.wrist]
        return landmarks.map { landmark in
            HandLandmark(
                x: landmark.x - wrist.x,
                y: landmark.y - wrist.y,
                z: landmark.z - wrist.z,
                confidence: landmark.confidence,
                type: landmark.type
            )
        }
    }
    
    /// 手のバウンディングボックスを計算
    public func boundingBox() -> (min: (x: Float, y: Float), max: (x: Float, y: Float)) {
        let xValues = landmarks.map { $0.x }
        let yValues = landmarks.map { $0.y }
        
        return (
            min: (x: xValues.min() ?? 0, y: yValues.min() ?? 0),
            max: (x: xValues.max() ?? 1, y: yValues.max() ?? 1)
        )
    }
    
    /// 手の中心座標を計算
    public func center() -> (x: Float, y: Float, z: Float) {
        let xSum = landmarks.map { $0.x }.reduce(0, +)
        let ySum = landmarks.map { $0.y }.reduce(0, +)
        let zSum = landmarks.map { $0.z }.reduce(0, +)
        let count = Float(landmarks.count)
        
        return (
            x: xSum / count,
            y: ySum / count,
            z: zSum / count
        )
    }
    
    /// 指の開閉状態を推定
    public func fingerStates() -> [Finger: FingerState] {
        var states: [Finger: FingerState] = [:]
        
        for finger in Finger.allCases {
            let fingerLandmarks = landmarks(for: finger)
            guard fingerLandmarks.count == 4 else { continue }
            
            // 指先と付け根の距離で開閉を判定
            let tip = fingerLandmarks[3]
            let base = fingerLandmarks[0]
            let distance = sqrt(
                pow(tip.x - base.x, 2) +
                pow(tip.y - base.y, 2) +
                pow(tip.z - base.z, 2)
            )
            
            // 閾値は調整が必要
            states[finger] = distance > 0.15 ? .open : .closed
        }
        
        return states
    }
}

/// 指の開閉状態
public enum FingerState: String, Codable {
    case open = "開"
    case closed = "閉"
    case unknown = "不明"
}

/// HandPoseの配列に対する拡張
extension Array where Element == HandPose {
    /// 複数フレームの平均姿勢を計算（スムージング用）
    public func averagePose() -> HandPose? {
        guard !isEmpty else { return nil }
        
        var averagedLandmarks: [HandLandmark] = []
        
        for i in 0..<21 {
            let xSum = self.map { $0.landmarks[i].x }.reduce(0, +)
            let ySum = self.map { $0.landmarks[i].y }.reduce(0, +)
            let zSum = self.map { $0.landmarks[i].z }.reduce(0, +)
            let confidenceSum = self.map { $0.landmarks[i].confidence }.reduce(0, +)
            let count = Float(self.count)
            
            let averagedLandmark = HandLandmark(
                x: xSum / count,
                y: ySum / count,
                z: zSum / count,
                confidence: confidenceSum / count,
                type: LandmarkType(rawValue: i)!
            )
            averagedLandmarks.append(averagedLandmark)
        }
        
        return HandPose(landmarks: averagedLandmarks)
    }
}