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
- [x] RenderingFeatureの基本構造実装（State/Action/Reducer）
- [x] RenderingViewの基本実装（RealityView使用）
- [x] RealityKitシーンの初期化処理
- [x] MediaPipe座標系（0-1正規化）からRealityKit座標系への変換実装
- [x] HandModelProviderプロトコルの定義
- [x] DependencyとしてのRenderingClientの基本実装
- [x] 基本的なライティング設定
- [x] RenderingFeatureの単体テスト（基本動作）
- [x] テストが全て通る

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
### 2025-05-29 12:30
- タスク開始、ブランチ作成: feature/005-01-realitykit-setup
- タスクファイルをdoingフォルダに移動

### 2025-05-29 13:00
- ModelType enumを作成（simple/mesh/realisticの3種類）
- HandModelProviderプロトコルを定義
- SimpleHandModelProviderを実装（球体と円柱のモデル）

### 2025-05-29 13:30
- RenderingClientをDependencyとして実装
- CoordinateConverterを作成（MediaPipe→RealityKit座標変換）
- RenderingFeatureを更新（新しいState/Action追加）

### 2025-05-29 14:00
- RenderingViewを実装（UIViewRepresentableでARViewを使用）
- Coordinatorパターンでシーン管理を実装
- ライティング設定を追加（ポイントライトと環境光）

### 2025-05-29 14:30
- RenderingFeatureTestsを更新（新しいアクションのテスト追加）
- 既存のRenderingErrorをAppError.swiftに統合
- ビルドエラーを修正（public修飾子の削除等）

### 2025-05-29 15:00
- 全てのテストが通ることを確認
- SwiftLintエラーが0件であることを確認
- タスク完了