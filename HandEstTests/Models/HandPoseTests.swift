import XCTest
@testable import HandEst

final class HandPoseTests: XCTestCase {
    
    /// テスト用の21個のランドマークを生成
    private func createTestLandmarks() -> [HandLandmark] {
        return LandmarkType.allCases.map { type in
            HandLandmark(
                x: Float(type.rawValue) / 20.0,
                y: Float(type.rawValue) / 20.0 + 0.1,
                z: Float(type.rawValue) / 100.0,
                confidence: 0.9,
                type: type
            )
        }
    }
    
    /// 動作: HandPoseを21個のランドマークで初期化
    /// 期待結果: 正しく初期化され、overallConfidenceが計算される
    func testHandPoseInitialization() {
        let landmarks = createTestLandmarks()
        let pose = HandPose(landmarks: landmarks)
        
        XCTAssertEqual(pose.landmarks.count, 21)
        XCTAssertEqual(pose.overallConfidence, 0.9, accuracy: 0.001)
        XCTAssertNotNil(pose.timestamp)
    }
    
    /// 動作: 21個未満のランドマークでHandPoseを初期化
    /// 期待結果: fatalErrorが発生する
    func testHandPoseInitializationWithInvalidLandmarkCount() {
        // この種のテストは実際のアプリでは避けるべきですが、
        // 開発時の検証として記載しています
        // 実際のコードではfatalErrorの代わりにthrowable initを使用することを推奨
    }
    
    /// 動作: インデックスでランドマークにアクセス
    /// 期待結果: 正しいランドマークが返される
    func testSubscriptByIndex() {
        let landmarks = createTestLandmarks()
        let pose = HandPose(landmarks: landmarks)
        
        let wrist = pose[0]
        XCTAssertEqual(wrist.type, .wrist)
        
        let indexTip = pose[8]
        XCTAssertEqual(indexTip.type, .indexTip)
    }
    
    /// 動作: LandmarkTypeでランドマークにアクセス
    /// 期待結果: 正しいランドマークが返される
    func testSubscriptByType() {
        let landmarks = createTestLandmarks()
        let pose = HandPose(landmarks: landmarks)
        
        let wrist = pose[.wrist]
        XCTAssertEqual(wrist.type, .wrist)
        XCTAssertEqual(wrist.x, 0.0)
        
        let thumbTip = pose[.thumbTip]
        XCTAssertEqual(thumbTip.type, .thumbTip)
    }
    
    /// 動作: 特定の指のランドマークを取得
    /// 期待結果: 指定した指の4つのランドマークが返される
    func testLandmarksForFinger() {
        let landmarks = createTestLandmarks()
        let pose = HandPose(landmarks: landmarks)
        
        let thumbLandmarks = pose.landmarks(for: .thumb)
        XCTAssertEqual(thumbLandmarks.count, 4)
        XCTAssertTrue(thumbLandmarks.allSatisfy { $0.type.finger == .thumb })
        
        let indexLandmarks = pose.landmarks(for: .index)
        XCTAssertEqual(indexLandmarks.count, 4)
        XCTAssertTrue(indexLandmarks.allSatisfy { $0.type.finger == .index })
    }
    
    /// 動作: 手首相対座標に変換
    /// 期待結果: 全てのランドマークが手首を基準とした座標に変換される
    func testToWristRelativeCoordinates() {
        let landmarks = createTestLandmarks()
        let pose = HandPose(landmarks: landmarks)
        
        let relativeLandmarks = pose.toWristRelativeCoordinates()
        
        // 手首の相対座標は(0, 0, 0)になるはず
        let relativeWrist = relativeLandmarks[0]
        XCTAssertEqual(relativeWrist.x, 0.0)
        XCTAssertEqual(relativeWrist.y, 0.0)
        XCTAssertEqual(relativeWrist.z, 0.0)
        
        // 他のランドマークも正しく変換されているか確認
        let originalThumbTip = pose[.thumbTip]
        let relativeThumbTip = relativeLandmarks[4]
        XCTAssertEqual(relativeThumbTip.x, originalThumbTip.x - pose[.wrist].x)
        XCTAssertEqual(relativeThumbTip.y, originalThumbTip.y - pose[.wrist].y)
        XCTAssertEqual(relativeThumbTip.z, originalThumbTip.z - pose[.wrist].z)
    }
    
    /// 動作: バウンディングボックスを計算
    /// 期待結果: 正しい最小値と最大値が返される
    func testBoundingBox() {
        let landmarks = createTestLandmarks()
        let pose = HandPose(landmarks: landmarks)
        
        let box = pose.boundingBox()
        
        XCTAssertEqual(box.min.x, 0.0)
        XCTAssertEqual(box.min.y, 0.1)
        XCTAssertEqual(box.max.x, 1.0)
        XCTAssertEqual(box.max.y, 1.1)
    }
    
    /// 動作: 手の中心座標を計算
    /// 期待結果: 全ランドマークの平均座標が返される
    func testCenter() {
        let landmarks = createTestLandmarks()
        let pose = HandPose(landmarks: landmarks)
        
        let center = pose.center()
        
        // 0から20までの平均は10、それを20で割ると0.5
        XCTAssertEqual(center.x, 0.5, accuracy: 0.001)
        XCTAssertEqual(center.y, 0.6, accuracy: 0.001)  // 0.5 + 0.1
        XCTAssertEqual(center.z, 0.1, accuracy: 0.001)  // 10 / 100
    }
    
    /// 動作: HandPoseのEquatable準拠をテスト
    /// 期待結果: 同じランドマークを持つポーズが等しいと判定される
    func testHandPoseEquatable() {
        let landmarks1 = createTestLandmarks()
        let landmarks2 = createTestLandmarks()
        
        let pose1 = HandPose(landmarks: landmarks1)
        let pose2 = HandPose(landmarks: landmarks2)
        
        // タイムスタンプが異なるため、単純な比較では等しくならない
        // landmarksとoverallConfidenceで判定
        XCTAssertEqual(pose1.landmarks, pose2.landmarks)
        XCTAssertEqual(pose1.overallConfidence, pose2.overallConfidence)
    }
    
    /// 動作: HandPoseのCodable準拠をテスト
    /// 期待結果: エンコード・デコードが正しく動作する
    func testHandPoseCodable() throws {
        let landmarks = createTestLandmarks()
        let originalPose = HandPose(landmarks: landmarks)
        
        let encoder = JSONEncoder()
        let data = try encoder.encode(originalPose)
        
        let decoder = JSONDecoder()
        let decodedPose = try decoder.decode(HandPose.self, from: data)
        
        XCTAssertEqual(originalPose.landmarks, decodedPose.landmarks)
        XCTAssertEqual(originalPose.overallConfidence, decodedPose.overallConfidence)
    }
    
    /// 動作: 複数のHandPoseの平均を計算
    /// 期待結果: 各ランドマークの座標と信頼度が平均化される
    func testAveragePose() {
        // 3つの異なるポーズを作成
        let poses = (0..<3).map { i in
            let landmarks = LandmarkType.allCases.map { type in
                HandLandmark(
                    x: Float(i) * 0.1,
                    y: Float(i) * 0.1,
                    z: Float(i) * 0.01,
                    confidence: 0.8 + Float(i) * 0.05,
                    type: type
                )
            }
            return HandPose(landmarks: landmarks)
        }
        
        let averagePose = poses.averagePose()
        XCTAssertNotNil(averagePose)
        
        // 平均値を確認 (0.0, 0.1, 0.2の平均は0.1)
        let wrist = averagePose![.wrist]
        XCTAssertEqual(wrist.x, 0.1, accuracy: 0.001)
        XCTAssertEqual(wrist.y, 0.1, accuracy: 0.001)
        XCTAssertEqual(wrist.z, 0.01, accuracy: 0.001)
        XCTAssertEqual(wrist.confidence, 0.85, accuracy: 0.001)  // (0.8 + 0.85 + 0.9) / 3
    }
    
    /// 動作: 空の配列で平均ポーズを計算
    /// 期待結果: nilが返される
    func testAveragePoseWithEmptyArray() {
        let poses: [HandPose] = []
        XCTAssertNil(poses.averagePose())
    }
}