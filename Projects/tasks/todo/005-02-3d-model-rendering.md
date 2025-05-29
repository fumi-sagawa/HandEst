# タスク名: 3Dモデル表示実装 - 球体・円柱レンダリング

## 概要
MediaPipeで取得した手の関節点データを基に、関節を球体、骨を円柱で表現する簡易的な3Dモデルを実装する。リアルタイム更新に対応し、30fpsを維持する。

## 背景・目的
- MVP段階での3D手モデルの実現
- リアルタイム更新の性能検証
- 将来のリアルモデルへの移行準備

## 優先度
**High** - MVPの中核機能

## 前提条件
- #005-01（RealityKit基盤構築）が完了していること

## To-Be（完了条件）
- [ ] SimpleHandModelProviderの実装
- [ ] 関節点への球体配置（21個、半径5mm）
- [ ] 関節間の円柱による接続（骨構造の再現）
- [ ] 手のひら部分の簡易メッシュ表示
- [ ] シンプルなマテリアル設定（白色、少し透明度）
- [ ] エンティティプールによる効率化
- [ ] 3Dモデルの更新処理（30fps維持）
- [ ] メモリリークの防止（weak参照）
- [ ] パフォーマンステストの作成
- [ ] テストが全て通る

## 実装方針
1. **SimpleHandModelProvider実装**
   - 球体: ModelEntity.generateSphere(radius: 0.005)
   - 円柱: ModelEntity.generateCylinder(height:, radius:)
   - 手のひらメッシュ: カスタムメッシュ生成

2. **骨構造の定義**
   ```swift
   enum HandBone: CaseIterable {
       case thumb, index, middle, ring, pinky
       var connections: [(from: Int, to: Int)] { ... }
   }
   ```

3. **エンティティプール**
   - 球体21個、円柱20個を事前生成
   - 位置更新のみで再利用

## 関連情報
- 親タスク: #005（簡易3Dモデルの表示）
- 前提タスク: #005-01（RealityKit基盤構築）
- MediaPipe Hand Landmarksドキュメント

## 作業ログ
### YYYY-MM-DD HH:MM
- 作業内容の記録