# VSCode・Xcode連携環境構築

## 概要
VSCodeでiOS開発を行いながら、Xcodeとの連携をスムーズにするための環境構築を実施。

## 背景・目的
- VSCodeでの開発を継続したい
- Xcodeの外で作成したファイルが認識されない問題を解決
- 最終的なリリース時にはXcodeが必要なため、連携方法を確立

## 実施内容

### 1. 現状分析
- Xcode 16.2の`PBXFileSystemSynchronizedRootGroup`機能を確認
- この機能だけでは完全な自動同期は実現されないことが判明

### 2. xcodegenの導入

#### インストール
```bash
brew install xcodegen
```

#### project.yml作成
```yaml
name: HandEst
options:
  bundleIdPrefix: com.sagawafumiya
  deploymentTarget:
    iOS: 18.2
  createIntermediateGroups: true
  groupSortPosition: top
  generateEmptyDirectories: true
  fileTypes:
    .md:
      buildPhase: resources

targets:
  HandEst:
    type: application
    platform: iOS
    sources:
      - path: HandEst
        createIntermediateGroups: true
    settings:
      base:
        PRODUCT_BUNDLE_IDENTIFIER: com.sagawafumiya.HandEst
        DEVELOPMENT_TEAM: 8BD446AR8T
        SWIFT_VERSION: 5.0
        TARGETED_DEVICE_FAMILY: "1,2"
        INFOPLIST_KEY_UIApplicationSceneManifest_Generation: YES
        INFOPLIST_KEY_UIApplicationSupportsIndirectInputEvents: YES
        INFOPLIST_KEY_UILaunchScreen_Generation: YES
        INFOPLIST_KEY_UISupportedInterfaceOrientations_iPhone: "UIInterfaceOrientationPortrait UIInterfaceOrientationLandscapeLeft UIInterfaceOrientationLandscapeRight"
        INFOPLIST_KEY_UISupportedInterfaceOrientations_iPad: "UIInterfaceOrientationPortrait UIInterfaceOrientationPortraitUpsideDown UIInterfaceOrientationLandscapeLeft UIInterfaceOrientationLandscapeRight"
    dependencies:
      - package: ComposableArchitecture
        product: ComposableArchitecture
    preBuildScripts:
      - script: |
          if which swiftlint >/dev/null; then
            swiftlint
          else
            echo "warning: SwiftLint not installed, download from https://github.com/realm/SwiftLint"
          fi
        name: SwiftLint
        inputFiles:
          - $(SRCROOT)/HandEst
        outputFiles: []
        basedOnDependencyAnalysis: false

  HandEstTests:
    type: bundle.unit-test
    platform: iOS
    sources:
      - HandEstTests
    dependencies:
      - target: HandEst
    settings:
      base:
        PRODUCT_BUNDLE_IDENTIFIER: com.sagawafumiya.HandEstTests
        DEVELOPMENT_TEAM: 8BD446AR8T

  HandEstUITests:
    type: bundle.ui-testing
    platform: iOS
    sources:
      - HandEstUITests
    dependencies:
      - target: HandEst
    settings:
      base:
        PRODUCT_BUNDLE_IDENTIFIER: com.sagawafumiya.HandEstUITests
        DEVELOPMENT_TEAM: 8BD446AR8T
        TEST_TARGET_NAME: HandEst

packages:
  ComposableArchitecture:
    url: https://github.com/pointfreeco/swift-composable-architecture
    from: 1.0.0
```

### 3. スクリプト作成

#### sync-xcode.sh（手動同期用）
```bash
#!/bin/bash

# Xcodeプロジェクトをバックグラウンドで開いて同期
echo "🔄 Xcodeプロジェクトを同期中..."

# Xcodeを開く
open -g HandEst.xcodeproj

# 少し待つ（Xcodeが起動してファイルをスキャンする時間）
sleep 3

# AppleScriptでXcodeを保存して閉じる
osascript <<EOF
tell application "Xcode"
    if (count of documents) > 0 then
        save front document
        close front document
    end if
end tell
EOF

echo "✅ 同期完了！"
```

#### regenerate-project.sh（xcodegen用）
```bash
#!/bin/bash

echo "🔄 プロジェクトファイルを再生成中..."
cd "$(dirname "$0")/.."

# xcodegenでプロジェクトファイルを生成
xcodegen generate

if [ $? -eq 0 ]; then
    echo "✅ プロジェクトファイルの生成が完了しました！"
    echo "📱 Xcodeで開く場合: open HandEst.xcodeproj"
else
    echo "❌ エラーが発生しました"
    exit 1
fi
```

## 今後のワークフロー

### 開発時
1. VSCodeで新しいファイルを作成
2. `./Scripts/regenerate-project.sh`を実行
3. `xcodebuild`でビルド・テスト

### 初回セットアップ時
1. Xcodeでプロジェクトを開く
2. ビルド実行（Cmd+B）
3. マクロ使用許可ダイアログで「Trust & Enable All」をクリック

### リリース時
1. Xcodeでプロジェクトを開く
2. Archive作成
3. App Store Connectへアップロード

## メリット
- VSCodeで作成したファイルが自動的にXcodeプロジェクトに含まれる
- project.ymlだけを管理すれば良い（.pbxprojの複雑な差分を気にしなくて良い）
- マージコンフリクトが大幅に減少
- CI/CDとの相性が良い

## 注意点
- 初回はXcodeでマクロの使用許可が必要
- 新しいSwiftパッケージ追加時もXcodeで一度開く必要がある
- TCA（The Composable Architecture）が自動的に追加されている

## 作業ログ
### 2024-12-03 21:30
- VSCodeとXcodeの連携問題について調査開始
- PBXFileSystemSynchronizedRootGroupの仕組みを確認
- xcodegenの導入を決定

### 2024-12-03 21:45
- xcodegenをインストール（2.43.0）
- project.ymlを作成
- プロジェクトファイルを再生成
- 便利スクリプトを作成
- マクロビルドエラーに遭遇（Xcodeでの許可が必要）

### 2024-12-03 21:55
- Xcodeでマクロの使用を許可（Trust & Enable All）
- Info.plistの自動生成エラーを解決
  - `GENERATE_INFOPLIST_FILE: YES`を全ターゲットに追加
  - SwiftLintの`basedOnDependencyAnalysis: true`に変更
- プロジェクトファイルを再生成

### 2024-12-03 22:00
- ビルド成功！SwiftLint警告を解決
  - SwiftLintのパス問題を修正（M1/Intel Mac両対応）
  - outputFilesを追加
  - .swiftlint.yml設定ファイルを作成
- CFBundleVersionエラーを解決
  - INFOPLIST_KEY_CFBundleVersion等を追加
  - MARKETING_VERSION/CURRENT_PROJECT_VERSIONを設定

### 2024-12-03 22:05
- SwiftLintの残り警告を解決
  - 設定ファイルの矛盾を修正（無効化ルールから不要なものを削除）
  - sorted_importsルール違反を修正
  - static_over_final_classルール違反を修正
- アプリがシミュレータで正常に起動することを確認！

### 2024-12-03 22:15
- VSCode設定の追加
  - .vscode/settings.json: Swift拡張機能用の設定
  - .vscode/tasks.json: ビルドタスクの定義
  - .vscode/extensions.json: 推奨拡張機能
  - Package.swift: SPM対応（iOS v17に修正）

### 2024-12-03 22:20
- README.mdを作成
  - セットアップ手順を明確に記載
  - 開発フローを説明
  - トラブルシューティングを追加
- .gitignoreを整備
  - Xcode関連ファイルを適切に除外
  - VSCodeやその他エディタの設定も考慮
  - プロジェクト固有の設定を追加

### 2024-12-03 22:25
- Git hooksとSwiftLintの動作確認
  - pre-commit hookが正常に動作することを確認
  - SwiftLintがproject.yml経由で実行されることを確認
  - テストとビルドが自動実行されることを確認
- SwiftLint警告の修正
  - Package.swiftのtrailing_comma警告を修正
  - 最終改行を追加
- VSCode設定の最終調整
  - sourcekit-lsp.serverPathの設定を削除（Deprecated警告の解消）
  - 拡張機能による自動検出に切り替え
- Scripts/README.mdを追加
  - 各スクリプトの説明を記載

## 最終成果
- ✅ VSCodeとXcodeの連携環境構築完了
- ✅ xcodegenによる自動ファイル認識が可能に
- ✅ SwiftLintによるコード品質管理が有効化
- ✅ TCA（The Composable Architecture）の導入完了
- ✅ シミュレータでのビルド・実行が可能に
- ✅ README.mdによるドキュメント整備
- ✅ .gitignoreによる適切なファイル管理
- ✅ Git hooksによる自動テスト実行環境
- ✅ 全ての警告・エラーを解消

## 次回の作業予定
- 実際の開発フローで動作確認
- CI/CD設定の検討
- カメラ機能の実装開始