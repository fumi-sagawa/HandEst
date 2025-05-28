import Foundation

/// 手の左右を表す列挙型
public enum Handedness: String, CaseIterable, Equatable, Codable {
    case left = "左手"
    case right = "右手"
}