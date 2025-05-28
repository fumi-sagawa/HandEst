# タスク名: TCAを使用した基本的な状態管理の実装

## 概要
The Composable Architectureを使用して、アプリケーション全体の状態管理基盤を構築する。各機能のFeatureとそれらを統合するAppFeatureを実装する。

## 背景・目的
- アプリ全体の状態を一元管理
- 各機能間の状態共有とアクション伝達の仕組み構築
- テスタブルな状態管理の実現

## 優先度
**High** - アプリケーションの中核となる状態管理

## 前提条件
- #001（プロジェクト環境構築）が完了していること

## To-Be（完了条件）
- [ ] AppFeatureのState/Action/Reducerを実装
- [ ] 各FeatureのScopeを定義
- [ ] Dependencyクライアントの基本構造を作成
- [ ] 状態の永続化（UserDefaults）の仕組みを実装
- [ ] エラー処理の共通化実装
- [ ] AppFeatureの単体テストを作成
- [ ] TestStoreを使用した状態遷移テスト
- [ ] テストが全て通る
- [ ] ドキュメント更新完了

## 実装方針
1. AppFeatureで管理する全体状態を定義
   - カメラ状態（権限、アクティブ状態）
   - 手認識状態（認識中、ロック状態、左右判別）
   - 3Dレンダリング状態（焦点距離、回転、拡大率）
   - ユーザー設定（デフォルト値、触覚フィードバック）
2. 子Featureへの状態分割（Scope）を実装
   - CameraFeature
   - HandTrackingFeature
   - RenderingFeature
   - SettingsFeature
3. 依存関係注入の仕組みを構築
   - @Dependency使用
   - テスト用モックの準備
4. 共通エラー型の定義
   - AppError列挙型
   - リカバリーアクション

## 関連情報
- 前提タスク: #001（プロジェクト環境構築）
- TCA公式ドキュメント: Composing features
- CLAUDE.md: TCAの基本原則セクション

## 作業ログ
### 2025-05-28 13:15
- AppFeatureの状態管理基盤を完成
- 各Feature（Camera/HandTracking/Rendering/Settings）の雛形を実装
- Dependencyクライアント（CameraManager/UserDefaultsManager）の基本構造を作成
- TCA+ErrorHandling拡張で共通エラーハンドリングを実装
- AppFeatureのTestStoreを使用した包括的な単体テストを作成
- 全14テストが成功、TCAアーキテクチャの状態管理基盤が完成
- 次回以降のタスクで具体的な機能実装（カメラアクセス、MediaPipe統合等）を進める