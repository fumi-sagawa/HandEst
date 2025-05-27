# HandEst - リアルタイム3D手モデル参照アプリ

HandEstは、アーティストのための手の参考資料を提供するiOSアプリケーションです。カメラで手をトラッキングし、リアルタイムで3Dモデルとして表示します。

## 🎯 主な機能

- リアルタイム手トラッキング（MediaPipe使用）
- 3Dモデル表示（RealityKit使用）
- 焦点距離シミュレーション（魚眼、24mm、50mm、85mm、平行投影）
- ポーズロック機能
- 写真・動画撮影機能

## 🛠 技術スタック

- **SwiftUI** - UIフレームワーク
- **The Composable Architecture (TCA)** - 状態管理
- **RealityKit** - 3Dレンダリング
- **MediaPipe** - 手のトラッキング
- **AVFoundation** - カメラ制御

## 📋 必要な環境

- macOS 13.0以上
- Xcode 16.2以上
- iOS 17.0以上（デプロイメントターゲット）
- [Homebrew](https://brew.sh/ja/)（ツールのインストール用）

## 🚀 セットアップ

### 1. リポジトリのクローン

```bash
git clone https://github.com/yourusername/HandEst.git
cd HandEst
```

### 2. 必要なツールのインストール

```bash
# xcodegenのインストール（プロジェクトファイル生成用）
brew install xcodegen

# SwiftLintのインストール（コード品質チェック用）
brew install swiftlint
```

### 3. プロジェクトファイルの生成

```bash
# xcodegenでプロジェクトファイルを生成
./Scripts/regenerate-project.sh
```

### 4. Xcodeでプロジェクトを開く

```bash
open HandEst.xcodeproj
```

初回起動時は、TCAのマクロ使用許可ダイアログが表示されます。
「Trust & Enable All」をクリックしてください。

### 5. Git Hooksの設定（オプション）

コミット前に自動でテストを実行したい場合：

```bash
# Git hooksをインストール
./Scripts/install-hooks.sh
```

これにより、`git commit`時に自動的に以下が実行されます：
- 全テストの実行
- ビルドの確認

**注意**: SwiftLintはビルド時に自動実行されるため、pre-commitでは実行されません。

## 💻 開発フロー

### VSCodeでの開発（推奨）

1. **新しいファイルを作成した場合**
   ```bash
   # プロジェクトファイルを再生成
   ./Scripts/regenerate-project.sh
   ```

2. **ビルド**
   ```bash
   xcodebuild -scheme HandEst -destination 'platform=iOS Simulator,name=iPhone 16 Pro' build
   ```

3. **テスト実行**
   ```bash
   xcodebuild -scheme HandEst test
   ```

4. **シミュレータで実行**
   ```bash
   xcodebuild -scheme HandEst -destination 'platform=iOS Simulator,name=iPhone 16 Pro' build
   open -a Simulator
   ```

### Xcodeでの開発

通常通りXcodeでプロジェクトを開いて開発できます。
ただし、ファイル構造を変更した場合は、`project.yml`も更新する必要があります。

## 📁 プロジェクト構造

```
HandEst/
├── App/                    # アプリケーションエントリーポイント
│   ├── HandEstApp.swift
│   └── AppFeature.swift
├── Features/               # 機能モジュール（TCA）
│   ├── Camera/            # カメラ機能
│   ├── HandTracking/      # 手トラッキング
│   ├── Rendering/         # 3Dレンダリング
│   └── Settings/          # 設定画面
├── Models/                 # 共有データモデル
├── Shared/                 # 共有コンポーネント
├── Resources/              # アセット、ローカライゼーション
└── Projects/               # プロジェクトドキュメント
    ├── 要件定義.md
    ├── 機能要件仕様書.md
    └── tasks/              # タスク管理
```

## 🔧 設定ファイル

- `project.yml` - xcodegenの設定ファイル（プロジェクト構造を定義）
- `.swiftlint.yml` - SwiftLintの設定ファイル
- `CLAUDE.md` - 開発ガイドライン（日本語）

## 🧪 テスト

```bash
# 単体テストの実行
xcodebuild -scheme HandEst test

# SwiftLintでコード品質チェック
swiftlint
```

## 🚨 トラブルシューティング

### xcodegenでプロジェクトファイルが生成されない

```bash
# xcodegenのバージョン確認
xcodegen --version

# 最新版にアップデート
brew upgrade xcodegen
```

### ビルドエラー：No such module 'ComposableArchitecture'

Xcodeでプロジェクトを開き、Package Dependenciesが解決されるまで待ってください。

### シミュレータが見つからない

```bash
# 利用可能なシミュレータを確認
xcrun simctl list devices
```

## 📝 コントリビューション

1. Featureブランチを作成
2. 変更をコミット（Git Hookによりテストが自動実行されます）
3. プルリクエストを作成

詳細な開発ガイドラインは[CLAUDE.md](./CLAUDE.md)を参照してください。

## 📄 ライセンス

[ライセンスを記載]