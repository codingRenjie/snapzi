import Foundation

enum MasteryLevel: String, Codable, CaseIterable {
    case notStarted
    case introduced
    case recognizing
    case solid

    var displayName: String {
        switch self {
        case .notStarted: "未学"
        case .introduced: "初识"
        case .recognizing: "认读"
        case .solid: "稳固"
        }
    }
}
