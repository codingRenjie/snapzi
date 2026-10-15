import Foundation
import SwiftData

@Model
final class CapturedWordPhoto {
    var keywordCharacter: String
    var wordPhrase: String
    var relativePath: String
    var createdAt: Date

    init(keywordCharacter: String, wordPhrase: String, relativePath: String, createdAt: Date = .now) {
        self.keywordCharacter = keywordCharacter
        self.wordPhrase = wordPhrase
        self.relativePath = relativePath
        self.createdAt = createdAt
    }
}
