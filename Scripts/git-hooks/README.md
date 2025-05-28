# Git Hooks ドキュメント

## 概要

このディレクトリには、HandEstプロジェクトで使用するGit Hooksが含まれています。
Git Hooksは、Gitの特定のアクションが実行される前後に自動的に実行されるスクリプトです。

## 現在実装されているHooks

### pre-commit

**実行タイミング**: `git commit`コマンド実行時（コミットメッセージ入力前）

**目的**: 
- 品質の低いコードがリポジトリに入ることを防ぐ
- チーム全体で一貫した品質基準を維持する
- 早期にエラーを発見し、修正コストを削減する

**実行内容**:

```bash
# 1. ビルドとテストの実行（1-3分）
xcodebuild -scheme HandEst test
├─ SwiftLintによるコード品質チェック
├─ コンパイルエラーの検出
├─ 単体テストの実行
└─ UIテストの実行

# 2. テストカバレッジチェック（1-2秒）
./Scripts/check-test-coverage.swift
└─ TCAの原則に基づくテスト必須項目の確認
```

## セットアップ方法

### 自動インストール（推奨）

```bash
./Scripts/install-hooks.sh
```

このスクリプトは以下を実行します：
1. `git-hooks/`内のファイルを`.git/hooks/`にコピー
2. 実行権限を付与
3. 既存のhooksをバックアップ

### 手動インストール

```bash
# pre-commit hookをコピー
cp Scripts/git-hooks/pre-commit .git/hooks/pre-commit

# 実行権限を付与
chmod +x .git/hooks/pre-commit
```

## 使用方法

### 通常のコミット

```bash
git add .
git commit -m "feat: 新機能の追加"
# → 自動的にテストとチェックが実行される
```

### チェックをスキップする場合（非推奨）

```bash
# 緊急時のみ使用
git commit --no-verify -m "hotfix: 緊急修正"
```

**注意**: `--no-verify`の使用は最小限に留めてください。
品質チェックをスキップすると、後で問題が発生する可能性があります。

## 実行時間とパフォーマンス

### 実行時間の内訳

| フェーズ | 実行時間 | 内容 |
|---------|----------|------|
| SwiftLint | 2-5秒 | コードスタイルチェック |
| ビルド | 30-60秒 | コンパイルエラーの検出 |
| テスト | 30-90秒 | 単体テスト・UIテスト |
| カバレッジ | 1-2秒 | テスト必須項目の確認 |
| **合計** | **1-3分** | 全チェック |

### パフォーマンス最適化

pre-commit hookは以下の最適化を行っています：

```bash
# 並列ビルドオプション
-parallelizeTargets  # ターゲットを並列でビルド
-jobs 8             # 最大8ジョブを同時実行
```

## エラーが発生した場合

### よくあるエラーと対処法

#### 1. SwiftLint違反

```
❌ Line Length Violation: Line should be 120 characters or less
```

**対処法**:
```bash
# 自動修正を試す
swiftlint --fix

# 手動で修正後、再度コミット
git add .
git commit -m "メッセージ"
```

#### 2. テスト失敗

```
❌ Tests failed! Please fix the failing tests before committing.
```

**対処法**:
```bash
# 失敗したテストの詳細を確認
xcodebuild -scheme HandEst test

# テストを修正後、再度コミット
```

#### 3. テストカバレッジ不足

```
⚠️ 警告: 純粋関数またはReducerのテストが不足しています
```

**対処法**:
- 指摘された関数のテストを追加
- または、privateに変更して内部実装とする

## カスタマイズ

### hookの編集

`Scripts/git-hooks/pre-commit`を編集して、独自のチェックを追加できます：

```bash
# 例: TODOコメントの検出
echo "🔍 Checking for TODO comments..."
if grep -r "TODO:" --include="*.swift" . | grep -v "Tests"; then
    echo "⚠️ TODO comments found in production code!"
fi
```

編集後は再インストールが必要です：
```bash
./Scripts/install-hooks.sh
```

### 環境変数

以下の環境変数で動作を制御できます：

| 変数名 | 説明 | 使用例 |
|--------|------|--------|
| CLAUDE_BASH_TIMEOUT | タイムアウト時間（ミリ秒） | `600000`（10分） |

## トラブルシューティング

### hookが実行されない

```bash
# hookの存在確認
ls -la .git/hooks/pre-commit

# 実行権限の確認
ls -la .git/hooks/pre-commit
# → -rwxr-xr-x であることを確認

# 再インストール
./Scripts/install-hooks.sh
```

### タイムアウトエラー

`.claude/settings.local.json`でタイムアウトを延長：
```json
{
  "environment": {
    "CLAUDE_BASH_TIMEOUT": "600000"
  }
}
```

## ベストプラクティス

1. **小さく頻繁なコミット**: 大きな変更は問題の特定を困難にします
2. **意味のあるコミットメッセージ**: 何を変更したかではなく、なぜ変更したかを書く
3. **テストファースト**: 実装前にテストを書くことで、設計が改善されます
4. **定期的なフルテスト**: pushする前には必ず全テストを実行

## 関連リソース

- [Git Hooks公式ドキュメント](https://git-scm.com/book/en/v2/Customizing-Git-Git-Hooks)
- [HandEst品質チェックシステム](../QUALITY_CHECKS.md)
- [プロジェクトガイドライン](../../CLAUDE.md)

---

最終更新: 2024年12月28日