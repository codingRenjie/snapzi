import Foundation

struct KeywordEntry: Identifiable, Codable, Hashable {
    var id: String { char }
    let char: String
    let relatedWords: [String]

    var captureWords: [String] {
        Array(relatedWords.prefix(3))
    }
}

struct KeywordCatalog: Sendable {
    static let shared = KeywordCatalog()

    let keywords: [KeywordEntry]

    init() {
        keywords = Self.loadKeywords()
    }

    func entry(for character: String) -> KeywordEntry? {
        keywords.first { $0.char == character }
    }

    func randomDistractors(excluding character: String, count: Int) -> [String] {
        keywords
            .map(\.char)
            .filter { $0 != character }
            .shuffled()
            .prefix(count)
            .map { $0 }
    }

    private static func loadKeywords() -> [KeywordEntry] {
        guard
            let url = Bundle.main.url(forResource: "keywords", withExtension: "json"),
            let data = try? Data(contentsOf: url),
            let root = try? JSONDecoder().decode(Root.self, from: data)
        else {
            return [
                KeywordEntry(char: "门", relatedWords: ["大门", "房门", "柜门"])
            ]
        }
        return root.keywords
    }

    private struct Root: Decodable {
        let keywords: [KeywordEntry]
    }
}
