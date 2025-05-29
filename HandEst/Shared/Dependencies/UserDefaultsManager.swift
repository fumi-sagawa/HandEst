import ComposableArchitecture
import Foundation

struct UserDefaultsManager {
    var load: @Sendable (String) -> Any?
    var save: @Sendable (Any?, String) -> Void
    var remove: @Sendable (String) -> Void
}

extension UserDefaultsManager: DependencyKey {
    static let liveValue = UserDefaultsManager(
        load: { key in
            UserDefaults.standard.object(forKey: key)
        },
        save: { value, key in
            UserDefaults.standard.set(value, forKey: key)
        },
        remove: { key in
            UserDefaults.standard.removeObject(forKey: key)
        }
    )
    
    static let testValue = UserDefaultsManager(
        load: { _ in nil },
        save: { _, _ in },
        remove: { _ in }
    )
}

extension DependencyValues {
    var userDefaultsManager: UserDefaultsManager {
        get { self[UserDefaultsManager.self] }
        set { self[UserDefaultsManager.self] = newValue }
    }
}