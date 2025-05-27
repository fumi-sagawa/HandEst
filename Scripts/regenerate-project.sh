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