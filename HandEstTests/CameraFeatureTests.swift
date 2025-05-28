import XCTest
import ComposableArchitecture
@testable import HandEst

@MainActor
final class CameraFeatureTests: XCTestCase {
    
    /// 動作: カメラ権限許可アクションをテスト
    /// 期待結果: isAuthorizedがtrueに更新される
    func testPermissionGranted() async {
        let store = TestStore(
            initialState: CameraFeature.State(),
            reducer: { CameraFeature() }
        )
        
        await store.send(.permissionGranted(true)) {
            $0.isAuthorized = true
        }
    }
    
    /// 動作: カメラ開始アクションをテスト
    /// 期待結果: isCameraActiveがtrueに更新される
    func testStartCamera() async {
        let store = TestStore(
            initialState: CameraFeature.State(),
            reducer: { CameraFeature() }
        )
        
        await store.send(.startCamera) {
            $0.isCameraActive = true
        }
    }
    
    /// 動作: カメラ停止アクションをテスト
    /// 期待結果: isCameraActiveがfalseに更新される
    func testStopCamera() async {
        let store = TestStore(
            initialState: CameraFeature.State(isCameraActive: true),
            reducer: { CameraFeature() }
        )
        
        await store.send(.stopCamera) {
            $0.isCameraActive = false
        }
    }
    
    /// 動作: エラー発生アクションをテスト
    /// 期待結果: エラーメッセージが設定される
    func testErrorOccurred() async {
        let store = TestStore(
            initialState: CameraFeature.State(),
            reducer: { CameraFeature() }
        )
        
        let errorMessage = "テストエラー"
        await store.send(.errorOccurred(errorMessage)) {
            $0.error = errorMessage
        }
    }
}