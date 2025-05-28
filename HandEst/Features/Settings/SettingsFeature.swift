import ComposableArchitecture
import Foundation

@Reducer
struct SettingsFeature {
    @ObservableState
    struct State: Equatable {
        var hapticFeedbackEnabled = true
        var defaultFocalLength: FocalLength = .normal50mm
        var defaultHandedness: Handedness = .right
        var isLoaded = false
    }
    
    enum Action: Equatable {
        case loadSettings
        case saveSettings
        case setHapticFeedback(Bool)
        case setDefaultFocalLength(FocalLength)
        case setDefaultHandedness(Handedness)
        case settingsLoaded
        case settingsSaved
    }
    
    var body: some ReducerOf<Self> {
        Reduce { state, action in
            switch action {
            case .loadSettings:
                state.isLoaded = true
                return .send(.settingsLoaded)
                
            case .saveSettings:
                return .send(.settingsSaved)
                
            case let .setHapticFeedback(enabled):
                state.hapticFeedbackEnabled = enabled
                return .send(.saveSettings)
                
            case let .setDefaultFocalLength(focalLength):
                state.defaultFocalLength = focalLength
                return .send(.saveSettings)
                
            case let .setDefaultHandedness(handedness):
                state.defaultHandedness = handedness
                return .send(.saveSettings)
                
            case .settingsLoaded, .settingsSaved:
                return .none
            }
        }
    }
}