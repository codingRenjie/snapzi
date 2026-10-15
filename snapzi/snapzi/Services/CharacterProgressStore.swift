import Foundation
import SwiftData

enum CharacterProgressStore {
    static func record(for character: String, in context: ModelContext) -> LearnedCharacter {
        let char = character
        let descriptor = FetchDescriptor<LearnedCharacter>(
            predicate: #Predicate { $0.character == char }
        )
        if let existing = try? context.fetch(descriptor).first {
            return existing
        }
        let created = LearnedCharacter(character: character)
        context.insert(created)
        try? context.save()
        return created
    }

    static func photos(for character: String, in context: ModelContext) -> [CapturedWordPhoto] {
        let char = character
        let descriptor = FetchDescriptor<CapturedWordPhoto>(
            predicate: #Predicate { $0.keywordCharacter == char },
            sortBy: [SortDescriptor(\.createdAt)]
        )
        return (try? context.fetch(descriptor)) ?? []
    }

    static func masteredCharacters(in context: ModelContext) -> [LearnedCharacter] {
        let descriptor = FetchDescriptor<LearnedCharacter>(
            sortBy: [SortDescriptor(\.character)]
        )
        return ((try? context.fetch(descriptor)) ?? []).filter(\.fullyMastered)
    }

    static func allPhotos(in context: ModelContext) -> [CapturedWordPhoto] {
        let descriptor = FetchDescriptor<CapturedWordPhoto>(
            sortBy: [SortDescriptor(\.createdAt)]
        )
        return (try? context.fetch(descriptor)) ?? []
    }

    /// 新照片加入字族后，需重新走练习（至少一段；MVP 重置三环）。
    static func resetPracticeAfterNewPhoto(for character: String, in context: ModelContext) {
        let record = record(for: character, in: context)
        record.segment1Complete = false
        record.segment2Complete = false
        record.segment3Complete = false
        record.lastStudiedAt = .now
        try? context.save()
    }

    static func deletePhoto(_ photo: CapturedWordPhoto, in context: ModelContext) {
        PhotoStorage.delete(relativePath: photo.relativePath)
        context.delete(photo)
        try? context.save()
    }

    static func isEligibleForNewCharacterPick(_ character: String, in context: ModelContext) -> Bool {
        let char = character
        let descriptor = FetchDescriptor<LearnedCharacter>(
            predicate: #Predicate { $0.character == char }
        )
        guard let record = try? context.fetch(descriptor).first else { return true }
        return !record.fullyMastered
    }
}
