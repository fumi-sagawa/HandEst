import Foundation

/// 3Dモデルの表示タイプ
enum ModelType: String, CaseIterable, Equatable {
    /// 球体と円柱による簡易表現
    case simple = "簡易モデル"
    
    /// 簡易的なメッシュモデル（将来実装）
    case mesh = "メッシュモデル"
    
    /// リアルなスキンメッシュモデル（将来実装）
    case realistic = "リアルモデル"
    
    /// 日本語の説明を取得
    var description: String {
        return self.rawValue
    }
}