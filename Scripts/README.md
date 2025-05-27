# Scripts ディレクトリ

このディレクトリには、開発を支援するスクリプトが含まれています。

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

## git-hooks/ ディレクトリ

Git hooksのテンプレートが含まれています：
- `pre-commit`: コミット前にテストとビルドを実行

これらのファイルはGitで管理され、`install-hooks.sh`によって
`.git/hooks/`にコピーされます。