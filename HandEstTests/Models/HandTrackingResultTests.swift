import XCTest
@testable import HandEst

final class HandTrackingResultTests: XCTestCase {
    
    /// テスト用のHandPoseを生成
    private func createTestHandPose() -> HandPose {
        let landmarks = LandmarkType.allCases.map { type in
            HandLandmark(
                x: Float(type.rawValue) / 20.0,
                y: Float(type.rawValue) / 20.0 + 0.1,
                z: Float(type.rawValue) / 100.0,
                confidence: 0.9,
                type: type
            )
        }
        return HandPose(landmarks: landmarks)
    }
    
    /// 動作: HandTrackingResultを初期化
    /// 期待結果: 全てのプロパティが正しく設定される
    func testHandTrackingResultInitialization() {
        let pose1 = createTestHandPose()
        let pose2 = createTestHandPose()
        let handednessData = MultiHandednessData(hands: [
            HandednessData(handType: .left, confidence: 0.9),
            HandednessData(handType: .right, confidence: 0.85)
        ])
        
        let result = HandTrackingResult(
            poses: [pose1, pose2],
            handednessData: handednessData,
            processingTimeMs: 16.7,
            frameSize: CGSize(width: 1920, height: 1080)
        )
        
        XCTAssertEqual(result.poses.count, 2)
        XCTAssertEqual(result.processingTimeMs, 16.7)
        XCTAssertEqual(result.frameSize, CGSize(width: 1920, height: 1080))
        XCTAssertNotNil(result.timestamp)
    }
    
    /// 動作: 左手と右手のポーズを取得
    /// 期待結果: 正しい手のポーズが返される
    func testHandPoseAccess() {
        let leftPose = createTestHandPose()
        let rightPose = createTestHandPose()
        let handednessData = MultiHandednessData(hands: [
            HandednessData(handType: .left, confidence: 0.9),
            HandednessData(handType: .right, confidence: 0.85)
        ])
        
        let result = HandTrackingResult(
            poses: [leftPose, rightPose],
            handednessData: handednessData,
            processingTimeMs: 16.7,
            frameSize: CGSize(width: 1920, height: 1080)
        )
        
        XCTAssertNotNil(result.leftHandPose)
        XCTAssertNotNil(result.rightHandPose)
        XCTAssertEqual(result.detectedHandsCount, 2)
        XCTAssertTrue(result.hasBothHands)
    }
    
    /// 動作: 片手のみのトラッキング結果
    /// 期待結果: 検出された手のみポーズが返される
    func testSingleHandTracking() {
        let pose = createTestHandPose()
        let handednessData = MultiHandednessData(hands: [
            HandednessData(handType: .left, confidence: 0.9)
        ])
        
        let result = HandTrackingResult(
            poses: [pose],
            handednessData: handednessData,
            processingTimeMs: 16.7,
            frameSize: CGSize(width: 1920, height: 1080)
        )
        
        XCTAssertNotNil(result.leftHandPose)
        XCTAssertNil(result.rightHandPose)
        XCTAssertEqual(result.detectedHandsCount, 1)
        XCTAssertFalse(result.hasBothHands)
    }
    
    /// 動作: FPSを計算
    /// 期待結果: 処理時間から正しいFPSが計算される
    func testEstimatedFPS() {
        let result = HandTrackingResult(
            poses: [],
            handednessData: MultiHandednessData(hands: []),
            processingTimeMs: 16.7,  // 約60FPS
            frameSize: CGSize(width: 1920, height: 1080)
        )
        
        XCTAssertEqual(result.estimatedFPS, 59.88, accuracy: Double(0.1))
        
        // 処理時間が0の場合
        let zeroTimeResult = HandTrackingResult(
            poses: [],
            handednessData: MultiHandednessData(hands: []),
            processingTimeMs: 0,
            frameSize: CGSize(width: 1920, height: 1080)
        )
        
        XCTAssertEqual(zeroTimeResult.estimatedFPS, 0)
    }
    
    /// 動作: 最も信頼度の高いポーズを取得
    /// 期待結果: overallConfidenceが最も高いポーズが返される
    func testMostConfidentPose() {
        // 異なる信頼度のランドマークを持つポーズを作成
        let highConfidenceLandmarks = LandmarkType.allCases.map { type in
            HandLandmark(x: 0, y: 0, z: 0, confidence: 0.95, type: type)
        }
        let lowConfidenceLandmarks = LandmarkType.allCases.map { type in
            HandLandmark(x: 0, y: 0, z: 0, confidence: 0.6, type: type)
        }
        
        let highConfidencePose = HandPose(landmarks: highConfidenceLandmarks)
        let lowConfidencePose = HandPose(landmarks: lowConfidenceLandmarks)
        
        let result = HandTrackingResult(
            poses: [lowConfidencePose, highConfidencePose],
            handednessData: MultiHandednessData(hands: []),
            processingTimeMs: 16.7,
            frameSize: CGSize(width: 1920, height: 1080)
        )
        
        XCTAssertEqual(result.mostConfidentPose?.overallConfidence ?? 0, 0.95, accuracy: Float(0.001))
    }
    
    /// 動作: 特定の手のポーズとハンドネスデータをペアで取得
    /// 期待結果: 正しいペアが返される
    func testHandDataPair() {
        let leftPose = createTestHandPose()
        let rightPose = createTestHandPose()
        let handednessData = MultiHandednessData(hands: [
            HandednessData(handType: .left, confidence: 0.9),
            HandednessData(handType: .right, confidence: 0.85)
        ])
        
        let result = HandTrackingResult(
            poses: [leftPose, rightPose],
            handednessData: handednessData,
            processingTimeMs: 16.7,
            frameSize: CGSize(width: 1920, height: 1080)
        )
        
        let leftData = result.handData(for: .left)
        XCTAssertNotNil(leftData)
        XCTAssertEqual(leftData?.handednessData.confidence, 0.9)
        
        let rightData = result.handData(for: .right)
        XCTAssertNotNil(rightData)
        XCTAssertEqual(rightData?.handednessData.confidence, 0.85)
        
        let unknownData = result.handData(for: .unknown)
        XCTAssertNil(unknownData)
    }
    
    /// 動作: HandTrackingHistoryに結果を追加
    /// 期待結果: 履歴が正しく管理される
    func testHandTrackingHistoryAppend() {
        var history = HandTrackingHistory(maxFrames: 3)
        
        let result1 = HandTrackingResult(
            poses: [],
            handednessData: MultiHandednessData(hands: []),
            processingTimeMs: 16.0,
            frameSize: CGSize(width: 1920, height: 1080)
        )
        
        history.append(result1)
        XCTAssertEqual(history.results.count, 1)
        
        // 最大数まで追加
        history.append(result1)
        history.append(result1)
        XCTAssertEqual(history.results.count, 3)
        
        // 最大数を超えて追加（古いものが削除される）
        history.append(result1)
        XCTAssertEqual(history.results.count, 3)
    }
    
    /// 動作: HandTrackingHistoryの統計情報を計算
    /// 期待結果: 平均処理時間、平均FPS、検出率が正しく計算される
    func testHandTrackingHistoryStatistics() {
        var history = HandTrackingHistory(maxFrames: 10)
        
        // 異なる処理時間と検出数の結果を追加
        let result1 = HandTrackingResult(
            poses: [createTestHandPose()],
            handednessData: MultiHandednessData(hands: [HandednessData(handType: .left, confidence: 0.9)]),
            processingTimeMs: 16.0,
            frameSize: CGSize(width: 1920, height: 1080)
        )
        
        let result2 = HandTrackingResult(
            poses: [],
            handednessData: MultiHandednessData(hands: []),
            processingTimeMs: 20.0,
            frameSize: CGSize(width: 1920, height: 1080)
        )
        
        history.append(result1)
        history.append(result2)
        history.append(result1)
        
        // 平均処理時間: (16 + 20 + 16) / 3 = 17.33...
        XCTAssertEqual(history.averageProcessingTimeMs, 17.33, accuracy: Double(0.1))
        
        // 平均FPS: 1000 / 17.33... = 57.69...
        XCTAssertEqual(history.averageFPS, 57.69, accuracy: Double(0.1))
        
        // 検出率: 2/3 = 0.666...
        XCTAssertEqual(history.detectionRate, 0.666, accuracy: Double(0.01))
        
        // 最新の結果
        XCTAssertEqual(history.latest?.processingTimeMs, 16.0)
    }
    
    /// 動作: HandTrackingHistoryをクリア
    /// 期待結果: 履歴が空になる
    func testHandTrackingHistoryClear() {
        var history = HandTrackingHistory(maxFrames: 10)
        
        let result = HandTrackingResult(
            poses: [],
            handednessData: MultiHandednessData(hands: []),
            processingTimeMs: 16.0,
            frameSize: CGSize(width: 1920, height: 1080)
        )
        
        history.append(result)
        history.append(result)
        XCTAssertEqual(history.results.count, 2)
        
        history.clear()
        XCTAssertEqual(history.results.count, 0)
        XCTAssertNil(history.latest)
    }
    
    /// 動作: HandTrackingResultのCodable準拠をテスト
    /// 期待結果: エンコード・デコードが正しく動作する
    func testHandTrackingResultCodable() throws {
        let pose = createTestHandPose()
        let handednessData = MultiHandednessData(hands: [
            HandednessData(handType: .left, confidence: 0.9)
        ])
        
        let originalResult = HandTrackingResult(
            poses: [pose],
            handednessData: handednessData,
            processingTimeMs: 16.7,
            frameSize: CGSize(width: 1920, height: 1080)
        )
        
        let encoder = JSONEncoder()
        let data = try encoder.encode(originalResult)
        
        let decoder = JSONDecoder()
        let decodedResult = try decoder.decode(HandTrackingResult.self, from: data)
        
        XCTAssertEqual(originalResult.poses.count, decodedResult.poses.count)
        XCTAssertEqual(originalResult.processingTimeMs, decodedResult.processingTimeMs)
        XCTAssertEqual(originalResult.frameSize, decodedResult.frameSize)
    }
}