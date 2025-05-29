# タスク名: カメラ映像統合 - 背景処理とRealityKit連携

## 概要
カメラ映像を背景として表示し、グレースケール＋ブラー処理を適用する。RealityKitの3Dモデルと自然に統合し、アーティスト向けの参考資料として最適な表示を実現する。

## 背景・目的
- 手の3Dモデルを際立たせるための背景処理
- カメラ映像とRealityKitの自然な統合
- アーティストが集中できる視覚的環境の構築

## 優先度
**Medium** - UX向上のために重要だが、3Dモデル表示後でも可

## 前提条件
- #005-02（3Dモデル表示実装）が完了していること

## To-Be（完了条件）
- [ ] カメラ映像のリアルタイムフィルター処理
- [ ] グレースケール変換の実装
- [ ] ガウシアンブラーの適用（調整可能な強度）
- [ ] RealityViewの背景としてカメラ映像を設定
- [ ] フィルター処理のパフォーマンス最適化
- [ ] メモリ効率的な実装（CVPixelBuffer再利用）
- [ ] フィルター強度の設定UI（後続タスクへの準備）
- [ ] 統合テストの作成
- [ ] テストが全て通る

## 実装方針
1. **フィルター処理パイプライン**
   ```swift
   class VideoFilterProcessor {
       func process(_ pixelBuffer: CVPixelBuffer) -> CVPixelBuffer {
           // 1. グレースケール変換
           // 2. ガウシアンブラー適用
           // 3. 結果を返す
       }
   }
   ```

2. **Core Imageフィルター使用**
   - CIColorControls（彩度を0に）
   - CIGaussianBlur（radius調整可能）
   - Metal Performance Shadersで高速化

3. **RealityKitとの統合**
   - ARViewのcameraMode設定
   - カスタム背景レンダリング

## 関連情報
- 親タスク: #005（簡易3Dモデルの表示）
- 前提タスク: #005-02（3Dモデル表示実装）
- Core Imageプログラミングガイド

## 作業ログ
### YYYY-MM-DD HH:MM
- 作業内容の記録