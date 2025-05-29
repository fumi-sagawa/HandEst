import XCTest
import ComposableArchitecture
@testable import HandEst

@MainActor
final class RenderingFeatureTests: XCTestCase {
    
    /// 動作: RealityKit初期化アクションをテスト
    /// 期待結果: 初期化が成功し、isInitializedがtrueになる
    func testInitializeRealityKit() async {
        let store = TestStore(
            initialState: RenderingFeature.State(),
            reducer: { RenderingFeature() }
        ) {
            $0.renderingClient.initializeScene = { /* 成功をシミュレート */ }
        }
        
        await store.send(.initializeRealityKit)
        await store.receive(.realityKitInitialized) {
            $0.isInitialized = true
            $0.renderingError = nil
        }
    }
    
    /// 動作: RealityKit初期化失敗をテスト
    /// 期待結果: エラーが設定され、isInitializedがfalseのまま
    func testInitializeRealityKitFailure() async {
        let expectedError = RenderingError.initializationFailed("テストエラー")
        let store = TestStore(
            initialState: RenderingFeature.State(),
            reducer: { RenderingFeature() }
        ) {
            $0.renderingClient.initializeScene = { throw expectedError }
        }
        
        await store.send(.initializeRealityKit)
        await store.receive(.initializationFailed(expectedError)) {
            $0.isInitialized = false
            $0.renderingError = expectedError
        }
    }
    
    /// 動作: レンダリング開始アクションをテスト
    /// 期待結果: isRenderingがtrueに更新される
    func testStartRendering() async {
        let store = TestStore(
            initialState: RenderingFeature.State(),
            reducer: { RenderingFeature() }
        )
        
        await store.send(.startRendering) {
            $0.isRendering = true
        }
    }
    
    /// 動作: レンダリング停止アクションをテスト
    /// 期待結果: isRenderingがfalseに更新される
    func testStopRendering() async {
        let store = TestStore(
            initialState: RenderingFeature.State(isRendering: true),
            reducer: { RenderingFeature() }
        )
        
        await store.send(.stopRendering) {
            $0.isRendering = false
        }
    }
    
    /// 動作: 焦点距離設定アクションをテスト
    /// 期待結果: focalLengthが指定された値に更新される
    func testSetFocalLength() async {
        let store = TestStore(
            initialState: RenderingFeature.State(),
            reducer: { RenderingFeature() }
        )
        
        await store.send(.setFocalLength(.wide24mm)) {
            $0.focalLength = .wide24mm
        }
    }
    
    /// 動作: 回転更新アクションをテスト
    /// 期待結果: rotationが指定された値に更新される
    func testUpdateRotation() async {
        let store = TestStore(
            initialState: RenderingFeature.State(),
            reducer: { RenderingFeature() }
        )
        
        await store.send(.updateRotation(45.0)) {
            $0.rotation = 45.0
        }
    }
    
    /// 動作: スケール更新アクションをテスト
    /// 期待結果: scaleが指定された値に更新される
    func testUpdateScale() async {
        let store = TestStore(
            initialState: RenderingFeature.State(),
            reducer: { RenderingFeature() }
        )
        
        await store.send(.updateScale(1.5)) {
            $0.scale = 1.5
        }
    }
    
    /// 動作: エラー発生アクションをテスト
    /// 期待結果: エラーメッセージが設定される
    func testErrorOccurred() async {
        let store = TestStore(
            initialState: RenderingFeature.State(),
            reducer: { RenderingFeature() }
        )
        
        let errorMessage = "レンダリングエラー"
        await store.send(.errorOccurred(errorMessage)) {
            $0.error = errorMessage
        }
    }
    
    /// 動作: 手のランドマーク更新アクションをテスト
    /// 期待結果: currentHandLandmarksが更新される
    func testUpdateHandLandmarks() async {
        let landmarks = [
            HandLandmark(x: 0.5, y: 0.5, z: 0.0, confidence: 1.0, type: .wrist),
            HandLandmark(x: 0.6, y: 0.6, z: 0.1, confidence: 0.9, type: .thumbTip)
        ]
        
        let store = TestStore(
            initialState: RenderingFeature.State(),
            reducer: { RenderingFeature() }
        )
        
        await store.send(.updateHandLandmarks(landmarks)) {
            $0.currentHandLandmarks = landmarks
        }
    }
    
    /// 動作: モデルタイプ設定アクションをテスト
    /// 期待結果: modelTypeが指定された値に更新される
    func testSetModelType() async {
        let store = TestStore(
            initialState: RenderingFeature.State(),
            reducer: { RenderingFeature() }
        )
        
        await store.send(.setModelType(.mesh)) {
            $0.modelType = .mesh
        }
    }
    
    /// 動作: レンダリングエラー発生アクションをテスト
    /// 期待結果: renderingErrorとerrorが設定される
    func testRenderingErrorOccurred() async {
        let renderingError = RenderingError.modelCreationFailed
        let store = TestStore(
            initialState: RenderingFeature.State(),
            reducer: { RenderingFeature() }
        )
        
        await store.send(.renderingErrorOccurred(renderingError)) {
            $0.renderingError = renderingError
            $0.error = renderingError.localizedDescription
        }
    }
    
    /// 動作: エラークリアアクションをテスト
    /// 期待結果: errorとrenderingErrorがnilに設定される
    func testClearError() async {
        let store = TestStore(
            initialState: RenderingFeature.State(
                renderingError: .memoryWarning,
                error: "メモリ不足"
            ),
            reducer: { RenderingFeature() }
        )
        
        await store.send(.clearError) {
            $0.error = nil
            $0.renderingError = nil
        }
    }
}