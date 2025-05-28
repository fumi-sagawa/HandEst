# タスク名: フェーズ5 - HandTrackingFeature実装

## 概要
TCAアーキテクチャに基づくHandTrackingFeatureを実装し、MediaPipeClientとの統合を完成させる。

## 背景・目的
- TCAによる状態管理の実現
- MediaPipeClientとのクリーンな統合
- UIとビジネスロジックの分離

## 優先度
**High** - アプリケーションレイヤーの核心実装

## 前提条件
- 004-04（MediaPipeClient詳細）が完了していること
- MediaPipeClientが完全に動作していること

## To-Be（完了条件）
- [ ] HandTrackingFeature State定義
- [ ] HandTrackingFeature Action定義  
- [ ] HandTrackingFeature Reducer実装
- [ ] MediaPipeClientとの統合
- [ ] 非同期Effect管理の実装
- [ ] エラー状態の適切な管理
- [ ] ライフサイクル管理（開始/停止）
- [ ] パフォーマンス監視機能
- [ ] 認識中の数値ログ表示（デバッグ用）
  - [ ] 検出された手の数をログ出力
  - [ ] 各手の信頼度スコアをログ出力
  - [ ] FPS情報をログ出力
  - [ ] 主要ランドマーク座標をログ出力（手首、親指先端など）
- [ ] HandTrackingFeatureの単体テスト作成
- [ ] 全テスト通過確認

## 実装方針
1. **TCA State設計**
   ```swift
   struct State {
       var isTracking: Bool = false
       var currentResult: HandTrackingResult?
       var error: MediaPipeError?
       var performanceMetrics: PerformanceMetrics?
   }
   ```

2. **Action設計**
   ```swift
   enum Action {
       case startTracking
       case stopTracking
       case trackingResult(HandTrackingResult)
       case trackingError(MediaPipeError)
       case performanceUpdate(PerformanceMetrics)
   }
   ```

3. **Effect管理**
   - MediaPipeClientの非同期呼び出し
   - ストリーミングデータの処理
   - エラーハンドリング

4. **デバッグログ出力**
   - trackingResultアクションで認識情報をログ出力
   - Logger.shared.logを使用してコンソールに表示
   - 検出情報の詳細（手の数、信頼度、FPS、主要座標）を出力

## 成功判定基準
- TCAアーキテクチャに準拠している
- MediaPipeClientと正常に統合されている
- 状態管理が適切に実装されている
- 非同期処理が正しく動作する
- テストカバレッジが90%以上

## 想定期間
2-3日

## 関連情報
- TCA Reducer パターン
- TCA Effect 管理
- 前提チケット: 004-04-mediapipe-client-detailed.md

## 作業ログ
### 2025-05-28 23:30
- **問題発生**: xcodebuildでビルドエラーが発生
  - エラー: `Target 'ComposableArchitectureMacros' must be enabled before it can be used`
  - 原因: TCAが1.20.1から1.20.2に自動アップデートされ、Swift 6.0マクロサポートの変更が影響
- **調査内容**:
  - pre-commitフックは正常に設定されていたが、最近の複数コミットで同じエラーが発生
  - Package.resolvedには1.20.1が記録されていたが、実際には1.20.2がインストールされていた
- **解決方法**:
  - project.ymlでTCAを`exactVersion: 1.20.1`に固定
  - Package.swiftでも`exact: "1.20.1"`に変更
  - DerivedDataをクリーンアップして再ビルド
- **結果**:
  - xcodebuildでビルド成功
  - 全107テストが成功
  - Xcodeでのビルドも成功確認
- **今後の対策**:
  - 依存関係は`exact`バージョンで固定して予期しない自動アップデートを防止
  - pre-commitフックの実行を徹底（--no-verifyの使用を最小限に）