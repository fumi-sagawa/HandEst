import Foundation
import simd

/// MediaPipe座標系とRealityKit座標系の変換を行うユーティリティ
struct CoordinateConverter {
    /// 手のモデルの基準サイズ（メートル）
    /// 一般的な成人の手のひらの幅は約8-10cm
    private static let handBaseSize: Float = 0.09 // 9cm
    
    /// 画面のアスペクト比
    private let aspectRatio: Float
    
    /// 手の表示スケール
    private let displayScale: Float
    
    init(aspectRatio: Float = 16.0/9.0, displayScale: Float = 1.0) {
        self.aspectRatio = aspectRatio
        self.displayScale = displayScale
    }
    
    /// MediaPipe座標系からRealityKit座標系への変換
    /// - Parameter landmark: MediaPipeのランドマーク（正規化座標）
    /// - Returns: RealityKitの3D座標（メートル単位）
    func convertToRealityKit(_ landmark: HandLandmark) -> SIMD3<Float> {
        // MediaPipe座標系:
        // - x: 0.0（左）〜 1.0（右）
        // - y: 0.0（上）〜 1.0（下）
        // - z: カメラからの相対的な深度（負の値がカメラに近い）
        
        // RealityKit座標系:
        // - x: 右が正
        // - y: 上が正
        // - z: カメラに向かって正
        
        // 中心を原点にして、-0.5〜0.5の範囲に正規化
        let normalizedX = landmark.x - 0.5
        let normalizedY = landmark.y - 0.5
        
        // アスペクト比を考慮した座標変換
        let x = normalizedX * Self.handBaseSize * displayScale * aspectRatio
        let y = -normalizedY * Self.handBaseSize * displayScale // Y軸反転
        let z = landmark.z * Self.handBaseSize * 0.5 * displayScale // 深度のスケーリング
        
        return SIMD3<Float>(x, y, z)
    }
    
    /// ランドマークの配列を一括変換
    /// - Parameter landmarks: MediaPipeのランドマーク配列
    /// - Returns: RealityKitの3D座標配列
    func convertToRealityKit(_ landmarks: [HandLandmark]) -> [SIMD3<Float>] {
        return landmarks.map { convertToRealityKit($0) }
    }
    
    /// 手の重心を計算
    /// - Parameter landmarks: 手のランドマーク配列（21個）
    /// - Returns: 重心の3D座標
    static func calculateCentroid(_ landmarks: [HandLandmark]) -> SIMD3<Float> {
        guard landmarks.count == 21 else {
            return SIMD3<Float>(0, 0, 0)
        }
        
        let sum = landmarks.reduce(SIMD3<Float>(0, 0, 0)) { result, landmark in
            let converter = CoordinateConverter()
            let position = converter.convertToRealityKit(landmark)
            return result + position
        }
        
        return sum / Float(landmarks.count)
    }
    
    /// 手のひらの中心を計算（手首と中指の付け根の中点）
    /// - Parameter landmarks: 手のランドマーク配列
    /// - Returns: 手のひら中心の3D座標
    static func calculatePalmCenter(_ landmarks: [HandLandmark]) -> SIMD3<Float>? {
        guard landmarks.count == 21 else { return nil }
        
        let converter = CoordinateConverter()
        let wrist = converter.convertToRealityKit(landmarks[0]) // 手首
        let middleMCP = converter.convertToRealityKit(landmarks[9]) // 中指MP関節
        
        return (wrist + middleMCP) / 2.0
    }
    
    /// 2つのランドマーク間の距離を計算
    /// - Parameters:
    ///   - from: 始点のランドマーク
    ///   - to: 終点のランドマーク
    /// - Returns: 距離（メートル単位）
    func distance(from: HandLandmark, to: HandLandmark) -> Float {
        let fromPos = convertToRealityKit(from)
        let toPos = convertToRealityKit(to)
        return simd_distance(fromPos, toPos)
    }
}