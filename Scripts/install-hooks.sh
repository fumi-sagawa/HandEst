#!/bin/bash

# Git hooksをインストールするスクリプト

HOOKS_DIR=".git/hooks"
SCRIPTS_DIR="Scripts/git-hooks"

echo "📦 Installing git hooks..."

# Scripts/git-hooksディレクトリが存在しない場合は作成
mkdir -p "$SCRIPTS_DIR"

# pre-commit hookをコピー
if [ -f "$SCRIPTS_DIR/pre-commit" ]; then
    cp "$SCRIPTS_DIR/pre-commit" "$HOOKS_DIR/pre-commit"
    chmod +x "$HOOKS_DIR/pre-commit"
    echo "✅ pre-commit hook installed"
fi

# pre-push hookをコピー（オプション）
if [ -f "$SCRIPTS_DIR/pre-push" ]; then
    cp "$SCRIPTS_DIR/pre-push" "$HOOKS_DIR/pre-push"
    chmod +x "$HOOKS_DIR/pre-push"
    echo "✅ pre-push hook installed"
fi

echo "🎉 Git hooks installation complete!"