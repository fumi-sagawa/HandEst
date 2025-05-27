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