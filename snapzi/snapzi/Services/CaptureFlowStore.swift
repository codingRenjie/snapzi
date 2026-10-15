import UIKit
import Observation

@Observable
final class CaptureFlowStore {
    var keywordCharacter: String = ""
    var squareImage: UIImage?
    var suggestedWords: [String] = []
    var selectedWord: String = ""
}
