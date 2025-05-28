import XCTest
@testable import HandEst

final class HandednessDataTests: XCTestCase {
    
    /// 動作: HandednessDataを初期化
    /// 期待結果: プロパティが正しく設定される
    func testHandednessDataInitialization() {
        let data = HandednessData(handType: .left, confidence: 0.95)
        
        XCTAssertEqual(data.handType, .left)
        XCTAssertEqual(data.confidence, 0.95)
    }
    
    /// 動作: 信頼度が範囲外の値で初期化
    /// 期待結果: 0-1の範囲にクランプされる
    func testHandednessDataConfidenceClamping() {
        let dataOverOne = HandednessData(handType: .right, confidence: 1.5)
        XCTAssertEqual(dataOverOne.confidence, 1.0)
        
        let dataUnderZero = HandednessData(handType: .left, confidence: -0.5)
        XCTAssertEqual(dataUnderZero.confidence, 0.0)
    }
    
    /// 動作: isReliableメソッドをデフォルト閾値で呼び出し
    /// 期待結果: 信頼度が0.8以上の場合trueを返す
    func testIsReliableWithDefaultThreshold() {
        let highConfidence = HandednessData(handType: .right, confidence: 0.9)
        let lowConfidence = HandednessData(handType: .left, confidence: 0.7)
        
        XCTAssertTrue(highConfidence.isReliable())
        XCTAssertFalse(lowConfidence.isReliable())
    }
    
    /// 動作: isReliableメソッドをカスタム閾値で呼び出し
    /// 期待結果: 信頼度が指定閾値以上の場合trueを返す
    func testIsReliableWithCustomThreshold() {
        let data = HandednessData(handType: .right, confidence: 0.75)
        
        XCTAssertTrue(data.isReliable(threshold: 0.7))
        XCTAssertFalse(data.isReliable(threshold: 0.8))
    }
    
    /// 動作: HandTypeの反対の手を取得
    /// 期待結果: 左手の反対は右手、右手の反対は左手、不明の反対は不明
    func testHandTypeOpposite() {
        XCTAssertEqual(HandType.left.opposite, .right)
        XCTAssertEqual(HandType.right.opposite, .left)
        XCTAssertEqual(HandType.unknown.opposite, .unknown)
    }
    
    /// 動作: HandTypeの英語名を取得
    /// 期待結果: 正しい英語名が返される
    func testHandTypeEnglishName() {
        XCTAssertEqual(HandType.left.englishName, "Left")
        XCTAssertEqual(HandType.right.englishName, "Right")
        XCTAssertEqual(HandType.unknown.englishName, "Unknown")
    }
    
    /// 動作: MultiHandednessDataを初期化
    /// 期待結果: 複数の手のデータが正しく管理される
    func testMultiHandednessDataInitialization() {
        let leftHand = HandednessData(handType: .left, confidence: 0.9)
        let rightHand = HandednessData(handType: .right, confidence: 0.85)
        
        let multiData = MultiHandednessData(hands: [leftHand, rightHand])
        
        XCTAssertEqual(multiData.hands.count, 2)
        XCTAssertEqual(multiData.detectedHandsCount, 2)
    }
    
    /// 動作: MultiHandednessDataから左手と右手のデータを取得
    /// 期待結果: 正しい手のデータが返される
    func testMultiHandednessDataHandAccess() {
        let leftHand = HandednessData(handType: .left, confidence: 0.9)
        let rightHand = HandednessData(handType: .right, confidence: 0.85)
        let unknownHand = HandednessData(handType: .unknown, confidence: 0.5)
        
        let multiData = MultiHandednessData(hands: [leftHand, rightHand, unknownHand])
        
        XCTAssertEqual(multiData.leftHand?.confidence, 0.9)
        XCTAssertEqual(multiData.rightHand?.confidence, 0.85)
    }
    
    /// 動作: 両手が検出されているかを判定
    /// 期待結果: 左手と右手の両方がある場合のみtrueを返す
    func testMultiHandednessDataHasBothHands() {
        let bothHands = MultiHandednessData(hands: [
            HandednessData(handType: .left, confidence: 0.9),
            HandednessData(handType: .right, confidence: 0.85)
        ])
        XCTAssertTrue(bothHands.hasBothHands)
        
        let leftOnly = MultiHandednessData(hands: [
            HandednessData(handType: .left, confidence: 0.9)
        ])
        XCTAssertFalse(leftOnly.hasBothHands)
        
        let unknownHands = MultiHandednessData(hands: [
            HandednessData(handType: .unknown, confidence: 0.9),
            HandednessData(handType: .unknown, confidence: 0.85)
        ])
        XCTAssertFalse(unknownHands.hasBothHands)
    }
    
    /// 動作: 最も信頼度の高い手のデータを取得
    /// 期待結果: 最高の信頼度を持つデータが返される
    func testMultiHandednessDataMostConfidentHand() {
        let hands = [
            HandednessData(handType: .left, confidence: 0.7),
            HandednessData(handType: .right, confidence: 0.95),
            HandednessData(handType: .unknown, confidence: 0.6)
        ]
        
        let multiData = MultiHandednessData(hands: hands)
        
        XCTAssertEqual(multiData.mostConfidentHand?.handType, .right)
        XCTAssertEqual(multiData.mostConfidentHand?.confidence, 0.95)
    }
    
    /// 動作: 空の配列でMultiHandednessDataを初期化
    /// 期待結果: 各プロパティが適切な値を返す
    func testMultiHandednessDataEmpty() {
        let multiData = MultiHandednessData(hands: [])
        
        XCTAssertEqual(multiData.detectedHandsCount, 0)
        XCTAssertNil(multiData.leftHand)
        XCTAssertNil(multiData.rightHand)
        XCTAssertFalse(multiData.hasBothHands)
        XCTAssertNil(multiData.mostConfidentHand)
    }
    
    /// 動作: HandednessDataのEquatable準拠をテスト
    /// 期待結果: 同じ値を持つインスタンスが等しいと判定される
    func testHandednessDataEquatable() {
        let data1 = HandednessData(handType: .left, confidence: 0.9)
        let data2 = HandednessData(handType: .left, confidence: 0.9)
        let data3 = HandednessData(handType: .right, confidence: 0.9)
        
        XCTAssertEqual(data1, data2)
        XCTAssertNotEqual(data1, data3)
    }
    
    /// 動作: HandednessDataのCodable準拠をテスト
    /// 期待結果: エンコード・デコードが正しく動作する
    func testHandednessDataCodable() throws {
        let originalData = HandednessData(handType: .right, confidence: 0.87)
        
        let encoder = JSONEncoder()
        let data = try encoder.encode(originalData)
        
        let decoder = JSONDecoder()
        let decodedData = try decoder.decode(HandednessData.self, from: data)
        
        XCTAssertEqual(originalData, decodedData)
    }
    
    /// 動作: MultiHandednessDataのCodable準拠をテスト
    /// 期待結果: エンコード・デコードが正しく動作する
    func testMultiHandednessDataCodable() throws {
        let hands = [
            HandednessData(handType: .left, confidence: 0.9),
            HandednessData(handType: .right, confidence: 0.85)
        ]
        let originalData = MultiHandednessData(hands: hands)
        
        let encoder = JSONEncoder()
        let data = try encoder.encode(originalData)
        
        let decoder = JSONDecoder()
        let decodedData = try decoder.decode(MultiHandednessData.self, from: data)
        
        XCTAssertEqual(originalData, decodedData)
    }
}