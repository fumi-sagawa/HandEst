import XCTest
import ComposableArchitecture
@testable import HandEst

@MainActor
final class AppFeatureTests: XCTestCase {
    
    func testOnAppearLogsStartup() async {
        let store = TestStore(
            initialState: AppFeature.State(),
            reducer: { AppFeature() }
        )
        
        await store.send(.onAppear)
    }
    
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
}