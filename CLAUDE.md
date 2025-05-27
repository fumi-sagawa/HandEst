# CLAUDE.md

このファイルは、このリポジトリでコードを扱う際のClaude Code (claude.ai/code) への指針を提供します。

## 言語設定

このプロジェクトでは**日本語**を基本言語として使用します。コメント、ドキュメント、コミットメッセージなどは日本語で記述してください。

## プロジェクト概要

HandEstは、ユーザーの手をリアルタイムで3Dモデルに変換し、アーティストの参考資料として提供するiOSアプリケーションです。手のトラッキングにはMediaPipe、3DレンダリングにはRealityKitを使用します。

## 主要技術

- **SwiftUI**: メインUIフレームワーク
- **The Composable Architecture (TCA)**: 状態管理
- **RealityKit**: スキンメッシュ対応の3Dレンダリング
- **MediaPipe Hands**: 21点の手トラッキング用MLフレームワーク
- **AVFoundation**: カメラアクセス

## ビルドコマンド

```bash
# アプリをビルド
xcodebuild -scheme HandEst -configuration Debug build

# テストを実行  
xcodebuild -scheme HandEst test

# リリース用にビルド
xcodebuild -scheme HandEst -configuration Release archive

# ビルドフォルダをクリーン
xcodebuild -scheme HandEst clean

# シミュレータで実行
xcodebuild -scheme HandEst -destination 'platform=iOS Simulator,name=iPhone 15' build
```

## Git Hooks設定

このプロジェクトではコミット前に自動的にテストを実行するGit hooksを使用しています。

### セットアップ方法

1. **自動インストール（推奨）**
```bash
./Scripts/install-hooks.sh
```

2. **手動インストール**
```bash
# pre-commit hookを有効化
chmod +x .git/hooks/pre-commit
```

### pre-commit hookの内容

コミット前に以下のチェックが自動実行されます：
- 🧪 全テストの実行
- 🧹 SwiftLintによるコード品質チェック（インストール済みの場合）
- 🔨 ビルドの成功確認

### hookをスキップしたい場合

緊急時やWIP（Work In Progress）コミットの場合：
```bash
git commit --no-verify -m "WIP: 作業中の内容"
```

**注意**: `--no-verify`の使用は最小限に留めてください。

## アーキテクチャ

アプリはレイヤードアーキテクチャに従います：

1. **プレゼンテーション層**: `HandEst/`内のSwiftUIビュー
2. **状態管理**: アプリ状態を管理するTCAのReducerとStore
3. **3Dレンダリング**: 手の可視化のためのRealityKitエンティティ
4. **ML処理**: リアルタイム手トラッキング用MediaPipe統合
5. **カメラ層**: カメラフィード処理用AVFoundation

## コア機能の実装

### カメラと手のトラッキング
- ビデオデータ出力付きの`AVCaptureSession`を使用
- MediaPipeの`HandLandmarker`でフレームを処理
- 21個のランドマークを3D位置に変換

### 3Dモデルレンダリング
- RealityKitでスキンメッシュを作成
- MediaPipeのジョイントをメッシュスケルトンにマッピング
- マテリアルとライティングを適用

### 焦点距離シミュレーション
- パースペクティブ変換の実装:
  - 魚眼: バレル歪み
  - 24mm/50mm/85mm: FOVベースの投影
  - 平行投影: 正投影

### TCAによる状態管理
- 各画面ごとにFeatureドメインを定義
- カメラ権限、手のトラッキング状態、ユーザーインタラクションを処理
- ポーズロック状態と3D変換を管理

## テスト

- TCAのReducerと状態ロジックの単体テスト
- 重要なユーザーフローのUIテスト
- 手のトラッキングフレームレートのパフォーマンステスト

## 重要なファイル

- `Projects/要件定義.md`: 元の要件
- `Projects/機能要件仕様書.md`: 詳細な機能仕様
- `Projects/デザイン.md`: UI/UXデザイン仕様

## アーキテクチャ哲学 - The Composable Architecture (TCA)

このプロジェクトは保守可能でテスタブルなアーキテクチャのためにThe Composable Architecture (TCA)のベストプラクティスに従います：

### ディレクトリ構造の原則
```
HandEst/
├── App/                    # アプリケーションのエントリーポイント
│   ├── HandEstApp.swift    # @main
│   └── AppFeature.swift    # ルートReducer
├── Features/               # 機能モジュール（Model-Reducer-View）
│   ├── Camera/
│   │   ├── CameraFeature.swift      # Reducer（State/Action/Logic）
│   │   ├── CameraView.swift         # SwiftUIビュー
│   │   └── CameraClient.swift       # 依存関係クライアント
│   ├── HandTracking/
│   │   ├── HandTrackingFeature.swift
│   │   ├── HandTrackingView.swift
│   │   └── MediaPipeClient.swift
│   ├── Rendering/
│   │   ├── RenderingFeature.swift
│   │   ├── RenderingView.swift
│   │   └── RealityKitClient.swift
│   └── Settings/
│       ├── SettingsFeature.swift
│       └── SettingsView.swift
├── Models/                 # 共有データモデル
│   ├── Hand.swift          # 手のモデル
│   ├── CameraSettings.swift
│   └── RenderingSettings.swift
├── Shared/                 # 共有コンポーネント
│   ├── Views/              # 再利用可能なビュー
│   ├── Extensions/         # Swift拡張
│   ├── Helpers/            # ヘルパー関数
│   └── Dependencies/       # TCA依存関係
└── Resources/              # アセット、ローカライゼーション
```

### TCAの基本原則（Flux的なデータフロー）

1. **単一方向データフロー**: 
   - View → Action → Reducer → State → View
   - Stateの変更は必ずReducer経由で行う
   - 副作用はEffectとして明示的に扱う

2. **Feature分割の原則**:
   - 各Featureは独自のState、Action、Reducerを持つ
   - 親Featureは子Featureを組み合わせて構成
   - Featureは`@Reducer`マクロで定義

3. **依存関係の管理**:
   - 外部依存関係は`DependencyClient`として定義
   - テスト時はモックに置き換え可能
   - `@Dependency`プロパティラッパーで注入

## プロジェクト管理

### プロジェクトフォルダ構造
```
Projects/
├── 要件定義.md          # プロジェクトの要件定義書
├── 機能要件仕様書.md    # 詳細な機能仕様
├── デザイン.md          # UI/UXデザイン仕様
├── Hand Estデザインイメージ.png  # デザインイメージ
└── tasks/               # タスク管理フォルダ
    ├── todo/            # 未着手のタスク
    ├── doing/           # 作業中のタスク
    └── done/            # 完了したタスク
```

### タスク管理フロー
1. **新規タスク作成**: `Projects/tasks/todo/` に新しいタスクファイルを作成
2. **作業開始**: タスクファイルを `doing/` フォルダに移動し、対応するブランチを作成
3. **作業完了**: タスクファイルを `done/` フォルダに移動

### タスクチケットテンプレート
```markdown
# タスク名: [わかりやすいタスク名]

## 概要
[このタスクで実現したいことの概要]

## 背景・目的
[なぜこのタスクが必要なのか]

## To-Be（完了条件）
- [ ] 実装完了条件1
- [ ] 実装完了条件2
- [ ] テストが全て通る
- [ ] ドキュメント更新完了

## 実装方針
[どのように実装するかの方針]

## 関連情報
- 関連Issue: #XX
- 参考資料: [リンク]

## 作業ログ
### YYYY-MM-DD HH:MM
- 作業内容の記録
- 発生した問題と解決方法
- 次回の作業予定
```

### タスク管理のベストプラクティス
- タスクファイル名は `チケット番号-タスク名.md` の形式で作成
- 作業ログは時系列で追記し、後から見返せるようにする
- ブランチ名はタスクファイル名と対応させる（例: `feature/tikect_number-camera-setup`）
- 完了したタスクも削除せず、`done/` フォルダに保管して知識として蓄積

## 機能実装時の作業フロー

**重要**: ユーザーからタスクファイルパス（例: `Projects/tasks/todo/tikect_number-camera-setup.md`）が指定されたら、以下の手順を順番通りに実行すること。

### 0. 作業開始前の自動実行事項
タスクファイルパスが指定されたら、即座に以下を実行：
1. タスクファイルを読み込み、内容を確認
2. ファイル名からブランチ名を決定（例: `feature/20240524-camera-setup`）
3. ブランチを作成・切り替え
4. タスクファイルをdoingフォルダに移動
5. 作業開始を宣言

### 1. **チケット選択とブランチ作成**
```bash
# todoフォルダから作業するチケットを選択
# 例: 20240524-camera-setup.md を選択した場合

# ブランチを作成して移動
git checkout -b feature/20240524-camera-setup

# チケットをdoingフォルダに移動
mv Projects/tasks/todo/20240524-camera-setup.md Projects/tasks/doing/
```

### 2. **作業中のログ記録**
- 大きな実装ステップ完了時に、チケットの作業ログを更新
- 以下のタイミングでログ更新を実施：
  - 主要な機能の実装完了時
  - 重要な問題の解決時
  - テストの作成完了時
- 細かい修正や調整では更新不要（自立的に作業を進める）

### 3. **作業完了時**

1. **テストの実行と確認**
   ```bash
   # 全テストが通ることを確認
   xcodebuild -scheme HandEst test
   ```

2. **ビルドとユーザーへの報告**
   ```bash
   # アプリをビルドしてシミュレータで起動
   xcodebuild -scheme HandEst -destination 'platform=iOS Simulator,name=iPhone 15' build
   open -a Simulator
   ```
   
   報告内容に含めるもの：
   - 実装した機能の概要
   - 動作確認方法（どの画面でどう操作するか）
   - スクリーンショットや動画（必要に応じて）

3. **承認後の作業**
   ```bash
   # チケットをdoneフォルダに移動
   mv Projects/tasks/doing/チケット番号-タスク名.md Projects/tasks/done/
   
   # 変更をステージング
   git add .
   
   # コミット作成（Git hookによりテストが自動実行される）
   git commit -m "feat: 実装した機能の説明"
   
   # developブランチに戻ってマージ
   git checkout develop
   git merge feature/チケット番号-タスク名
   
   # リモートにプッシュ
   git push origin develop
   ```

## 開発アプローチ - SwiftUIとTCAでの型定義駆動TDD

このプロジェクトではSwiftUIとThe Composable Architecture (TCA)を使用した型定義駆動のテスト駆動開発を採用しています：

### 型定義駆動TDDのフロー
1. **要件の確認** - `Projects/機能要件仕様書.md` で実装対象の機能仕様を確認
2. **型定義の作成** - TCAのState/Action/Environmentの型を定義
3. **型に基づくテスト設計** - Reducerのテストケースを作成
4. **実装** - テストが通るように実装
5. **リファクタリング** - 型とテストを維持しながらコードを改善

### 実践例（カメラ機能）
```swift
// 1. 型定義を作成
struct CameraFeature: Reducer {
    struct State: Equatable {
        var isAuthorized: Bool = false
        var isCameraActive: Bool = false
        var currentFrame: CVPixelBuffer?
        var error: CameraError?
    }
    
    enum Action: Equatable {
        case onAppear
        case requestCameraPermission
        case cameraPermissionResponse(Bool)
        case startCamera
        case stopCamera
        case frameReceived(CVPixelBuffer)
        case errorOccurred(CameraError)
    }
    
    @Dependency(\.cameraManager) var cameraManager
    
    // 2. Reducerロジックを実装
    func reduce(into state: inout State, action: Action) -> Effect<Action> {
        switch action {
        case .onAppear:
            return .run { send in
                let isAuthorized = await cameraManager.checkAuthorizationStatus()
                await send(.cameraPermissionResponse(isAuthorized))
            }
        // ... 他のアクション処理
        }
    }
}

// 3. テストを作成
final class CameraFeatureTests: XCTestCase {
    @MainActor
    func testCameraPermissionFlow() async {
        let store = TestStore(
            initialState: CameraFeature.State(),
            reducer: { CameraFeature() }
        ) {
            $0.cameraManager = .testValue
        }
        
        await store.send(.onAppear)
        await store.receive(.cameraPermissionResponse(true)) {
            $0.isAuthorized = true
        }
    }
}
```

### テスト作成のガイドライン
- TCAのTestStoreを使用して状態遷移をテスト
- 非同期処理は`@MainActor`と`async/await`で処理
- 依存関係は`withDependencies`でモック化
- 正常系・異常系・エッジケースを網羅

### SwiftUIビューのテスト
```swift
// ViewInspectorを使用したUIテスト
func testCameraViewShowsPermissionAlert() throws {
    let view = CameraView(
        store: Store(
            initialState: CameraFeature.State(isAuthorized: false),
            reducer: { CameraFeature() }
        )
    )
    
    let alert = try view.inspect().alert()
    XCTAssertEqual(try alert.title().string(), "カメラへのアクセスが必要です")
}
```

## 🚨 重要：機能実装完了時の報告ルール

**機能追加やコード変更が完了し、コミットする前は必ずユーザーに報告してください。**

### 報告すべき内容
1. **実装した機能の概要**
2. **変更されたファイル一覧**
3. **テスト結果（全て通過していることを確認）**
4. **動作確認の結果**
5. **コミットメッセージの提案**

### 実機テストが必要な機能の報告フロー

カメラやMediaPipeなど、シミュレータでテストできない機能の場合：

1. **タスクの進捗状況を明確に報告**
   ```
   例：「カメラ機能の実装を完了しました。以下のタスクが完了しています：
   ✅ カメラ権限のリクエスト処理
   ✅ AVCaptureSessionの初期化
   ✅ TCAのReducer実装
   ⏳ 実機での動作確認が必要
   ```

2. **残タスクの明確化**
   ```
   例：「実機で以下の確認が必要です：
   - カメラ権限ダイアログの表示と承認フロー
   - カメラプレビューの正常表示
   - フレームレートが60fpsで安定しているか
   これらが確認できたら、このチケットは完了となります。」
   ```

3. **チケットの作業ログを活用**
   - タスクファイルのTo-Be（完了条件）を参照
   - 完了したタスクと未完了タスクを明示
   - 次のステップを具体的に提示

### 報告例テンプレート

```markdown
## 作業完了報告

### 実装内容
[実装した機能の概要]

### 完了したタスク
- ✅ [完了タスク1]
- ✅ [完了タスク2]
- ✅ 単体テストの作成と実行

### 実機確認が必要なタスク
- ⏳ [確認項目1]
- ⏳ [確認項目2]

### 次のアクション
「実機で上記の動作確認を行い、問題がなければこのチケットは完了です。
確認方法：[具体的な確認手順]」

### 変更ファイル
- HandEst/Features/Camera/CameraFeature.swift
- HandEst/Features/Camera/CameraView.swift
- （他のファイル一覧）
```

### 報告のタイミング
- 新機能の実装が完了した時
- 既存機能の修正・改善が完了した時
- ドキュメントの更新が完了した時
- リファクタリングが完了した時

### 報告後の流れ
1. ユーザーの確認・承認を得る
2. 実機テストの結果を待つ（必要な場合）
3. 承認後にコミット・プッシュを実行

**注意**: ユーザーの明示的な承認なしに、勝手にコミット・プッシュは行わないでください。

## 実装の優先順位

1. **型定義** - TCAのState/Action/Environmentを最初に定義
2. **テスト** - 型定義に基づいてReducerのテストを作成
3. **実装** - テストが通るように実装
4. **ビュー** - TCAストアと連携するSwiftUIビューを実装
5. **ドキュメント** - 実装と同時に更新

## コード品質の維持

- 型定義は各Featureディレクトリ内に配置
- テストは型定義を直接使用
- 実装は型定義に厳密に従う
- SwiftUIビューはTCAのViewStoreを使用して状態を監視