# タスク名: RealityKit基盤構築 - 3D表示基礎

## 概要
RealityKitの初期セットアップと、3Dレンダリングの基盤となるRenderingFeatureの基本構造を実装する。MediaPipeの座標系からRealityKitの座標系への変換処理も含む。

## 背景・目的
- 3Dモデル表示の土台作り
- 座標系変換の基盤確立
- 後続の3Dモデル実装のための準備

## 優先度
**High** - 3D表示機能の基盤として必須

## 前提条件
- #004（MediaPipe統合）が完了していること

## To-Be（完了条件）
- [ ] RenderingFeatureの基本構造実装（State/Action/Reducer）
- [ ] RenderingViewの基本実装（RealityView使用）
- [ ] RealityKitシーンの初期化処理
- [ ] MediaPipe座標系（0-1正規化）からRealityKit座標系への変換実装
- [ ] HandModelProviderプロトコルの定義
- [ ] DependencyとしてのRenderingClientの基本実装
- [ ] 基本的なライティング設定
- [ ] RenderingFeatureの単体テスト（基本動作）
- [ ] テストが全て通る

## 実装方針
1. **RenderingFeature定義**
   ```swift
   @Reducer
   struct RenderingFeature {
       struct State: Equatable {
           var isInitialized: Bool = false
           var currentHandLandmarks: [HandLandmark]?
           var modelType: ModelType = .simple
           var error: RenderingError?
       }
   }
   ```

2. **HandModelProviderプロトコル**
   ```swift
   protocol HandModelProvider {
       func createHandModel() -> ModelEntity
       func updateHandModel(_ model: ModelEntity, with landmarks: [HandLandmark])
   }
   ```

3. **座標変換ユーティリティ**
   - MediaPipe (x:0-1, y:0-1, z:深度) → RealityKit (meters)
   - 手のサイズを適切にスケーリング

## 関連情報
- 親タスク: #005（簡易3Dモデルの表示）
- RealityKit公式ドキュメント
- SwiftUIとRealityKitの統合ガイド

## 作業ログ
### YYYY-MM-DD HH:MM
- 作業内容の記録