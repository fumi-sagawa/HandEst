import AVFoundation
import XCTest
import ComposableArchitecture
@testable import HandEst

@MainActor
final class AppFeatureTests: XCTestCase {
    
    /// 動作: アプリ起動時にonAppearアクションを送信
    /// 期待結果: ログが出力され、子Featureの初期化アクションが送信される
    func testOnAppearLogsStartup() async {
        let store = TestStore(
            initialState: AppFeature.State(),
            reducer: { AppFeature() }
        ) {
            $0.cameraManager.checkAuthorizationStatus = { .notDetermined }
        }
        
        // 非網羅的なテストストアを使用（CameraFeatureの詳細なアクションは無視）
        store.exhaustivity = .off
        
        await store.send(.onAppear)
        await store.receive(\.camera.onAppear)
        await store.receive(\.settings.loadSettings)
        await store.receive(\.settings.settingsLoaded)
    }
    
    /// 動作: ローディング状態をtrue/falseで切り替え
    /// 期待結果: state.isLoadingが送信した値に更新される
    func testSetLoadingUpdatesState() async {
        let store = TestStore(
            initialState: AppFeature.State(),
            reducer: { AppFeature() }
        )
        
        await store.send(.setLoading(true)) {
            $0.isLoading = true
        }
        
        await store.send(.setLoading(false)) {
            $0.isLoading = false
        }
    }
    
    /// 動作: AppErrorオブジェクトでエラー表示アクションを送信
    /// 期待結果: エラー状態がtrue、メッセージとエラーオブジェクトが設定、ローディングがfalse
    func testShowErrorUpdatesState() async {
        let store = TestStore(
            initialState: AppFeature.State(),
            reducer: { AppFeature() }
        )
        
        let testError = AppError.camera(.permissionDenied)
        
        await store.send(.showError(testError)) {
            $0.hasError = true
            $0.errorMessage = testError.userMessage
            $0.currentError = testError
            $0.isLoading = false
        }
    }
    
    /// 動作: 文字列でエラーメッセージ表示アクションを送信
    /// 期待結果: エラー状態がtrue、メッセージが設定、エラーオブジェクトはnil、ローディングがfalse
    func testShowErrorMessageUpdatesState() async {
        let store = TestStore(
            initialState: AppFeature.State(),
            reducer: { AppFeature() }
        )
        
        let testMessage = "テストエラーメッセージ"
        
        await store.send(.showErrorMessage(testMessage)) {
            $0.hasError = true
            $0.errorMessage = testMessage
            $0.currentError = nil
            $0.isLoading = false
        }
    }
    
    /// 動作: エラー状態でdismissErrorアクションを送信
    /// 期待結果: エラー関連の状態が全てクリア（hasError=false, errorMessage=nil, currentError=nil）
    func testDismissErrorClearsState() async {
        let store = TestStore(
            initialState: AppFeature.State(
                hasError: true,
                errorMessage: "テストエラー",
                currentError: AppError.unknown("テスト")
            ),
            reducer: { AppFeature() }
        )
        
        await store.send(.dismissError) {
            $0.hasError = false
            $0.errorMessage = nil
            $0.currentError = nil
        }
    }
    
    /// 動作: 各種AppErrorタイプのuserMessageプロパティを検証
    /// 期待結果: 各エラータイプが適切な日本語メッセージを返す
    func testErrorMessagesForAllErrorTypes() {
        // カメラエラー
        let cameraError = AppError.camera(.permissionDenied)
        XCTAssertEqual(
            cameraError.userMessage, 
            "カメラの使用を許可してください。設定アプリからHandEstのカメラ権限を有効にしてください。"
        )
        
        // 手トラッキングエラー
        let handTrackingError = AppError.handTracking(.noHandsDetected)
        XCTAssertEqual(handTrackingError.userMessage, "手が検出されませんでした。カメラに手をかざしてください。")
        
        // レンダリングエラー
        let renderingError = AppError.rendering(.sceneSetupFailed)
        XCTAssertEqual(
            renderingError.userMessage, 
            "3Dレンダリングの初期化に失敗しました。アプリを再起動してお試しください。"
        )
        
        // 権限エラー
        let permissionError = AppError.permission(.cameraNotAuthorized)
        XCTAssertEqual(
            permissionError.userMessage, 
            "カメラの使用を許可してください。設定アプリからHandEstのカメラ権限を有効にしてください。"
        )
        
        // 未知のエラー
        let unknownError = AppError.unknown("テストエラー")
        XCTAssertEqual(
            unknownError.userMessage, 
            "予期しないエラーが発生しました。アプリを再起動してお試しください。"
        )
    }
    
    /// 動作: カメラFeatureのアクションがAppFeatureで正しく処理されるかテスト
    /// 期待結果: カメラFeatureの状態が適切に更新される
    func testCameraFeatureIntegration() async {
        let mockSession = AVCaptureSession()
        let store = TestStore(
            initialState: AppFeature.State(),
            reducer: { AppFeature() }
        ) {
            $0.cameraManager.requestPermission = { true }
            $0.cameraManager.startSession = { }
            $0.cameraManager.getCaptureSession = { mockSession }
        }
        
        // 非網羅的なテストストアを使用
        store.exhaustivity = .off
        
        await store.send(.camera(.requestPermission))
        
        await store.send(.camera(.permissionReceived(true))) {
            $0.camera.authorizationStatus = .authorized
        }
        
        await store.send(.camera(.startCamera))
    }
    
    /// 動作: 設定Featureのアクションがスコープされて処理されるかテスト
    /// 期待結果: 設定の変更が正しく反映され、保存アクションが発行される
    func testSettingsFeatureIntegration() async {
        let store = TestStore(
            initialState: AppFeature.State(),
            reducer: { AppFeature() }
        )
        
        await store.send(.settings(.setHapticFeedback(false))) {
            $0.settings.hapticFeedbackEnabled = false
        }
        await store.receive(\.settings.saveSettings)
        await store.receive(\.settings.settingsSaved)
        
        await store.send(.settings(.setDefaultHandedness(.left))) {
            $0.settings.defaultHandedness = .left
        }
        await store.receive(\.settings.saveSettings)
        await store.receive(\.settings.settingsSaved)
    }
    
    /// 動作: HandTrackingFeatureの基本アクションテスト
    /// 期待結果: 手認識の開始・停止が正しく動作する
    func testHandTrackingFeatureIntegration() async {
        let store = TestStore(
            initialState: AppFeature.State(),
            reducer: { AppFeature() }
        )
        
        await store.send(.handTracking(.startTracking)) {
            $0.handTracking.isTracking = true
        }
        
        await store.send(.handTracking(.setHandedness(.left))) {
            $0.handTracking.handedness = .left
        }
        
        await store.send(.handTracking(.togglePoseLock)) {
            $0.handTracking.isPoseLocked = true
        }
        
        await store.send(.handTracking(.stopTracking)) {
            $0.handTracking.isTracking = false
        }
    }
    
    /// 動作: RenderingFeatureの設定変更テスト
    /// 期待結果: レンダリング設定が正しく更新される
    func testRenderingFeatureIntegration() async {
        let store = TestStore(
            initialState: AppFeature.State(),
            reducer: { AppFeature() }
        )
        
        await store.send(.rendering(.setFocalLength(.wide24mm))) {
            $0.rendering.focalLength = .wide24mm
        }
        
        await store.send(.rendering(.updateScale(1.5))) {
            $0.rendering.scale = 1.5
        }
        
        await store.send(.rendering(.startRendering)) {
            $0.rendering.isRendering = true
        }
    }
}