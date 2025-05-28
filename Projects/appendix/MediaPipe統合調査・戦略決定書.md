# MediaPipe統合調査・戦略決定書

## 文書概要
**作成日**: 2025年5月28日  
**目的**: HandEstアプリにおける手の21関節点トラッキング機能の実装方法を調査し、最適な統合戦略を決定する

---

## 1. 調査結果概要

### 1.1 MediaPipe公式のSPM対応状況

#### 現状
- **MediaPipe公式はSwift Package Manager（SPM）をサポートしていない**（2024-2025年現在）
- GitHub Issue #5464でSPM対応が要望されているが、実装予定は不明
- 公式文書では「MediaPipe Tasks can only be installed using CocoaPods」と明記

#### 公式統合方法
- **第一選択**: CocoaPods（公式推奨）
- **代替手段**: Bazel/Bazeliskを使用した手動フレームワーク追加

### 1.2 代替ソリューション調査

#### QuickPose iOS SDK
- **開発元**: QuickPose.ai（コミュニティベース）
- **ベース技術**: MediaPipeとBlazePoseを基盤
- **ライセンス**: Apache-2.0（商用利用可能）
- **SPM対応**: 完全サポート
- **重要な制約**: APIキー登録必須、使用制限あり

#### SwiftTasksVision
- **開発元**: paescebu（コミュニティメンテナンス）
- **ベース技術**: MediaPipeTasksVision.xcframeworkをSPMパッケージ化
- **ライセンス**: MIT License
- **SPM対応**: 完全サポート
- **利点**: APIキー不要、外部サービス依存なし

---

## 2. 技術仕様比較

### 2.1 MediaPipe Hand Landmarker機能

#### 21関節点構成
```
1. 手首（Wrist）: 1点
2. 親指（Thumb）: 4点（CMC、MCP、IP関節、先端）
3. 人差し指（Index）: 4点（MCP、PIP、DIP関節、先端）
4. 中指（Middle）: 4点（MCP、PIP、DIP関節、先端）
5. 薬指（Ring）: 4点（MCP、PIP、DIP関節、先端）
6. 小指（Pinky）: 4点（MCP、PIP、DIP関節、先端）
```

#### 技術的特徴
- **3D座標データ**: x, y, z（正規化座標 0.0-1.0）
- **信頼度スコア**: 各関節点の検出信頼度
- **左右手判別**: 信頼度閾値による判別機能
- **リアルタイム処理**: 30fps以上の安定動作

### 2.2 統合方法比較分析

| 評価項目 | SwiftTasksVision | QuickPose iOS SDK | MediaPipe + CocoaPods | 自前ビルド |
|---------|------------------|-------------------|---------------------|---------|
| **SPM対応** | ✅ 完全対応 | ✅ 完全対応 | ❌ 非対応 | ✅ 可能 |
| **外部依存** | 🟢 なし | ❌ APIキー必須 | 🟢 なし | 🟢 なし |
| **21関節点** | ✅ 完全対応 | ✅ 完全対応 | ✅ 完全対応 | ✅ 完全対応 |
| **パフォーマンス** | 📈 30fps | 🚀 120fps | 📈 30fps | 📈 30fps |
| **統合難易度** | 🟢 簡単（2-3日） | 🟢 簡単（数日） | 🟡 中程度（1-2週間） | 🔴 困難（2-3週間） |
| **プロジェクト影響** | 🟢 最小 | 🟢 最小 | 🟡 SPM→CocoaPods移行 | 🟢 最小 |
| **コスト** | 🆓 完全無料 | ⚠️ 制限あり | 🆓 完全無料 | 🆓 完全無料 |
| **メンテナンス** | 🟡 コミュニティ依存 | 🟡 企業依存 | 🟢 Google公式 | 🔴 自社管理 |
| **カスタマイズ性** | 🟡 中程度 | 🟡 SDK制約 | 🟢 完全制御 | 🟢 完全制御 |

---

## 3. 現在のプロジェクト状況

### 3.1 技術スタック
```swift
// Package.swift - 現在の依存関係
dependencies: [
    .package(url: "https://github.com/pointfreeco/swift-composable-architecture", from: "1.0.0")
]

// プラットフォーム要件
platforms: [
    .iOS(.v17),  // 全ソリューションと互換
    .macOS(.v12)
]
```

### 3.2 アーキテクチャ親和性
- **TCA（The Composable Architecture）**: 状態管理
- **SPMベース**: 依存関係管理
- **iOS 17+**: 対象プラットフォーム

---

## 4. 最終戦略決定

### 4.1 段階的アプローチ（SPM完全維持）

#### 第1段階: SwiftTasksVisionで迅速検証（2-3日）✅完了
**目的**: Hand Landmarker機能の動作確認
```
1. ✅ SwiftTasksVision依存関係追加（ローカルパッケージとして統合）
2. ✅ MediaPipeTasksVisionのimport確認
3. ⏳ 基本的なHand Landmarker実装（次ステップ）
4. ⏳ 21関節点データの取得確認（次ステップ）
5. ⏳ パフォーマンステスト（30fps目標）
6. ⏳ TCAとの基本統合
```

**統合方法の更新**:
- SPMのunsafeFlags制限を回避するため、LocalPackagesディレクトリで管理
- Package.swiftからunsafeFlagsを削除、project.ymlでOTHER_LDFLAGSを設定

**検証項目**:
- [ ] 21関節点の正確な検出
- [ ] 30fps以上の安定した処理
- [ ] 左右の手の判別（信頼度0.8以上）
- [ ] メモリ使用量が適切
- [ ] クラッシュや不安定性なし

#### 第2段階: 継続 or 移行判断

**オプションA: SwiftTasksVision継続**
- **条件**: 第1段階で全機能が正常動作
- **メリット**: SPM維持、開発効率最大化
- **対策**: 必要に応じてフォークして自社管理

**オプションB: 自前フレームワークビルド**
- **条件**: SwiftTasksVisionに制限発見
- **実装**: Bazel + 手動xcframework作成
- **期間**: 追加2-3週間

### 4.2 自前ビルドアプローチ（バックアップ戦略）

#### 必要ツール
```bash
# Bazel最新版のインストール
brew install bazelisk

# MediaPipeリポジトリクローン
git clone https://github.com/google-ai-edge/mediapipe.git
cd mediapipe
```

#### 現実的なビルド工程
```bash
# 1. iOS実機用フレームワーク
bazel build --config=ios_arm64 //mediapipe/tasks/ios:MediaPipeTasksVision

# 2. iOS シミュレータ用フレームワーク
bazel build --config=ios_x86_64 //mediapipe/tasks/ios:MediaPipeTasksVision

# 3. XCFramework手動作成（Bazel制約回避）
xcodebuild -create-xcframework \
  -framework bazel-bin/mediapipe/tasks/ios/MediaPipeTasksVision_ios_arm64.framework \
  -framework bazel-bin/mediapipe/tasks/ios/MediaPipeTasksVision_ios_x86_64.framework \
  -output MediaPipeTasksVision.xcframework
```

#### 技術的制約
1. **XCFramework直接生成不可**: Bazelは直接xcframeworkを生成できない
2. **BUILD_LIBRARY_FOR_DISTRIBUTION未対応**: Swift Module Interfaceの制限
3. **手動工程必要**: `xcodebuild -create-xcframework`での後処理が必要

---

## 5. リスク分析と軽減策

### 5.1 SwiftTasksVision採用のリスク
1. **コミュニティ依存**: paescebuによる個人メンテナンス
2. **更新頻度**: MediaPipe公式更新への追従タイミング
3. **長期サポート**: メンテナンス継続性の不確実性

### 5.2 リスク軽減策
1. **フォーク戦略**: 自社フォークによる継続保証
2. **移行可能性**: MediaPipeベースなので公式実装に移行可能
3. **段階的検証**: プロトタイプで十分検証後に本格採用
4. **バックアップ計画**: 自前ビルドによる完全制御オプション

---

## 6. 実装スケジュール

### 6.1 推奨スケジュール

| フェーズ | 期間 | 内容 | 成果物 |
|---------|------|------|-------|
| **検証段階** | 2-3日 | SwiftTasksVision動作確認 | プロトタイプ |
| **判断段階** | 1日 | 継続 or 移行判断 | 戦略決定 |
| **実装段階** | 2-3週間 | 本格実装（選択した方法） | 完成品 |

### 6.2 最大期間保証
- **最短ケース**: 3日（SwiftTasksVision成功）
- **最長ケース**: 4週間（自前ビルド移行）
- **確実性**: CocoaPods使用せずSPM完全維持

---

## 7. 結論

### 7.1 最終推奨戦略
**SwiftTasksVisionによる段階的アプローチを採用**

**推奨理由**:
1. **SPM完全維持**: プロジェクト構成を変更せず
2. **迅速検証**: 2-3日で機能確認可能
3. **確実なバックアップ**: 自前ビルドによる代替手段確保
4. **CocoaPods回避**: 時代に逆行しない技術選択

### 7.2 期待される成果
- **成功パターン**: SPM維持で高速実装完了
- **代替パターン**: 自前フレームワークで完全制御実現
- **品質保証**: 30fps、21関節点、左右判別の全要件達成

---

## 8. 参考資料

### 8.1 調査ソース
- [MediaPipe iOS Framework Guide](https://ai.google.dev/edge/mediapipe/framework/getting_started/ios)
- [GitHub Issue #5464: iOS SPM support](https://github.com/google-ai-edge/mediapipe/issues/5464)
- [SwiftTasksVision](https://github.com/paescebu/SwiftTasksVision)
- [自前ビルド参考記事](https://qiita.com/noppefoxwolf/items/99cb1da63c093f668d71)

### 8.2 技術仕様
- MediaPipe Hand Landmarks: 21関節点の標準化された座標系
- TCA Dependencies: 依存関係注入パターン
- Swift Package Manager: 依存関係管理