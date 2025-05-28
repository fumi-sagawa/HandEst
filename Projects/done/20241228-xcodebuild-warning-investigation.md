# xcodebuild重複destination警告の調査と対応

## 概要
pre-commit hookでテスト実行時に発生する「Using the first of multiple matching destinations」警告について調査し、対応を実施した。

## 発生した問題
```
--- xcodebuild: WARNING: Using the first of multiple matching destinations:
{ platform:iOS Simulator, id:FEFE7239-CD6E-41F0-85BC-3ADA5798F869, OS:18.3.1, name:iPhone 16 }
{ platform:iOS Simulator, id:FEFE7239-CD6E-41F0-85BC-3ADA5798F869, OS:18.3.1, name:iPhone 16 }
```

同じiPhone 16シミュレータが2回検出されているような警告が表示される。

## 調査結果

### 原因
1. **直接的な原因**: pre-commit hookでiPhone 15を指定していたが、システムにはiPhone 16のみ存在
2. **根本的な原因**: Xcode/xcodebuildの既知の問題で、同じシミュレータが複数回リストされることがある

### 影響
- **実害なし**: テストとビルドは正常に動作
- **パフォーマンスへの影響なし**
- 多くの開発者が経験している一般的な問題

## 実施した対応

### 1. シミュレータ指定の修正
```bash
# 変更前
-destination 'platform=iOS Simulator,name=iPhone 15'

# 変更後
-destination 'platform=iOS Simulator,name=iPhone 16,OS=18.3'
```

### 2. 関連ファイルの更新
- `/Scripts/git-hooks/pre-commit`: iPhone 16に変更
- `/CLAUDE.md`: ビルドコマンド例をiPhone 16に更新

### 3. クリーンアップ作業
- DerivedDataの削除
- CoreSimulatorサービスの再起動
- シミュレータのリセット

## 結論
警告は残るが、これはXcodeの既知の問題であり、実際の開発に影響はない。
心理的に気になるが、無視して進めることが最善の対応。

## 今後の対応
- Xcodeのアップデートで改善される可能性がある
- 必要に応じて特定のUDIDを使用することも検討可能（環境依存になるため非推奨）

## 作業ログ
### 2024-12-28 10:40
- 警告の原因を調査
- pre-commit hookのシミュレータ指定を修正
- CLAUDE.mdのコマンド例を更新
- 各種クリーンアップを実施
- 警告は残るがXcodeの既知の問題と判断し、対応完了