import Foundation

enum Segment2Kind: Hashable {
    case listenPickPhoto(word: String, correctPath: String)
    case threePhotosPickChar(paths: [String], words: [String])
    case readCharacter
}

struct Segment1Session {
    let character: String
    let items: [(word: String, path: String)]
    var index: Int = 0

    var current: (word: String, path: String)? {
        guard items.indices.contains(index) else { return nil }
        return items[index]
    }

    var isLast: Bool { index >= items.count - 1 }

    mutating func advance() { index += 1 }
}

struct Segment2Session {
    let character: String
    let questions: [Segment2Kind]
    var index: Int = 0

    var current: Segment2Kind? {
        guard questions.indices.contains(index) else { return nil }
        return questions[index]
    }

    var isLast: Bool { index >= questions.count - 1 }

    mutating func advance() { index += 1 }

    static func build(character: String, photos: [CapturedWordPhoto]) -> Segment2Session {
        var questions: [Segment2Kind] = []
        for photo in photos {
            questions.append(.listenPickPhoto(word: photo.wordPhrase, correctPath: photo.relativePath))
        }
        if photos.count >= 3 {
            let slice = Array(photos.prefix(3))
            questions.append(.threePhotosPickChar(
                paths: slice.map(\.relativePath),
                words: slice.map(\.wordPhrase)
            ))
        }
        if photos.count >= 4 {
            let slice = Array(photos.suffix(3))
            questions.append(.threePhotosPickChar(
                paths: slice.map(\.relativePath),
                words: slice.map(\.wordPhrase)
            ))
        }
        questions.append(.readCharacter)
        questions.shuffle()
        return Segment2Session(character: character, questions: questions)
    }
}

enum PracticeRouter {
    static func segment1Session(character: String, photos: [CapturedWordPhoto]) -> Segment1Session {
        Segment1Session(
            character: character,
            items: photos.map { ($0.wordPhrase, $0.relativePath) }
        )
    }

    static func nextSegmentEntry(record: LearnedCharacter) -> SegmentEntry? {
        if !record.segment1Complete { return .segment1 }
        if !record.segment2Complete { return .segment2 }
        if !record.segment3Complete { return .segment3Intro }
        return nil
    }
}

enum SegmentEntry: Hashable {
    case segment1
    case segment2
    case segment3Intro
    case segment3Fixed
    case segment3Free
}
