import XCTest
@testable import HandEst

final class HandLandmarkTests: XCTestCase {
    
    /// 動作: HandLandmarkを初期化
    /// 期待結果: 全てのプロパティが正しく設定される
    func testHandLandmarkInitialization() {
        let landmark = HandLandmark(x: 0.5, y: 0.3, z: 0.1, confidence: 0.9, type: .indexTip)
        
        XCTAssertEqual(landmark.x, 0.5)
        XCTAssertEqual(landmark.y, 0.3)
        XCTAssertEqual(landmark.z, 0.1)
        XCTAssertEqual(landmark.confidence, 0.9)
        XCTAssertEqual(landmark.type, .indexTip)
    }
    
    /// 動作: toScreenCoordinatesメソッドを呼び出し
    /// 期待結果: 正規化座標が画面座標に正しく変換される
    func testToScreenCoordinates() {
        let landmark = HandLandmark(x: 0.5, y: 0.3, z: 0.1, confidence: 1.0, type: .wrist)
        let screenPoint = landmark.toScreenCoordinates(width: 1920, height: 1080)
        
        XCTAssertEqual(screenPoint.x, 960, accuracy: 0.1)  // 0.5 * 1920
        XCTAssertEqual(screenPoint.y, 324, accuracy: 0.1)  // 0.3 * 1080
    }
    
    /// 動作: isConfidentメソッドをデフォルト閾値で呼び出し
    /// 期待結果: 信頼度が0.5以上の場合trueを返す
    func testIsConfidentWithDefaultThreshold() {
        let highConfidenceLandmark = HandLandmark(x: 0, y: 0, z: 0, confidence: 0.8, type: .wrist)
        let lowConfidenceLandmark = HandLandmark(x: 0, y: 0, z: 0, confidence: 0.3, type: .wrist)
        
        XCTAssertTrue(highConfidenceLandmark.isConfident())
        XCTAssertFalse(lowConfidenceLandmark.isConfident())
    }
    
    /// 動作: isConfidentメソッドをカスタム閾値で呼び出し
    /// 期待結果: 信頼度が指定閾値以上の場合trueを返す
    func testIsConfidentWithCustomThreshold() {
        let landmark = HandLandmark(x: 0, y: 0, z: 0, confidence: 0.7, type: .wrist)
        
        XCTAssertTrue(landmark.isConfident(threshold: 0.6))
        XCTAssertFalse(landmark.isConfident(threshold: 0.8))
    }
    
    /// 動作: LandmarkTypeの全ケースをテスト
    /// 期待結果: 各タイプが正しいrawValueと日本語名を持つ
    func testLandmarkTypes() {
        XCTAssertEqual(LandmarkType.wrist.rawValue, 0)
        XCTAssertEqual(LandmarkType.thumbTip.rawValue, 4)
        XCTAssertEqual(LandmarkType.indexTip.rawValue, 8)
        XCTAssertEqual(LandmarkType.middleTip.rawValue, 12)
        XCTAssertEqual(LandmarkType.ringTip.rawValue, 16)
        XCTAssertEqual(LandmarkType.pinkyTip.rawValue, 20)
        
        XCTAssertEqual(LandmarkType.wrist.japaneseName, "手首")
        XCTAssertEqual(LandmarkType.thumbTip.japaneseName, "親指先端")
        XCTAssertEqual(LandmarkType.indexMCP.japaneseName, "人差し指MP関節")
    }
    
    /// 動作: LandmarkTypeのfingerプロパティをテスト
    /// 期待結果: 各タイプが正しい指を返す
    func testLandmarkTypeFinger() {
        XCTAssertNil(LandmarkType.wrist.finger)
        XCTAssertEqual(LandmarkType.thumbTip.finger, .thumb)
        XCTAssertEqual(LandmarkType.indexPIP.finger, .index)
        XCTAssertEqual(LandmarkType.middleDIP.finger, .middle)
        XCTAssertEqual(LandmarkType.ringMCP.finger, .ring)
        XCTAssertEqual(LandmarkType.pinkyTip.finger, .pinky)
    }
    
    /// 動作: HandLandmarkのEquatable準拠をテスト
    /// 期待結果: 同じ値を持つインスタンスが等しいと判定される
    func testHandLandmarkEquatable() {
        let landmark1 = HandLandmark(x: 0.5, y: 0.3, z: 0.1, confidence: 0.9, type: .indexTip)
        let landmark2 = HandLandmark(x: 0.5, y: 0.3, z: 0.1, confidence: 0.9, type: .indexTip)
        let landmark3 = HandLandmark(x: 0.6, y: 0.3, z: 0.1, confidence: 0.9, type: .indexTip)
        
        XCTAssertEqual(landmark1, landmark2)
        XCTAssertNotEqual(landmark1, landmark3)
    }
    
    /// 動作: HandLandmarkのCodable準拠をテスト
    /// 期待結果: エンコード・デコードが正しく動作する
    func testHandLandmarkCodable() throws {
        let originalLandmark = HandLandmark(x: 0.5, y: 0.3, z: 0.1, confidence: 0.9, type: .indexTip)
        
        let encoder = JSONEncoder()
        let data = try encoder.encode(originalLandmark)
        
        let decoder = JSONDecoder()
        let decodedLandmark = try decoder.decode(HandLandmark.self, from: data)
        
        XCTAssertEqual(originalLandmark, decodedLandmark)
    }
    
    /// 動作: Fingerの全ケースをテスト
    /// 期待結果: 各指が正しい日本語名を持つ
    func testFingerEnumeration() {
        XCTAssertEqual(Finger.thumb.rawValue, "親指")
        XCTAssertEqual(Finger.index.rawValue, "人差し指")
        XCTAssertEqual(Finger.middle.rawValue, "中指")
        XCTAssertEqual(Finger.ring.rawValue, "薬指")
        XCTAssertEqual(Finger.pinky.rawValue, "小指")
        
        XCTAssertEqual(Finger.allCases.count, 5)
    }
}