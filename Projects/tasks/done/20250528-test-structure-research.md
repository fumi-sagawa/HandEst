# タスク名: テスト構造の調査 - 機能と同階層配置の検討

## 概要
Webフロントエンドのように機能と同階層にテストファイルを配置する手法がSwiftプロジェクトでも適用可能かを調査し、HandEstプロジェクトでの採用可否を検討する。

## 背景・目的
- 最近のWebフロントエンドでは機能と同階層にテストファイルを配置することがメジャーになっている
- 凝集性の向上や開発効率の向上が期待できる
- SwiftプロジェクトでもPackage.swiftを使用すれば実現可能性があるため調査

## 調査結果

### Swiftでの同階層テスト配置の技術的可能性
✅ **技術的には実現可能**

実装方法：
```swift
// Package.swiftでの設定例
targets: [
    .target(
        name: "HandEst",
        exclude: ["Features/*/Tests"]  // テストフォルダを除外
    ),
    .testTarget(
        name: "CameraFeatureTests",
        path: "HandEst/Features/Camera/Tests"
    ),
    .testTarget(
        name: "HandTrackingFeatureTests", 
        path: "HandEst/Features/HandTracking/Tests"
    )
]
```

### 想定されるディレクトリ構造
```
HandEst/
├── Features/
│   ├── Camera/
│   │   ├── CameraFeature.swift
│   │   ├── CameraView.swift
│   │   └── Tests/
│   │       ├── CameraFeatureTests.swift
│   │       └── CameraViewTests.swift
│   └── HandTracking/
│       ├── HandTrackingFeature.swift
│       ├── HandTrackingView.swift
│       └── Tests/
│           └── HandTrackingFeatureTests.swift
```

### メリット・デメリット分析

#### メリット
- **凝集性向上**: 機能とテストが近い場所に配置され、関連性が明確
- **開発効率**: 機能修正時にテストファイルが見つけやすい  
- **モジュール性**: 各機能が独立したテスト可能な単位として管理

#### デメリット
- **Xcode設定の複雑化**: Package.swiftやプロジェクト設定が複雑になる
- **ビルド時間**: テストターゲットが増えると並列ビルドが必要
- **従来慣習からの逸脱**: Swiftコミュニティの一般的な構造と異なる

## 決定事項

### 🚫 **採用見送り**

#### 理由
1. **プロジェクト規模**: HandEstは比較的小規模なプロジェクトで、現在の分離型構造で十分管理可能
2. **TCAアーキテクチャとの適合性**: TCAの単体テストは機能間の依存が少なく、分離型でも問題ない
3. **保守性**: Xcodeの標準的な構造に従う方がメンテナンスしやすい
4. **CI/CD simplicity**: テスト実行の複雑化を避けられる

### 現在の構造を維持
```
HandEst/ (アプリケーションコード)
HandEstTests/ (単体テスト)
HandEstUITests/ (UIテスト)
```

## 将来的な検討事項
- プロジェクトが大規模化した場合は同階層配置への移行を検討可能
- 機能が10個以上に増えた場合は再評価
- チーム開発が本格化した場合の開発効率向上施策として検討

## 作業ログ
### 2025-05-28 15:30
- ユーザーからの質問を受けて調査開始
- Package.swiftの構造を確認
- 同階層配置の技術的実現方法を検証
- Package.swiftで一時的に変更を試行（後で元に戻し）
- メリット・デメリットを分析し採用見送りを決定
- 調査結果をドキュメント化して完了

## 関連情報
- 参考: Webフロントエンドでの同階層テスト配置トレンド
- Swift Package Managerの exclude 機能
- TCAアーキテクチャのテストベストプラクティス