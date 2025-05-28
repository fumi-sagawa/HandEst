# Scripts ディレクトリ - HandEst品質管理システム

このディレクトリには、HandEstプロジェクトの品質を維持するための自動化スクリプトとツールが含まれています。

## 🎯 品質管理の目的

1. **バグの早期発見**: コミット前にエラーを検出し、開発効率を向上
2. **コード品質の維持**: 統一されたコーディングスタイルで可読性を確保
3. **テスト駆動開発の促進**: TCAの原則に基づいた確実なテストカバレッジ
4. **安全なリファクタリング**: 包括的なテストによる変更の安全性確保

## スクリプト一覧

### regenerate-project.sh
xcodegenを使用してXcodeプロジェクトファイルを再生成します。
新しいファイルを追加した後に実行してください。

```bash
./Scripts/regenerate-project.sh
```

### install-hooks.sh
Git hooksをインストールします。
これにより、コミット前に自動的にテストが実行されます。

```bash
./Scripts/install-hooks.sh
```

### sync-xcode.sh
Xcodeプロジェクトをバックグラウンドで開いて同期します。
（通常はregernate-project.shの使用を推奨）

```bash
./Scripts/sync-xcode.sh
```

### check-test-coverage.swift
純粋関数とReducerのテストカバレッジをチェックします。
pre-commitフックで自動実行されます。

```bash
./Scripts/check-test-coverage.swift
```

#### チェック対象
- Reducerの`reduce`メソッド
- public/internalな純粋関数
- Featureファイルに対応するTestファイルの存在

#### 出力例
```
🔍 テストカバレッジをチェック中...
📄 CameraFeature.swift
   ✅ reduce
   ❌ calculateFocalLength のテストがありません
```

## git-hooks/ ディレクトリ

Git hooksのテンプレートが含まれています：
- `pre-commit`: コミット前にテストとビルドを実行

これらのファイルはGitで管理され、`install-hooks.sh`によって
`.git/hooks/`にコピーされます。

### quick-check.sh
開発中の高速ビルドチェック用スクリプト。テストをスキップしてビルドのみ実行します。

```bash
./Scripts/quick-check.sh
```

**用途**: コーディング中の素早いエラーチェック（約10-30秒）
**注意**: コミット前には必ずフルテストを実行してください

