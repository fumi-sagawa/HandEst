# タスク名: カメラアクセスと権限管理機能の実装

## 概要
AVFoundationを使用したカメラアクセス機能と、iOS標準のカメラ権限リクエスト・管理機能を実装する。TCAのDependencyとして実装し、テスタブルな設計にする。

## 背景・目的
- ユーザーの手を認識するためのカメラ映像取得
- 適切な権限管理によるプライバシー保護
- エラーハンドリングの基盤構築

## 優先度
**High** - MediaPipe手認識の前提となる基本機能

## 前提条件
- #002（TCA状態管理）が完了していること

## To-Be（完了条件）
- [x] CameraClientの依存関係を定義
- [x] AVCaptureSessionの初期化と管理
- [x] カメラ権限のリクエストと状態管理
- [x] CameraFeatureのReducer実装
- [x] カメラプレビューの表示（SwiftUI）
- [x] 権限拒否時のエラーハンドリング
- [x] カメラ初期化エラーの処理（Logger使用）
- [x] エラーメッセージの基本実装（AppError使用）
- [x] バックグラウンド時の自動停止
- [x] CameraFeatureの単体テスト作成
- [x] エラーケースのテスト作成
- [x] 実機での動作確認（権限ダイアログ、プレビュー表示）
- [x] テストが全て通る
- [x] ドキュメント更新完了

## 実装方針
1. CameraClient依存関係の定義
   - 権限チェック（async/await）
   - セッション開始/停止
   - フレーム取得のデリゲート
   - デバイス切り替え（前面/背面）
2. CameraFeatureの実装
   - State: 権限状態、カメラ状態、エラー、現在のデバイス
   - Action: 権限リクエスト、開始/停止、デバイス切替
   - Effect: 権限要求、セッション制御
3. SwiftUIでのプレビュー表示
   - AVCaptureVideoPreviewLayerのUIViewRepresentable化
   - 適切なContentModeの設定
   - 回転対応
4. Info.plistへの権限説明追加
   - NSCameraUsageDescription
   - 日本語と英語の説明文

## 関連情報
- 前提タスク: #002（TCA状態管理）
- AVFoundation公式ドキュメント
- 要件定義書: 5.4 セキュリティ・プライバシー要件
- 機能要件仕様書: 4.1 アプリケーション起動時の動作

## 作業ログ
### 2025-05-28 14:00
- ✅ CameraManager依存関係を実装（AVFoundation完全統合）
- ✅ CameraFeatureのState/Action/Reducer実装（TCA完全準拠）
- ✅ CameraViewとCameraPreviewView実装（SwiftUI+UIViewRepresentable）
- ✅ project.ymlにカメラ権限説明を追加（NSCameraUsageDescription）
- ✅ AppErrorとLoggerを活用したエラーハンドリング
- ✅ バックグラウンド/フォアグラウンド自動制御
- ✅ 15個の単体テストを作成・全テスト成功

### 実装内容詳細
**CameraManager（LiveCameraManager）:**
- AVCaptureSession完全制御
- 非同期権限チェック・リクエスト
- カメラ切り替え機能（前面/背面）
- エラーハンドリング・ログ出力
- @MainActor対応

**CameraFeature（TCA）:**
- State: 権限状態、セッション、エラー、カメラ位置
- Action: 権限/セッション/エラー/ライフサイクル制御
- Reducer: 完全な状態遷移・副作用処理

**CameraView:**
- カメラプレビュー表示（AVCaptureVideoPreviewLayer）
- 権限アラート・エラーアラート
- カメラ切り替えボタン
- アプリライフサイクル対応

**テスト:**
- 15のテストケース（権限、セッション、エラー、ライフサイクル）
- TCAのTestStore使用
- モック依存関係

### 次のアクション
- 実機での動作確認（権限ダイアログ、プレビュー表示）✅ 完了
- 必要に応じてContentViewでCameraViewを統合 ✅ 完了

### 2025-05-28 14:30 - 実機動作確認完了
- ✅ カメラ権限ダイアログ：正常に表示・許可できた
- ✅ カメラプレビュー：リアルタイム映像が表示された
- ✅ カメラ切り替え：フロント/リア両方動作確認
- ✅ UIボタン：右下の切り替えボタンが正常動作
- ✅ CameraPreviewViewの修正により黒画面問題を解決

### 残りの確認項目
- バックグラウンド/フォアグラウンド切り替え時の動作 ✅ 完了

### 2025-05-28 14:35 - タスク完了！
**全ての実装と動作確認が完了しました！**

実機確認結果：
- ✅ カメラ権限ダイアログ：正常動作
- ✅ カメラプレビュー：リアルタイム表示
- ✅ カメラ切り替え：フロント/リア両方OK
- ✅ バックグラウンド/フォアグラウンド：自動停止・再開OK
- ✅ デバッグ情報：開発中は残すことに決定

実装の成果：
- AVFoundationベースの完全なカメラ制御
- TCAによる状態管理とエラーハンドリング
- 15個の単体テスト（全て成功）
- ユーザー体験を考慮したライフサイクル管理

## ユーザーへの指示（実機確認手順）

### 1. ContentViewでCameraViewを表示する準備
まず、アプリでカメラ画面を表示できるようにContentViewを修正します。

**ファイル**: `/Users/fumiyasagawa/Development/fumiya/HandEst/HandEst/ContentView.swift`

以下のコードに更新してください：
```swift
import SwiftUI
import ComposableArchitecture

struct ContentView: View {
    @Bindable var store: StoreOf<AppFeature>
    
    var body: some View {
        // CameraViewを直接表示（テスト用）
        CameraView(
            store: store.scope(
                state: \.camera,
                action: \.camera
            )
        )
    }
}
```

### 2. Xcodeでプロジェクトを開く
```bash
cd /Users/fumiyasagawa/Development/fumiya/HandEst
open HandEst.xcodeproj
```

### 3. 実機をMacに接続
1. iPhoneまたはiPadをLightningケーブル/USB-Cケーブルで接続
2. デバイスで「このコンピュータを信頼しますか？」と表示されたら「信頼」をタップ

### 4. Xcodeで実機を選択
1. Xcodeの上部ツールバーで、シミュレータ名が表示されている部分をクリック
2. 「iOS Devices」セクションから、接続したデバイス名を選択
3. もし表示されない場合は、Xcode → Settings → Accounts で開発者アカウントが設定されているか確認

### 5. ビルド＆実行
1. Xcodeで「▶️」ボタン（Run）をクリック、またはCmd+Rを押す
2. 初回は少し時間がかかります（1-3分程度）
3. エラーが出た場合：
   - 「Signing & Capabilities」タブで「Automatically manage signing」にチェック
   - Teamに自分のApple IDを選択

### 6. 実機での確認項目

#### ✅ カメラ権限ダイアログ
1. アプリが起動したら、カメラ権限のダイアログが表示されるか確認
2. ダイアログの文言：「HandEstはユーザーの手をリアルタイムで3Dモデルに変換するためにカメラを使用します。カメラ映像は端末内でのみ処理され、外部に送信されることはありません。」
3. 「OK」をタップして権限を許可

#### ✅ カメラプレビュー表示
1. 権限許可後、カメラのプレビューが画面に表示されるか確認
2. 映像がリアルタイムで更新されているか確認
3. 画面が黒い場合は、カメラレンズが覆われていないか確認

#### ✅ カメラ切り替えボタン
1. 画面右下に回転アイコンのボタンが表示されているか確認
2. ボタンをタップして、前面/背面カメラが切り替わるか確認
3. 切り替え時に映像が正常に表示されるか確認

#### ✅ アプリのバックグラウンド/フォアグラウンド
1. ホームボタン/ホームインジケータをスワイプしてホーム画面に戻る
2. アプリアイコンをタップして戻る
3. カメラが自動的に再開されるか確認

#### ✅ 権限拒否時の動作（オプション）
1. 設定アプリ → HandEst → カメラをオフ
2. アプリを再起動
3. 「設定を開く」ボタンが表示されるか確認

### 7. 問題が発生した場合
- Xcodeのコンソール（下部）にエラーメッセージが表示されていないか確認
- 赤いエラーが表示されている場合は、その内容を報告してください
- スクリーンショットを撮って共有していただけると助かります

### 8. 確認完了後
すべての項目が正常に動作したら、このタスクは完了です！
問題があった場合は、具体的な症状を教えてください。