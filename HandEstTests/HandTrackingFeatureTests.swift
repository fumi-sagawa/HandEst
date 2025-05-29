import XCTest
import ComposableArchitecture
import CoreVideo
@testable import HandEst

@MainActor
final class HandTrackingFeatureTests: XCTestCase {
    
    /// 動作: 手認識開始アクションをテスト
    /// 期待結果: MediaPipeが初期化されている場合、isTrackingがtrueに更新される
    func testStartTracking() async {
        let store = TestStore(
            initialState: HandTrackingFeature.State(isMediaPipeInitialized: true),
            reducer: { HandTrackingFeature() }
        )
        
        await store.send(.startTracking) {
            $0.isTracking = true
        }
    }
    
    /// 動作: MediaPipeが初期化されていない状態で手認識開始アクションをテスト
    /// 期待結果: エラーが設定され、isTrackingはfalseのまま
    func testStartTrackingWithoutInitialization() async {
        let store = TestStore(
            initialState: HandTrackingFeature.State(),
            reducer: { HandTrackingFeature() }
        )
        
        await store.send(.startTracking) {
            $0.error = .notInitialized
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
    /// 期待結果: エラーが設定される
    func testTrackingError() async {
        let store = TestStore(
            initialState: HandTrackingFeature.State(),
            reducer: { HandTrackingFeature() }
        )
        
        let error = MediaPipeError.processingFailed("手認識エラー")
        await store.send(.trackingError(error)) {
            $0.error = error
        }
    }
    
    // MARK: - MediaPipe Integration Tests
    
    /// 動作: onAppearアクションでMediaPipeを初期化
    /// 期待結果: MediaPipeが初期化され、isMediaPipeInitializedがtrueになる
    func testMediaPipeInitializationOnAppear() async {
        let store = TestStore(
            initialState: HandTrackingFeature.State(),
            reducer: { HandTrackingFeature() }
        ) {
            $0.mediaPipeClient.initialize = { }
            $0.mediaPipeClient.isInitialized = { true }
        }
        
        await store.send(.onAppear)
        await store.receive(.initializeMediaPipe)
        await store.receive(.mediaPipeInitialized(true)) {
            $0.isMediaPipeInitialized = true
        }
    }
    
    /// 動作: MediaPipe初期化失敗をテスト
    /// 期待結果: エラーが設定される
    func testMediaPipeInitializationFailure() async {
        let initError = MediaPipeError.initializationFailed("モデルファイルが見つかりません")
        let store = TestStore(
            initialState: HandTrackingFeature.State(),
            reducer: { HandTrackingFeature() }
        ) {
            $0.mediaPipeClient.initialize = { throw initError }
        }
        
        await store.send(.initializeMediaPipe)
        await store.receive(.trackingError(initError)) {
            $0.error = initError
        }
    }
    
    /// 動作: フレーム処理の成功をテスト
    /// 期待結果: トラッキング結果が状態に反映される
    func testProcessFrameSuccess() async {
        // テスト用のピクセルバッファを作成
        let pixelBuffer = createMockPixelBuffer()
        let mockResult = createMockHandTrackingResult()
        
        let store = TestStore(
            initialState: HandTrackingFeature.State(
                isTracking: true,
                isMediaPipeInitialized: true,
                isDebugMode: false  // デバッグモードをOFFにしてテスト
            ),
            reducer: { HandTrackingFeature() }
        ) {
            $0.mediaPipeClient.processFrame = { _ in mockResult }
        }
        
        await store.send(.processFrame(pixelBuffer))
        await store.receive(.trackingResult(mockResult)) {
            $0.currentResult = mockResult
            $0.trackingHistory.append(mockResult)
        }
        await store.receive(.updatePerformanceMetrics) {
            $0.performanceMetrics.currentFPS = mockResult.estimatedFPS
            $0.performanceMetrics.processingTimeMs = mockResult.processingTimeMs
            $0.performanceMetrics.totalFramesProcessed = 1
            $0.performanceMetrics.averageFPS = mockResult.estimatedFPS
            $0.performanceMetrics.detectionRate = 1.0
        }
        await store.finish()
    }
    
    /// 動作: フレーム処理の失敗をテスト
    /// 期待結果: エラーが設定される
    func testProcessFrameFailure() async {
        let pixelBuffer = createMockPixelBuffer()
        let processError = MediaPipeError.processingFailed("処理エラー")
        
        let store = TestStore(
            initialState: HandTrackingFeature.State(
                isTracking: true,
                isMediaPipeInitialized: true
            ),
            reducer: { HandTrackingFeature() }
        ) {
            $0.mediaPipeClient.processFrame = { _ in throw processError }
        }
        
        await store.send(.processFrame(pixelBuffer))
        await store.receive(.trackingError(processError)) {
            $0.error = processError
        }
    }
    
    /// 動作: トラッキング停止時はフレーム処理をスキップ
    /// 期待結果: フレーム処理が実行されない
    func testProcessFrameSkipWhenNotTracking() async {
        let pixelBuffer = createMockPixelBuffer()
        
        let store = TestStore(
            initialState: HandTrackingFeature.State(
                isTracking: false,
                isMediaPipeInitialized: true
            ),
            reducer: { HandTrackingFeature() }
        ) {
            $0.mediaPipeClient.processFrame = { _ in
                XCTFail("processFrame should not be called when not tracking")
                return nil
            }
        }
        
        await store.send(.processFrame(pixelBuffer))
    }
    
    /// 動作: ポーズロック時はフレーム処理をスキップ
    /// 期待結果: フレーム処理が実行されない
    func testProcessFrameSkipWhenPoseLocked() async {
        let pixelBuffer = createMockPixelBuffer()
        
        let store = TestStore(
            initialState: HandTrackingFeature.State(
                isTracking: true,
                isPoseLocked: true,
                isMediaPipeInitialized: true
            ),
            reducer: { HandTrackingFeature() }
        ) {
            $0.mediaPipeClient.processFrame = { _ in
                XCTFail("processFrame should not be called when pose is locked")
                return nil
            }
        }
        
        await store.send(.processFrame(pixelBuffer))
    }
    
    /// 動作: onDisappearでMediaPipeをシャットダウン
    /// 期待結果: トラッキングが停止し、MediaPipeがシャットダウンされる
    func testOnDisappearShutdown() async {
        var shutdownCalled = false
        
        let store = TestStore(
            initialState: HandTrackingFeature.State(
                isTracking: true,
                isMediaPipeInitialized: true
            ),
            reducer: { HandTrackingFeature() }
        ) {
            $0.mediaPipeClient.shutdown = {
                shutdownCalled = true
            }
        }
        
        await store.send(.onDisappear)
        await store.receive(.stopTracking) {
            $0.isTracking = false
        }
        
        // 少し待ってからシャットダウンが呼ばれたことを確認
        try? await Task.sleep(nanoseconds: 100_000_000) // 0.1秒
        XCTAssertTrue(shutdownCalled)
    }
    
    /// 動作: デバッグモードの切り替えをテスト
    /// 期待結果: isDebugModeが反転される
    func testToggleDebugMode() async {
        let store = TestStore(
            initialState: HandTrackingFeature.State(),  // デフォルトでisDebugMode = true
            reducer: { HandTrackingFeature() }
        )
        
        // 初期状態がtrue -> falseに切り替え
        await store.send(.toggleDebugMode) {
            $0.isDebugMode = false
            $0.debugInfo = nil
        }
        
        // false -> trueに切り替え
        await store.send(.toggleDebugMode) {
            $0.isDebugMode = true
            // デバッグモードON時は、currentResultがnilなのでdebugInfoもnil
            $0.debugInfo = nil
        }
        
        await store.finish()
    }
    
    /// 動作: エラークリアをテスト
    /// 期待結果: エラーがnilになる
    func testClearError() async {
        let store = TestStore(
            initialState: HandTrackingFeature.State(
                error: MediaPipeError.notInitialized
            ),
            reducer: { HandTrackingFeature() }
        )
        
        await store.send(.clearError) {
            $0.error = nil
        }
    }
    
    // MARK: - Additional Core Tests
    
    /// 動作: MediaPipe未初期化時のフレーム処理をテスト
    /// 期待結果: フレーム処理がスキップされる
    func testProcessFrameSkipWhenNotInitialized() async {
        let store = TestStore(
            initialState: HandTrackingFeature.State(
                isTracking: true,
                isMediaPipeInitialized: false  // 未初期化
            ),
            reducer: { HandTrackingFeature() }
        ) {
            $0.mediaPipeClient.processFrame = { _ in
                XCTFail("processFrame should not be called when not initialized")
                return nil
            }
        }
        
        let pixelBuffer = createMockPixelBuffer()
        await store.send(.processFrame(pixelBuffer))
        // アクションは受信されない（フレーム処理がスキップされる）
    }
    
    /// 動作: ライフサイクル管理のテスト
    /// 期待結果: onDisappear時に適切にクリーンアップされる
    func testLifecycleManagement() async {
        var shutdownCalled = false
        
        let store = TestStore(
            initialState: HandTrackingFeature.State(
                isTracking: true,
                isMediaPipeInitialized: true
            ),
            reducer: { HandTrackingFeature() }
        ) {
            $0.mediaPipeClient.shutdown = {
                shutdownCalled = true
            }
        }
        
        await store.send(.onDisappear)
        await store.receive(.stopTracking) {
            $0.isTracking = false
        }
        
        // 少し待ってからシャットダウンが呼ばれたことを確認
        try? await Task.sleep(nanoseconds: 100_000_000) // 0.1秒
        XCTAssertTrue(shutdownCalled)
    }
    
    /// 動作: 重要なエラーシナリオのテスト
    /// 期待結果: 重大なエラー時に適切に処理される
    func testCriticalErrorHandling() async {
        let criticalError = MediaPipeError.initializationFailed("重大なエラー")
        
        let store = TestStore(
            initialState: HandTrackingFeature.State(),
            reducer: { HandTrackingFeature() }
        ) {
            $0.mediaPipeClient.initialize = { throw criticalError }
        }
        
        await store.send(.initializeMediaPipe)
        await store.receive(.trackingError(criticalError)) {
            $0.error = criticalError
        }
        
        // 重大なエラー後は初期化されていないことを確認
        XCTAssertFalse(store.state.isMediaPipeInitialized)
        XCTAssertNotNil(store.state.error)
    }
    
    // MARK: - Helper Methods
    
    private func createMockHandTrackingResult(
        hasBothHands: Bool = true,
        processingTimeMs: Double = 16.7,
        estimatedFPS: Double? = nil,
        leftConfidence: Float = 0.9,
        rightConfidence: Float = 0.9
    ) -> HandTrackingResult {
        var poses: [HandPose] = []
        var handednessDataArray: [HandednessData] = []
        
        if hasBothHands {
            // 左手のデータ
            poses.append(createMockHandPose())
            handednessDataArray.append(HandednessData(handType: .left, confidence: leftConfidence))
            
            // 右手のデータ
            poses.append(createMockHandPose())
            handednessDataArray.append(HandednessData(handType: .right, confidence: rightConfidence))
        } else if leftConfidence > 0 || rightConfidence > 0 {
            // 片手のみ（右手）
            poses.append(createMockHandPose())
            handednessDataArray.append(HandednessData(handType: .right, confidence: rightConfidence))
        }
        
        return HandTrackingResult(
            poses: poses,
            handednessData: MultiHandednessData(hands: handednessDataArray),
            processingTimeMs: processingTimeMs,
            frameSize: CGSize(width: 640, height: 480)
        )
    }
    
    private func createMockHandPose() -> HandPose {
        var landmarks: [HandLandmark] = []
        for (index, landmarkType) in LandmarkType.allCases.enumerated() {
            landmarks.append(
                HandLandmark(
                    x: Float.random(in: 0...1),
                    y: Float.random(in: 0...1),
                    z: Float.random(in: -0.5...0.5),
                    confidence: 1.0,
                    type: landmarkType
                )
            )
        }
        return HandPose(landmarks: landmarks)
    }
    
    private func createMockPixelBuffer() -> CVPixelBuffer {
        var pixelBuffer: CVPixelBuffer?
        let attrs = [
            kCVPixelBufferCGImageCompatibilityKey: kCFBooleanTrue,
            kCVPixelBufferCGBitmapContextCompatibilityKey: kCFBooleanTrue
        ] as CFDictionary
        
        CVPixelBufferCreate(
            kCFAllocatorDefault,
            640,
            480,
            kCVPixelFormatType_32BGRA,
            attrs,
            &pixelBuffer
        )
        
        return pixelBuffer!
    }
}

