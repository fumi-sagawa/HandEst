import XCTest
import ComposableArchitecture
@testable import HandEst

@MainActor
final class HandTrackingFeatureTests: XCTestCase {
    
    /// 動作: 手認識開始アクションをテスト
    /// 期待結果: isTrackingがtrueに更新される
    func testStartTracking() async {
        let store = TestStore(
            initialState: HandTrackingFeature.State(),
            reducer: { HandTrackingFeature() }
        )
        
        await store.send(.startTracking) {
            $0.isTracking = true
        }
    }
    
    /// 動作: 手認識停止アクションをテスト
    /// 期待結果: isTrackingがfalseに更新される
    func testStopTracking() async {
        let store = TestStore(
            initialState: HandTrackingFeature.State(isTracking: true),
            reducer: { HandTrackingFeature() }
        )
        
        await store.send(.stopTracking) {
            $0.isTracking = false
        }
    }
    
    /// 動作: ポーズロック切り替えアクションをテスト
    /// 期待結果: isPoseLockedが反転される
    func testTogglePoseLock() async {
        let store = TestStore(
            initialState: HandTrackingFeature.State(),
            reducer: { HandTrackingFeature() }
        )
        
        await store.send(.togglePoseLock) {
            $0.isPoseLocked = true
        }
        
        await store.send(.togglePoseLock) {
            $0.isPoseLocked = false
        }
    }
    
    /// 動作: 手の左右設定アクションをテスト
    /// 期待結果: handednessが指定された値に更新される
    func testSetHandedness() async {
        let store = TestStore(
            initialState: HandTrackingFeature.State(),
            reducer: { HandTrackingFeature() }
        )
        
        await store.send(.setHandedness(.left)) {
            $0.handedness = .left
        }
    }
    
    /// 動作: エラー発生アクションをテスト
    /// 期待結果: エラーメッセージが設定される
    func testErrorOccurred() async {
        let store = TestStore(
            initialState: HandTrackingFeature.State(),
            reducer: { HandTrackingFeature() }
        )
        
        let errorMessage = "手認識エラー"
        await store.send(.errorOccurred(errorMessage)) {
            $0.error = errorMessage
        }
    }
}