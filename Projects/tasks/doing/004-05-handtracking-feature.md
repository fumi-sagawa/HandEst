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

### 1. **アーキテクチャ設計**
   - HandTrackingFeatureは現在のBasicな実装からMediaPipeClientと統合した完全な実装に拡張
   - CameraFeatureからのビデオフレームストリームを受け取り、MediaPipeで処理
   - ポーズロック機能、左右手選択機能を含む

### 2. **State設計の詳細**
   ```swift
   @ObservableState
   struct State: Equatable {
       // トラッキング状態
       var isTracking = false
       var isPoseLocked = false
       var handedness: Handedness = .right
       
       // MediaPipe統合
       var isMediaPipeInitialized = false
       var currentResult: HandTrackingResult?
       var trackingHistory = HandTrackingHistory(maxFrames: 30)
       
       // パフォーマンス監視
       var performanceMetrics: PerformanceMetrics = PerformanceMetrics()
       
       // エラー管理
       var error: MediaPipeError?
       
       // デバッグ情報
       var isDebugMode = false
       var debugInfo: DebugInfo?
   }
   ```

### 3. **Action設計の詳細**
   ```swift
   enum Action: Equatable {
       // 基本制御
       case onAppear
       case onDisappear
       case startTracking
       case stopTracking
       case togglePoseLock
       case setHandedness(Handedness)
       
       // MediaPipe関連
       case initializeMediaPipe
       case mediaPipeInitialized(Bool)
       case processFrame(CVPixelBuffer)
       case trackingResult(HandTrackingResult)
       case trackingError(MediaPipeError)
       
       // パフォーマンス
       case updatePerformanceMetrics
       
       // デバッグ
       case toggleDebugMode
       case clearError
   }
   ```

### 4. **PerformanceMetrics構造体**
   ```swift
   struct PerformanceMetrics: Equatable {
       var currentFPS: Double = 0
       var averageFPS: Double = 0
       var processingTimeMs: Double = 0
       var frameDropRate: Double = 0
       var totalFramesProcessed: Int = 0
       var detectionRate: Double = 0
   }
   ```

### 5. **DebugInfo構造体**
   ```swift
   struct DebugInfo: Equatable {
       var detectedHandsCount: Int
       var leftHandConfidence: Float?
       var rightHandConfidence: Float?
       var primaryLandmarks: [LandmarkDebugInfo]
   }
   
   struct LandmarkDebugInfo: Equatable {
       var type: LandmarkType
       var position: CGPoint
       var confidence: Float
   }
   ```

### 6. **Reducer実装計画**
   - **初期化フロー**:
     1. onAppearでMediaPipeClientを初期化
     2. 初期化成功後、カメラフレーム受信の準備
   
   - **フレーム処理フロー**:
     1. CameraFeatureからCVPixelBufferを受信
     2. MediaPipeClientでフレーム処理
     3. 結果をStateに反映
     4. デバッグ情報をログ出力
   
   - **エラーハンドリング**:
     - MediaPipeエラーをキャッチしてユーザーに表示
     - 自動リトライ機能

### 7. **CameraFeatureとの統合**
   - AppFeatureレベルでCameraFeatureとHandTrackingFeatureを連携
   - CameraManagerのstartVideoDataOutputを使用してフレームを取得
   - フレームをHandTrackingFeatureに送信

### 8. **デバッグログ出力の詳細実装**
   ```swift
   private func logTrackingResult(_ result: HandTrackingResult) {
       let logger = AppLogger.shared
       
       // 基本情報
       logger.info("検出された手の数: \(result.detectedHandsCount)", category: .handTracking)
       logger.info("FPS: \(String(format: "%.1f", result.estimatedFPS))", category: .handTracking)
       logger.info("処理時間: \(String(format: "%.1f", result.processingTimeMs))ms", category: .handTracking)
       
       // 各手の詳細情報
       if let leftHand = result.leftHandPose {
           let confidence = result.handednessData.hands.first(where: { $0.handType == .left })?.confidence ?? 0
           logger.info("左手 - 信頼度: \(String(format: "%.2f", confidence))", category: .handTracking)
           logPrimaryLandmarks(leftHand, handType: "左手")
       }
       
       if let rightHand = result.rightHandPose {
           let confidence = result.handednessData.hands.first(where: { $0.handType == .right })?.confidence ?? 0
           logger.info("右手 - 信頼度: \(String(format: "%.2f", confidence))", category: .handTracking)
           logPrimaryLandmarks(rightHand, handType: "右手")
       }
   }
   
   private func logPrimaryLandmarks(_ pose: HandPose, handType: String) {
       let logger = AppLogger.shared
       
       // 主要ランドマークのみログ出力
       let primaryLandmarks: [LandmarkType] = [.wrist, .thumbTip, .indexFingerTip, .middleFingerTip]
       
       for landmarkType in primaryLandmarks {
           if let landmark = pose.landmark(for: landmarkType) {
               logger.debug(
                   "\(handType) - \(landmarkType): (\(String(format: "%.3f", landmark.x)), \(String(format: "%.3f", landmark.y)), \(String(format: "%.3f", landmark.z)))",
                   category: .handTracking
               )
           }
       }
   }
   ```

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

## 実装手順

### フェーズ1: 基本構造の拡張 ✅
1. [x] PerformanceMetrics構造体の実装
2. [x] DebugInfo構造体の実装
3. [x] HandTrackingFeature.Stateの拡張
4. [x] HandTrackingFeature.Actionの拡張
5. [x] 基本的なReducerロジックの実装

### フェーズ2: MediaPipe統合 ✅
1. [x] MediaPipeClient初期化ロジック
2. [x] フレーム処理パイプライン実装
3. [x] 結果の状態反映
4. [x] エラーハンドリング実装

### フェーズ3: CameraFeature連携 ✅
1. [x] AppFeatureでの連携実装
2. [x] フレームストリーミングのセットアップ
3. [x] ライフサイクル管理（開始/停止）

### フェーズ4: デバッグ・監視機能 ✅
1. [x] デバッグログ出力の実装
2. [x] パフォーマンスメトリクス計算
3. [x] デバッグモードUI（オプション）

### フェーズ5: テスト実装
1. [ ] Reducer単体テスト
2. [ ] MediaPipe統合テスト
3. [ ] パフォーマンステスト
4. [ ] エラーケーステスト

## 技術的考慮事項

### 1. **パフォーマンス最適化**
- フレームドロップの適切な処理
- 30FPSターゲットでの安定動作
- メモリ効率的なフレーム履歴管理

### 2. **並行処理**
- MediaPipeClientはactorベース
- TCA Effectでの非同期処理管理
- メインスレッドブロッキングの回避

### 3. **エラー回復**
- MediaPipe初期化失敗時の再試行
- カメラ切断時の適切な処理
- ユーザーへの明確なフィードバック

## テスト戦略

### 1. **既存テストの拡張**
- 現在の5つの基本テストを維持
- 新しいAction/Stateに対応するテストを追加

### 2. **MediaPipe統合テスト**
```swift
// MediaPipe初期化テスト
func testMediaPipeInitialization() async {
    // 初期化成功・失敗のシナリオ
}

// フレーム処理テスト  
func testFrameProcessing() async {
    // モックフレームでの処理テスト
}

// エラーハンドリングテスト
func testMediaPipeErrorHandling() async {
    // 各種エラーケースのテスト
}
```

### 3. **パフォーマンステスト**
```swift
// FPS計算テスト
func testPerformanceMetricsCalculation() async {
    // メトリクス計算の正確性確認
}

// 履歴管理テスト
func testTrackingHistoryManagement() async {
    // 履歴の追加・削除・統計計算
}
```

### 4. **統合テスト**
- CameraFeatureとの連携テスト
- ライフサイクル管理テスト
- デバッグモードのテスト

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

### 2025-05-29 00:00 
- **チケット詳細化**: これまでの実装を踏まえて実装計画を詳細化
- **調査内容**:
  - 完了したサブタスク（004-01〜004-04）の確認
  - MediaPipeClientの実装状況確認（TCA Dependency対応済み）
  - CameraManagerのビデオデータ出力機能確認
  - 既存のHandTrackingFeature基本実装の確認
- **実装計画**:
  - State/Actionの詳細設計
  - パフォーマンスメトリクス・デバッグ情報の構造体設計
  - CameraFeatureとの連携方法の明確化
  - デバッグログ出力の詳細実装計画
- **次のステップ**:
  - フェーズ1から順次実装開始

### 2025-05-29 00:20
- **Phase 1完了**: 基本構造の拡張を実装
  - PerformanceMetrics/DebugInfo/Handedness構造体を作成
  - HandTrackingFeatureのState/Actionを拡張
  - MediaPipeClient依存関係を統合したReducerを実装
  - 全108テストが成功
- **Phase 2完了**: MediaPipe統合を実装
  - MediaPipeClient初期化ロジック（onAppear/onDisappear）
  - フレーム処理パイプライン（processFrameアクション）
  - 結果の状態反映（trackingResult/updatePerformanceMetrics）
  - エラーハンドリング（trackingError/clearError）
  - MediaPipe統合テストを9個追加（全117テスト成功）
- **次のステップ**:
  - Phase 3: CameraFeature連携の実装

### 2025-05-29 01:30
- **Phase 3完了**: CameraFeature連携を実装
  - CameraFeatureにビデオデータ出力機能を追加
    - startVideoDataOutput/stopVideoDataOutputアクション
    - frameReceivedアクションでフレームを受信
  - AppFeatureでの連携実装
    - カメラ開始時にHandTrackingが初期化済みなら自動で連携開始
    - MediaPipe初期化時にカメラがアクティブなら自動で連携開始
    - フレームデータをCameraからHandTrackingへ転送
    - カメラ停止時にビデオ出力とトラッキングも停止
  - エラーハンドリング連携
    - CameraError.videoDataOutputFailedを追加
    - HandTrackingエラーをAppレベルで表示
  - テストを11個追加（全128テスト成功）
- **実装の詳細**:
  - CameraManagerのstartVideoDataOutput/stopVideoDataOutput機能を活用
  - TCAのEffect管理でフレーム処理を非同期実行
  - ライフサイクル管理を適切に実装（開始/停止の連携）
- **次のステップ**:
  - Phase 4: デバッグ・監視機能の実装

### 2025-05-29 02:00
- **Phase 4開始**: デバッグ・監視機能を実装
  - デバッグログ出力機能
    - logTrackingResultメソッドで手の検出情報をログ出力
    - logPrimaryLandmarksメソッドで主要ランドマーク座標をログ出力
    - logPerformanceMetricsメソッドでパフォーマンス情報をログ出力
  - パフォーマンスメトリクス計算の改善
    - フレームドロップ率の計算を追加（30FPS基準）
    - updatePerformanceMetricsアクションでメトリクスを更新
  - デバッグモードUI（HandTrackingView）を実装
    - デバッグモードトグル機能
    - パフォーマンス情報の表示（FPS、処理時間、検出率など）
    - 手の検出情報の表示（検出数、信頼度）
    - エラー情報の表示
  - 全128テストが成功
- **実装の詳細**:
  - デバッグ情報はisDebugModeがtrueの時のみログ出力・表示
  - パフォーマンス監視で30FPSを目標として設定
  - HandTrackingViewでリアルタイムデバッグ情報を視覚的に表示
- **次のステップ**:
  - Phase 5: テスト実装

### 2025-05-29 09:00
- **Phase 4追加実装**: MediaPipe初期化とフレーム処理の問題を解決
  - **問題1**: MediaPipe初期化エラー「The vision task is in live stream mode. An object must be set as the delegate」
    - 原因: runningModeが`.liveStream`でデリゲート設定が必要だった
    - 解決: runningModeを`.video`に変更してシンプルな同期処理に変更
  - **問題2**: ビデオフレームが受信されない
    - 原因: CameraManagerのframeDelegateがweak参照で早期解放されていた
    - 解決: weak修飾子を削除して参照を保持
  - **問題3**: TCAの「action sent from completed effect」警告
    - 原因: 長時間実行Effectの管理が不適切
    - 解決: AsyncStreamとcancellable IDを使用した適切なEffect管理を実装
  - **問題4**: pre-commit hookのタイムアウト
    - 原因: テスト実行に2分以上かかりタイムアウト
    - 解決: XcodeGenでプロジェクト再生成、pre-commit hookのテスト出力を簡潔化
- **追加機能実装**:
  - 21個全ての手のランドマークをログ出力する`logAllLandmarks`メソッドを実装
  - デバッグモードON時に10フレームごとに詳細ログを出力
  - 部位別（手首、親指、各指）に整理してランドマーク座標を表示
- **動作確認結果**:
  - MediaPipe初期化: ✅ 成功
  - 手の検出: ✅ 正常動作（47.6 FPS、検出率100%）
  - 21ランドマークログ: ✅ 正常出力
  - 全テスト: ✅ 128個全て成功
- **Phase 4完了**: 全ての要件を満たして実装完了