import XCTest
@testable import HandEst

final class LightingConditionTests: XCTestCase {
    
    /// 動作: 優秀な照明環境での評価
    /// 期待結果: ISO < 100, 露出時間 < 1/60の場合、excellentになる
    func testExcellentLightingCondition() {
        let exposureInfo = ExposureInfo(
            iso: 50,
            exposureDuration: 1.0/120.0, // 1/120秒
            exposureBias: 0
        )
        
        XCTAssertEqual(exposureInfo.lightingCondition, .excellent)
        XCTAssertTrue(exposureInfo.lightingCondition.isSuitableForHandTracking)
        XCTAssertFalse(exposureInfo.lightingCondition.shouldShowWarning)
        XCTAssertEqual(exposureInfo.lightingCondition.displayColor, "green")
        XCTAssertTrue(exposureInfo.lightingCondition.userMessage.isEmpty)
    }
    
    /// 動作: 良好な照明環境での評価
    /// 期待結果: ISO < 400, 露出時間 < 1/30の場合、goodになる
    func testGoodLightingCondition() {
        let exposureInfo = ExposureInfo(
            iso: 200,
            exposureDuration: 1.0/60.0, // 1/60秒
            exposureBias: 0
        )
        
        XCTAssertEqual(exposureInfo.lightingCondition, .good)
        XCTAssertTrue(exposureInfo.lightingCondition.isSuitableForHandTracking)
        XCTAssertFalse(exposureInfo.lightingCondition.shouldShowWarning)
        XCTAssertEqual(exposureInfo.lightingCondition.displayColor, "blue")
        XCTAssertTrue(exposureInfo.lightingCondition.userMessage.isEmpty)
    }
    
    /// 動作: 普通の照明環境での評価
    /// 期待結果: ISO < 800, 露出時間 < 1/15の場合、fairになる
    func testFairLightingCondition() {
        let exposureInfo = ExposureInfo(
            iso: 600,
            exposureDuration: 1.0/30.0, // 1/30秒
            exposureBias: 0
        )
        
        XCTAssertEqual(exposureInfo.lightingCondition, .fair)
        XCTAssertTrue(exposureInfo.lightingCondition.isSuitableForHandTracking)
        XCTAssertFalse(exposureInfo.lightingCondition.shouldShowWarning)
        XCTAssertEqual(exposureInfo.lightingCondition.displayColor, "yellow")
        XCTAssertEqual(exposureInfo.lightingCondition.userMessage, "照明が少し暗いですが、手の認識は可能です")
    }
    
    /// 動作: 暗い照明環境での評価
    /// 期待結果: ISO < 1600, 露出時間 < 1/8の場合、poorになる
    func testPoorLightingCondition() {
        let exposureInfo = ExposureInfo(
            iso: 1200,
            exposureDuration: 1.0/15.0, // 1/15秒
            exposureBias: 0
        )
        
        XCTAssertEqual(exposureInfo.lightingCondition, .poor)
        XCTAssertFalse(exposureInfo.lightingCondition.isSuitableForHandTracking)
        XCTAssertTrue(exposureInfo.lightingCondition.shouldShowWarning)
        XCTAssertEqual(exposureInfo.lightingCondition.displayColor, "orange")
        XCTAssertEqual(exposureInfo.lightingCondition.userMessage, "照明が暗いため、手の認識精度が低下する可能性があります。より明るい場所での使用をお勧めします。")
    }
    
    /// 動作: とても暗い照明環境での評価
    /// 期待結果: ISO >= 1600 または 露出時間 >= 1/8の場合、veryPoorになる
    func testVeryPoorLightingCondition() {
        let exposureInfo = ExposureInfo(
            iso: 2000,
            exposureDuration: 1.0/8.0, // 1/8秒
            exposureBias: 0
        )
        
        XCTAssertEqual(exposureInfo.lightingCondition, .veryPoor)
        XCTAssertFalse(exposureInfo.lightingCondition.isSuitableForHandTracking)
        XCTAssertTrue(exposureInfo.lightingCondition.shouldShowWarning)
        XCTAssertEqual(exposureInfo.lightingCondition.displayColor, "red")
        XCTAssertEqual(exposureInfo.lightingCondition.userMessage, "照明がとても暗いため、手の認識が困難です。明るい場所に移動してください。")
    }
    
    /// 動作: 露出時間ベースの厳しい評価
    /// 期待結果: ISO良好でも露出時間が長い場合、より厳しい評価になる
    func testStrictEvaluationBasedOnExposureTime() {
        let exposureInfo = ExposureInfo(
            iso: 100, // excellent range
            exposureDuration: 1.0/10.0, // poor range (1/10秒)
            exposureBias: 0
        )
        
        // より厳しい方（poor）が採用される
        XCTAssertEqual(exposureInfo.lightingCondition, .poor)
    }
    
    /// 動作: ISOベースの厳しい評価
    /// 期待結果: 露出時間良好でもISOが高い場合、より厳しい評価になる
    func testStrictEvaluationBasedOnISO() {
        let exposureInfo = ExposureInfo(
            iso: 1800, // veryPoor range
            exposureDuration: 1.0/120.0, // excellent range
            exposureBias: 0
        )
        
        // より厳しい方（veryPoor）が採用される
        XCTAssertEqual(exposureInfo.lightingCondition, .veryPoor)
    }
}