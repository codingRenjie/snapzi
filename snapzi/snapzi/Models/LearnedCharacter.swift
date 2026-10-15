import Foundation
import SwiftData

@Model
final class LearnedCharacter {
    @Attribute(.unique) var character: String
    var masteryRaw: String
    var lastStudiedAt: Date?
    var nextReviewAt: Date?
    var reviewIntervalDays: Int
    var segment1Complete: Bool
    var segment2Complete: Bool
    var segment3Complete: Bool

    init(character: String, mastery: MasteryLevel = .notStarted) {
        self.character = character
        self.masteryRaw = mastery.rawValue
        self.reviewIntervalDays = 1
        self.segment1Complete = false
        self.segment2Complete = false
        self.segment3Complete = false
    }

    var mastery: MasteryLevel {
        get { MasteryLevel(rawValue: masteryRaw) ?? .notStarted }
        set { masteryRaw = newValue.rawValue }
    }

    var fullyMastered: Bool {
        segment1Complete && segment2Complete && segment3Complete
    }
}
