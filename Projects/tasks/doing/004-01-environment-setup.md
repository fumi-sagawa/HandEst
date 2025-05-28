# タスク名: フェーズ1 - 環境セットアップと基盤実装

## 概要
MediaPipe統合の第1段階として、SwiftTasksVisionを使用した環境セットアップとMediaPipe基盤の実装を行う。

## 背景・目的
- SPM環境を維持したMediaPipe統合の実現
- SwiftTasksVisionの動作検証
- 後続フェーズの基盤構築

## 優先度
**High** - 全体の実装基盤となる重要フェーズ

## 前提条件
- プロジェクトがSPMベースで構成されていること
- iOS 17+ 対象であること

## To-Be（完了条件）
- [ ] SwiftTasksVisionのSPM依存関係追加
- [ ] MediaPipeTasksVisionのimport確認
- [ ] 基本的な初期化処理の実装
- [ ] プロジェクトビルド確認
- [ ] バイナリサイズへの影響測定
- [ ] 基本的な動作テスト作成
- [ ] エラーハンドリングの基礎実装
- [ ] 全テスト通過確認

## 実装方針
1. **SwiftTasksVision依存関係追加**
   - Package.swiftにSwiftTasksVision追加
   - URL: https://github.com/paescebu/SwiftTasksVision
   - バージョン制約の設定

2. **基本セットアップ**
   - MediaPipeTasksVisionのimport
   - 初期化コードの実装
   - エラーハンドリングの基礎

3. **動作確認**
   - ビルド成功の確認
   - 基本的なテストケース作成
   - バイナリサイズの測定

## 成功判定基準
- プロジェクトが正常にビルドされる
- MediaPipeTasksVisionが正常にimportされる
- 基本的な初期化処理が動作する
- テストが全て通る

## 想定期間
1日

## 関連情報
- 参考: SwiftTasksVision GitHub リポジトリ
- メインチケット: 004-mediapipe-integration.md

## 作業ログ
### 2025-05-28 17:30
- XcodeGenを使用してXcodeでのビルド環境を確認
- 初回ビルドは成功（MediaPipeをコメントアウトした状態）
- SwiftTasksVisionパッケージの統合を試みた

#### 発生した問題
1. **SwiftTasksVisionの`unsafeFlags`エラー**
   - エラー: `The package product 'SwiftTasksVision' cannot be used as a dependency of this target because it uses unsafe build flags`
   - 原因: SwiftTasksVisionのPackage.swiftで`linkerSettings: [.unsafeFlags(["-ObjC"])]`を使用している
   - Swift Package Managerはセキュリティ上の理由から、`unsafeFlags`を使用するパッケージを依存関係として許可しない

#### 調査した解決方法
1. **XcodeプロジェクトでOTHER_LDFLAGSを設定**
   - project.ymlに`OTHER_LDFLAGS: "-ObjC"`を追加
   - 結果: SPMの制限により効果なし

2. **追加のビルド設定**
   - `ALLOW_TARGET_PLATFORM_SPECIALIZATION: YES`
   - `CLANG_ALLOW_NON_MODULAR_INCLUDES_IN_FRAMEWORK_MODULES: YES`
   - 結果: SPMの制限により効果なし

#### 今後の方針
1. **ローカルパッケージとして統合**
   - SwiftTasksVisionをローカルにクローン
   - Package.swiftを編集して`unsafeFlags`を削除
   - ローカルパスで依存関係を追加

2. **フォークして修正**
   - SwiftTasksVisionをフォーク
   - `unsafeFlags`を使わない実装に変更
   - 修正版を使用

3. **代替手段の検討**
   - MediaPipe公式のiOS SDKを直接使用
   - XCFrameworkでの統合
   - 手動でのフレームワーク組み込み

4. **暫定対応**
   - 現時点ではMediaPipeClientをモックアップとして実装
   - 基本的なアーキテクチャは動作確認済み

#### 次回の作業予定
- 上記方針のいずれかを選択して実装
- MediaPipeの統合方法について最終決定
- 統合後の動作確認とテスト実装

### 2025-05-28 18:00
- SwiftTasksVisionをローカルパッケージとして統合することに決定
- LocalPackagesディレクトリを作成し、SwiftTasksVisionをクローン
- Package.swiftからunsafeFlagsを削除して、SPMの制限を回避
- project.ymlを更新して、ローカルパッケージを参照するように変更
- SwiftLintの設定を更新して、LocalPackagesフォルダを除外
- MediaPipeClient.swiftでMediaPipeTasksVisionのimportを確認

#### 成果
- ✅ SwiftTasksVisionのローカル統合完了
- ✅ MediaPipeTasksVisionモジュールのimport成功
- ✅ プロジェクトのビルド成功
- ✅ 全テストの通過確認
- ✅ HandLandmarkerOptionsクラスへのアクセス確認

#### 技術的決定事項
- SwiftTasksVisionをローカルパッケージとして管理
- `-ObjC`フラグはproject.ymlで設定済み
- LocalPackagesフォルダはSwiftLintから除外

#### 次のステップ
- MediaPipeのHandLandmarkerの実装を進める
- モデルファイルの配置と読み込み処理の実装