import Foundation
import RealityKit

/// 手の3Dモデルを生成・更新するプロバイダーのプロトコル
protocol HandModelProvider {
    /// 手の3Dモデルを生成する
    /// - Returns: 生成されたModelEntity
    func createHandModel() -> ModelEntity
    
    /// 手のモデルをランドマークデータで更新する
    /// - Parameters:
    ///   - model: 更新対象のModelEntity
    ///   - landmarks: 手の関節点データ（21個）
    func updateHandModel(_ model: ModelEntity, with landmarks: [HandLandmark])
}

/// SimpleモデルタイプのHandModelProvider実装
struct SimpleHandModelProvider: HandModelProvider {
    /// 関節球のデフォルト半径（メートル）
    private let jointRadius: Float = 0.005 // 5mm
    
    /// 骨の円柱のデフォルト半径（メートル）
    private let boneRadius: Float = 0.003 // 3mm
    
    init() {}
    
    func createHandModel() -> ModelEntity {
        let rootEntity = ModelEntity()
        rootEntity.name = "HandModel"
        
        // 21個の関節点用の球体を作成
        for i in 0..<21 {
            let jointEntity = ModelEntity(
                mesh: .generateSphere(radius: jointRadius),
                materials: [SimpleMaterial(color: .white.withAlphaComponent(0.8), isMetallic: false)]
            )
            jointEntity.name = "joint_\(i)"
            rootEntity.addChild(jointEntity)
        }
        
        // 骨を表す円柱は動的に生成・更新する
        
        return rootEntity
    }
    
    func updateHandModel(_ model: ModelEntity, with landmarks: [HandLandmark]) {
        guard landmarks.count == 21 else { return }
        
        // 各関節点の位置を更新
        for (index, landmark) in landmarks.enumerated() {
            if let jointEntity = model.children.first(where: { $0.name == "joint_\(index)" }) as? ModelEntity {
                // MediaPipe座標系からRealityKit座標系への変換
                let position = convertToRealityKitCoordinate(landmark)
                jointEntity.position = position
            }
        }
        
        // TODO: 骨（円柱）の位置と向きを更新
    }
    
    /// MediaPipe座標系からRealityKit座標系への変換
    private func convertToRealityKitCoordinate(_ landmark: HandLandmark) -> SIMD3<Float> {
        // MediaPipe: (x:0-1, y:0-1, z:深度)
        // RealityKit: メートル単位の3D座標
        
        // 仮の変換実装（後で調整が必要）
        let x = (landmark.x - 0.5) * 0.2 // 中心を0にして、約20cmの範囲にスケーリング
        let y = -(landmark.y - 0.5) * 0.2 // Y軸は反転、同様にスケーリング
        let z = landmark.z * 0.1 // Z軸は深度をメートルに変換
        
        return SIMD3<Float>(x, y, z)
    }
}