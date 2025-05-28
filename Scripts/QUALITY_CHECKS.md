# HandEst 品質チェックシステム詳細ガイド

## 📊 品質チェックの全体像

HandEstプロジェクトでは、以下の3層構造で品質を保証しています：

```
┌─────────────────────────────────────────┐
│         Layer 3: 手動チェック            │
│    (プッシュ前・レビュー時の確認)        │
├─────────────────────────────────────────┤
│         Layer 2: 自動チェック            │
│      (コミット時・ビルド時)             │
├─────────────────────────────────────────┤
│         Layer 1: リアルタイム            │
│    (エディタ・IDE上での即時確認)         │
└─────────────────────────────────────────┘
```

## 🚦 自動実行される品質チェック

### 1. Pre-commit Hook（コミット前の自動チェック）

**実行タイミング**: `git commit`実行時

**チェック項目と順序**:

```bash
1. SwiftLintチェック（約2-5秒）
   └─ コードスタイル違反を検出

2. ビルド＆テスト（約1-3分）
   ├─ コンパイルエラーのチェック
   ├─ 単体テストの実行
   └─ UIテストの実行

3. テストカバレッジチェック（約1-2秒）
   └─ 純粋関数とReducerのテスト有無を確認
```

**失敗時の挙動**:
- いずれかのチェックが失敗した場合、コミットは中止されます
- エラーメッセージと修正方法が表示されます

**設定ファイル**: `/Scripts/git-hooks/pre-commit`

### 2. Xcodeビルド時のチェック

**実行タイミング**: Xcodeでビルドボタンを押した時

**チェック項目**:
- SwiftLint（preBuildScriptとして実行）
- コンパイラ警告
- 静的解析

**設定ファイル**: `project.yml`

### 3. テストカバレッジチェックの詳細

**対象ファイル**: `Features/`ディレクトリ内の全Swiftファイル

**チェック対象となる要素**:

```swift
// 1. TCA Reducerのreduce関数
struct SomeFeature: Reducer {
    func reduce(into state: inout State, action: Action) -> Effect<Action> {
        // この関数は必ずテストが必要
    }
}

// 2. public/internal関数
public func calculateSomething(_ value: Int) -> Int {
    // この関数は必ずテストが必要
}

// 3. 複雑なビジネスロジック
internal func validateUserInput(_ input: String) -> ValidationResult {
    // この関数は必ずテストが必要
}
```

**テスト不要な要素**:
- private関数（内部実装の詳細）
- 単純なプロパティ
- View（SwiftUI）
- 依存関係のラッパー

## 🔧 手動実行可能なチェック

### 開発フロー別の推奨チェック

#### 1. コーディング中（頻繁に実行）

```bash
# ビルドエラーの確認のみ（最速: 10-30秒）
./Scripts/quick-check.sh

# または特定ファイルのSwiftLintチェック
swiftlint lint --path Features/Camera/CameraFeature.swift
```

#### 2. 機能実装完了時

```bash
# 関連するテストのみ実行
xcodebuild -scheme HandEst test -only-testing:HandEstTests/CameraFeatureTests

# SwiftLint自動修正
swiftlint --fix
```

#### 3. プッシュ前（必須）

```bash
# フルテストの実行
xcodebuild -scheme HandEst test

# 全ファイルのSwiftLintチェック
swiftlint

# テストカバレッジの確認
./Scripts/check-test-coverage.swift
```

## 📏 品質基準と設定

### SwiftLintルール（主要なもの）

| ルール | 設定値 | 目的 |
|--------|--------|------|
| line_length | 120文字 | 可読性の確保 |
| file_length | 400行 | ファイルの適切な分割 |
| function_body_length | 40行 | 関数の責任範囲の制限 |
| cyclomatic_complexity | 10 | 複雑度の抑制 |
| force_cast | エラー | 安全なキャストの強制 |
| force_unwrapping | 警告（一部許可） | nilの適切な処理 |

### ビルド最適化設定

```bash
-parallelizeTargets  # ターゲットの並列ビルド
-jobs 8             # 8並列でのビルド実行
-quiet              # 不要な出力を抑制
```

### テスト実行時間の目安

- 単体テスト: 10-30秒
- UIテスト: 30-60秒
- フルテスト: 1-3分

## 🚨 トラブルシューティング

### よくある問題と解決方法

#### 問題1: "Line Length Violation"

```swift
// ❌ エラー: 120文字を超えている
let veryLongVariableName = "This is a very long string that exceeds the maximum line length limit set by SwiftLint rules"

// ✅ 解決方法1: 改行する
let veryLongVariableName = """
    This is a very long string that exceeds the maximum 
    line length limit set by SwiftLint rules
    """

// ✅ 解決方法2: 一時的に無効化（どうしても必要な場合のみ）
// swiftlint:disable:next line_length
let veryLongVariableName = "This is a very long string that exceeds the maximum line length limit set by SwiftLint rules"
```

#### 問題2: テストが見つからないエラー

```
❌ calculateFocalLength のテストがありません
```

**解決方法**:
1. 対応するテストファイルを作成
2. テスト関数を実装
3. または、privateに変更して内部実装とする

#### 問題3: コミット時のタイムアウト

**症状**: pre-commit hookが2分以上かかる

**解決方法**:
- 並列ビルドが有効になっているか確認
- 不要なファイルがビルド対象になっていないか確認
- Derived Dataをクリーン: `rm -rf ~/Library/Developer/Xcode/DerivedData/HandEst-*`

## 📈 品質メトリクスの活用

### 現在の品質状態を確認

```bash
# SwiftLintの統計情報
swiftlint analyze

# テストカバレッジの詳細
xcodebuild test -enableCodeCoverage YES
```

### 継続的な改善

1. **週次レビュー**: SwiftLintの警告数の推移を確認
2. **新機能追加時**: 必ずテストを先に書く（TDD）
3. **リファクタリング時**: テストカバレッジを維持または向上

## 🎓 ベストプラクティス

### 1. コミットメッセージ

```bash
# ✅ 良い例（具体的で明確）
git commit -m "feat: カメラ権限リクエストのエラーハンドリングを追加"

# ❌ 悪い例（曖昧）
git commit -m "バグ修正"
```

### 2. テストの書き方

```swift
// ✅ 良いテスト（明確な期待値とアサーション）
func testCameraPermissionDenied() async {
    let store = TestStore(
        initialState: CameraFeature.State(),
        reducer: { CameraFeature() }
    )
    
    await store.send(.requestPermission)
    await store.receive(.permissionResponse(.denied)) {
        $0.permissionStatus = .denied
        $0.showPermissionAlert = true
    }
}

// ❌ 悪いテスト（曖昧で網羅的でない）
func testCamera() {
    // テスト内容が不明確
}
```

### 3. 品質チェックのスキップ

```bash
# ⚠️ 緊急時のみ使用
git commit --no-verify -m "hotfix: 緊急修正"

# 📝 理由を明記
git commit --no-verify -m "WIP: MediaPipe統合中（ビルドエラーあり）"
```

## 🔗 関連ドキュメント

- [CLAUDE.md](../CLAUDE.md) - プロジェクト全体のガイドライン
- [.swiftlint.yml](../.swiftlint.yml) - SwiftLintの詳細設定
- [The Composable Architecture - Testing](https://pointfreeco.github.io/swift-composable-architecture/main/documentation/composablearchitecture/testing) - TCAのテストガイド

---

最終更新: 2024年12月28日
作成者: HandEst開発チーム