import XCTest
import ComposableArchitecture
@testable import HandEst

@MainActor
final class RenderingFeatureTests: XCTestCase {
    
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
}