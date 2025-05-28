# タスク名: プロジェクト環境構築とアーキテクチャ基盤実装

## 概要
HandEstプロジェクトの基本的な開発環境を構築し、The Composable Architecture (TCA)を使用したアプリケーションアーキテクチャを設計・実装する。

## 背景・目的
- 堅牢でテスタブルなアプリケーション基盤の構築
- TCAによる単一方向データフローの実現
- 今後の機能開発がスムーズに進められる土台作り

## 優先度
**High** - 他の全ての実装タスクの前提となる

## 前提条件
- #000（プロジェクト技術方針）が完了していること

## To-Be（完了条件）
- [ ] TCAのSwift Package依存関係を追加
- [ ] 基本的なディレクトリ構造の作成
- [ ] AppFeature（ルートReducer）の実装
- [ ] 基本的なContentViewとの接続
- [ ] ロギングシステムの基盤構築（Logger）
- [ ] 基本的なエラー型定義（AppError）
- [ ] TCAでのエラー処理パターン確立
- [ ] テストターゲットの設定とサンプルテストの作成
- [ ] XcodeプロジェクトとSwift Packageの同期
- [ ] Git hooksの設定（pre-commit）
- [ ] SwiftLintの導入と設定
- [ ] ドキュメント更新完了

## 実装方針
1. Package.swiftにTCAの依存関係を追加
   - TCA 1.0以上の最新安定版を使用
   - 必要な関連パッケージも同時に追加
2. CLAUDE.mdに記載されているディレクトリ構造を作成
   - Features/
   - Models/
   - Shared/（Helpers/, Extensions/, Dependencies/を含む）
   - Resources/
3. 最小限のTCA実装でアプリが起動することを確認
   - AppFeatureの基本実装
   - 空のStateとReducer
4. 開発基盤の整備
   - Shared/Helpers/Logger.swift（デバッグログシステム）
   - Models/AppError.swift（共通エラー型）
   - TCAのalert/confirmationDialog処理パターン
   - エラー処理のサンプル実装
5. 開発環境の整備
   - Scripts/フォルダの活用
   - テスト自動実行の確認

## 関連情報
- 前提タスク: #000（プロジェクト技術方針）
- The Composable Architecture: https://github.com/pointfreeco/swift-composable-architecture
- プロジェクト構造: CLAUDE.mdのアーキテクチャ哲学セクション参照
- Projects/done/20241203-vscode-xcode-integration.md

## 作業ログ
### YYYY-MM-DD HH:MM
- 作業内容の記録
- 発生した問題と解決方法
- 次回の作業予定