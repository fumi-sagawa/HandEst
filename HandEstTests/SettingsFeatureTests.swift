import XCTest
import ComposableArchitecture
@testable import HandEst

@MainActor
final class SettingsFeatureTests: XCTestCase {
    
    /// 動作: 設定読み込みアクションをテスト
    /// 期待結果: isLoadedがtrueになり、settingsLoadedアクションが送信される
    func testLoadSettings() async {
        let store = TestStore(
            initialState: SettingsFeature.State(),
            reducer: { SettingsFeature() }
        )
        
        await store.send(.loadSettings) {
            $0.isLoaded = true
        }
        await store.receive(.settingsLoaded)
    }
    
    /// 動作: 触覚フィードバック設定アクションをテスト
    /// 期待結果: hapticFeedbackEnabledが更新され、saveSettingsアクションが送信される
    func testSetHapticFeedback() async {
        let store = TestStore(
            initialState: SettingsFeature.State(),
            reducer: { SettingsFeature() }
        )
        
        await store.send(.setHapticFeedback(false)) {
            $0.hapticFeedbackEnabled = false
        }
        await store.receive(.saveSettings)
        await store.receive(.settingsSaved)
    }
    
    /// 動作: デフォルト焦点距離設定アクションをテスト
    /// 期待結果: defaultFocalLengthが更新され、saveSettingsアクションが送信される
    func testSetDefaultFocalLength() async {
        let store = TestStore(
            initialState: SettingsFeature.State(),
            reducer: { SettingsFeature() }
        )
        
        await store.send(.setDefaultFocalLength(.wide24mm)) {
            $0.defaultFocalLength = .wide24mm
        }
        await store.receive(.saveSettings)
        await store.receive(.settingsSaved)
    }
    
    /// 動作: デフォルト手の左右設定アクションをテスト
    /// 期待結果: defaultHandednessが更新され、saveSettingsアクションが送信される
    func testSetDefaultHandedness() async {
        let store = TestStore(
            initialState: SettingsFeature.State(),
            reducer: { SettingsFeature() }
        )
        
        await store.send(.setDefaultHandedness(.left)) {
            $0.defaultHandedness = .left
        }
        await store.receive(.saveSettings)
        await store.receive(.settingsSaved)
    }
    
    /// 動作: 設定保存アクションをテスト
    /// 期待結果: settingsSavedアクションが送信される
    func testSaveSettings() async {
        let store = TestStore(
            initialState: SettingsFeature.State(),
            reducer: { SettingsFeature() }
        )
        
        await store.send(.saveSettings)
        await store.receive(.settingsSaved)
    }
}