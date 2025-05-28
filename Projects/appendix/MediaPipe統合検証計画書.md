# MediaPipe統合検証計画書

## 1. 概要

本文書は、HandEstプロジェクトにおけるMediaPipe Handsライブラリの統合に関する技術検証計画を定義します。段階的なアプローチにより、技術的リスクを最小化しながら確実な統合を目指します。

## 2. 検証目標

### 2.1 主要目標
- MediaPipe HandsのiOS統合の実現可能性確認
- リアルタイム処理（30fps）の達成可能性検証
- バイナリサイズとパフォーマンスの影響評価
- 安定性と精度の確認

### 2.2 成功基準
- [ ] MediaPipe Handsライブラリの正常な統合
- [ ] 21個の関節点データのリアルタイム取得
- [ ] 30fps以上でのフレーム処理
- [ ] アプリサイズ200MB以下の維持
- [ ] 15分使用でバッテリー消費15%以下

## 3. 段階的検証アプローチ

### 3.1 Phase 1: 基本統合検証（POC）✅部分完了

#### 目的
MediaPipe Handsライブラリの基本的な統合と動作確認

#### 検証内容
1. **ライブラリ統合** ✅完了
   - ✅ SwiftTasksVision経由でMediaPipe iOS Frameworkの追加
   - ✅ LocalPackagesディレクトリでの管理構造確立
   - ⏳ バイナリサイズへの影響測定（次ステップ）
   - ✅ ビルド時間への影響確認（問題なし）

2. **基本認識テスト**
   - 単一の手の検出
   - 21個の関節点座標の取得
   - 認識精度の初期評価

#### 実装内容
```swift
// 最小限のMediaPipe統合
class HandTrackingManager {
    private var handLandmarker: HandLandmarker?
    
    func initializeMediaPipe() -> Bool {
        // MediaPipe初期化処理
    }
    
    func processFrame(_ pixelBuffer: CVPixelBuffer) -> [HandLandmark]? {
        // フレーム処理と関節点取得
    }
}
```

#### 期間・リソース
- **期間**: 3-5日
- **成果物**: 基本POCアプリ
- **評価指標**: 動作確認、基本性能測定

### 3.2 Phase 2: パフォーマンス最適化検証

#### 目的
リアルタイム処理要件の達成とパフォーマンス最適化

#### 検証内容
1. **フレームレート最適化**
   - 30fps維持の確認
   - CPU/GPU使用率の測定
   - メモリ使用量の監視

2. **認識精度向上**
   - 照明条件別の精度測定
   - 手の位置・角度による影響評価
   - 複数の手が映った場合の処理

3. **バッテリー消費測定**
   - 連続使用時のバッテリー消費率
   - 発熱状況の監視
   - サーマルスロットリング対応

#### 実装内容
```swift
class OptimizedHandTracker {
    private let processingQueue = DispatchQueue(label: "hand-tracking", qos: .userInteractive)
    
    func optimizedProcessing(_ frame: CVPixelBuffer) async -> HandTrackingResult {
        // 最適化された非同期処理
    }
    
    func startPerformanceMonitoring() {
        // CPU使用率、メモリ、バッテリーの監視
    }
}
```

#### 期間・リソース
- **期間**: 5-7日
- **成果物**: パフォーマンス測定レポート
- **評価指標**: FPS、CPU使用率、バッテリー消費率

### 3.3 Phase 3: TCA統合とエラーハンドリング

#### 目的
本格的なアプリケーションアーキテクチャとの統合

#### 検証内容
1. **TCA統合**
   - HandTrackingFeatureの実装
   - 非同期処理のEffect化
   - 状態管理の最適化

2. **エラーハンドリング**
   - MediaPipe初期化失敗の対応
   - 認識エラーの処理
   - カメラアクセス権限の管理

3. **実機テスト**
   - 各種iPhone/iPadでの動作確認
   - iOS version別の互換性確認
   - App Store準備

#### 実装内容
```swift
struct HandTrackingFeature: Reducer {
    struct State: Equatable {
        var isInitialized: Bool = false
        var landmarks: [HandLandmark] = []
        var error: HandTrackingError?
        var performanceMetrics: PerformanceMetrics?
    }
    
    enum Action: Equatable {
        case initialize
        case processFrame(CVPixelBuffer)
        case landmarksReceived([HandLandmark])
        case errorOccurred(HandTrackingError)
    }
    
    @Dependency(\.handTracker) var handTracker
    
    func reduce(into state: inout State, action: Action) -> Effect<Action> {
        switch action {
        case .initialize:
            return .run { send in
                let success = await handTracker.initialize()
                if !success {
                    await send(.errorOccurred(.initializationFailed))
                }
            }
        // その他のアクション処理
        }
    }
}
```

#### 期間・リソース
- **期間**: 7-10日
- **成果物**: 完全統合版アプリ
- **評価指標**: 安定性、ユーザビリティ、App Store準備度

## 4. 技術的検証項目

### 4.1 ライブラリ統合関連

#### バイナリサイズ検証
- **確認項目**: MediaPipe追加前後のIPAサイズ
- **目標値**: 総サイズ200MB以下
- **対策**: On-Demand Resourcesの活用検討

#### ビルド時間影響
- **確認項目**: Clean Buildにかかる時間
- **許容値**: 3分以内
- **対策**: プリコンパイル済みフレームワークの活用

### 4.2 処理性能関連

#### フレーム処理速度
```swift
// 性能測定用コード例
class PerformanceMonitor {
    func measureFrameProcessingTime() {
        let startTime = CFAbsoluteTimeGetCurrent()
        // MediaPipe処理
        let processingTime = CFAbsoluteTimeGetCurrent() - startTime
        
        // 30fps = 33.33ms/frame以下が目標
        assert(processingTime < 0.0333, "Frame processing too slow")
    }
}
```

#### メモリ使用量
- **監視項目**: ピークメモリ使用量、メモリリーク
- **目標値**: 追加メモリ使用量100MB以下
- **測定方法**: Instrumentsによる詳細分析

### 4.3 認識精度関連

#### 照明条件テスト
- **明るい環境**: 500ルクス以上
- **標準環境**: 100-500ルクス
- **暗い環境**: 50-100ルクス
- **極暗環境**: 50ルクス以下

#### 手の位置・角度テスト
- **距離**: カメラから30cm-100cm
- **角度**: 正面、斜め30度、斜め60度
- **部分遮蔽**: 指の一部が隠れる状況

## 5. 検証環境・デバイス

### 5.1 テスト対象デバイス
- **iPhone**: iPhone 12, iPhone 14, iPhone 15
- **iPad**: iPad Air (第5世代), iPad Pro (11インチ)
- **iOS Version**: iOS 16.0, iOS 17.0, iOS 18.2

### 5.2 検証ツール
- **Xcode Instruments**: パフォーマンス測定
- **System Information**: バッテリー・温度監視
- **TestFlight**: 実機テスト配布
- **Custom Metrics**: FPS、認識精度測定

## 6. リスク対応策

### 6.1 技術的リスク

#### MediaPipe統合失敗
- **リスク**: iOS向けライブラリの制限
- **対応策**: Vision Frameworkへのフォールバック
- **代替案**: ARKitのハンドトラッキング（iOS 16+）

#### パフォーマンス不足
- **リスク**: 30fps維持困難
- **対応策**: 処理解像度の動的調整
- **代替案**: フレームスキップによる負荷軽減

#### アプリサイズ超過
- **リスク**: 200MB制限超過
- **対応策**: On-Demand Resourcesの活用
- **代替案**: 軽量版ライブラリの探索

### 6.2 スケジュールリスク
- **Phase遅延**: 各Phase +2日のバッファを設定
- **完全失敗**: 代替技術への切り替え準備

## 7. 成果物・報告

### 7.1 各Phase成果物
- **Phase 1**: 基本動作確認レポート
- **Phase 2**: パフォーマンス測定結果
- **Phase 3**: 統合完了報告書

### 7.2 最終報告書項目
1. 技術検証結果サマリー
2. パフォーマンス測定データ
3. 実装上の課題と対応策
4. 本格実装への推奨事項
5. 代替技術の評価

## 8. スケジュール

| Phase | 期間 | 主要成果物 |
|-------|------|------------|
| Phase 1 | 3-5日 | 基本POC |
| Phase 2 | 5-7日 | パフォーマンス評価 |
| Phase 3 | 7-10日 | 統合完了版 |
| **総計** | **15-22日** | **検証完了** |

---

*文書作成日: 2025-05-28*
*最終更新日: 2025-05-28*