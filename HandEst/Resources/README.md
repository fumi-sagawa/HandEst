# Resources

このディレクトリには、アプリケーションで使用するリソースファイルを配置します。

## MediaPipe Hand Landmarkerモデル

### モデルファイルの取得方法

1. [MediaPipe Models](https://developers.google.com/mediapipe/solutions/vision/hand_landmarker/index#models)から`hand_landmarker.task`をダウンロード
2. ダウンロードしたファイルをこのResourcesディレクトリに配置
3. Xcodeプロジェクトに追加（Copy items if neededをチェック）

### 必要なファイル

- `hand_landmarker.task` - MediaPipe Hand Landmarkerモデルファイル

### 注意事項

- モデルファイルはGitには含まれていません（サイズが大きいため）
- 初回セットアップ時に手動でダウンロードして配置する必要があります
- モデルファイルのライセンス: Apache License 2.0