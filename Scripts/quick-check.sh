#!/bin/bash
# 高速チェック用スクリプト（コミット前の簡易確認）

echo "🚀 Running quick checks..."

# SwiftLintのみ実行（高速、エラーのみ表示）
echo "🧹 Running SwiftLint..."
if [ -f /opt/homebrew/bin/swiftlint ]; then
    if /opt/homebrew/bin/swiftlint lint --quiet 2>&1 | grep "error:"; then
        echo "❌ SwiftLint errors found!"
    else
        echo "✅ No lint errors!"
    fi
elif [ -f /usr/local/bin/swiftlint ]; then
    if /usr/local/bin/swiftlint lint --quiet 2>&1 | grep "error:"; then
        echo "❌ SwiftLint errors found!"
    else
        echo "✅ No lint errors!"
    fi
else
    echo "⚠️ SwiftLint not found, skipping..."
fi

# ビルドのみ（テストなし、より高速）
echo "🔨 Quick build check..."
xcodebuild -scheme HandEst -configuration Debug -destination 'platform=iOS Simulator,name=iPhone 16' \
    -parallelizeTargets -jobs 8 \
    build \
    CODE_SIGN_IDENTITY="" \
    CODE_SIGNING_REQUIRED=NO \
    -quiet

if [ $? -eq 0 ]; then
    echo "✅ Quick checks passed!"
    echo ""
    echo "💡 Tip: Run full tests before pushing:"
    echo "   xcodebuild -scheme HandEst test"
else
    echo "❌ Build failed!"
    exit 1
fi