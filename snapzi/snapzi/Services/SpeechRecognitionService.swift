import Speech
import AVFoundation

@MainActor
final class SpeechRecognitionService: NSObject {
    static let shared = SpeechRecognitionService()

    private let recognizer = SFSpeechRecognizer(locale: Locale(identifier: "zh-CN"))
    private var recognitionTask: SFSpeechRecognitionTask?
    private var audioEngine = AVAudioEngine()

    func requestAuthorization() async -> Bool {
        await withCheckedContinuation { continuation in
            SFSpeechRecognizer.requestAuthorization { status in
                continuation.resume(returning: status == .authorized)
            }
        }
    }

    func startListening(onPartial: @escaping (String) -> Void, onFinish: @escaping (String) -> Void) throws {
        stopListening()
        let session = AVAudioSession.sharedInstance()
        try session.setCategory(.record, mode: .measurement, options: .duckOthers)
        try session.setActive(true, options: .notifyOthersOnDeactivation)

        guard let recognizer, recognizer.isAvailable else { return }
        let request = SFSpeechAudioBufferRecognitionRequest()
        request.shouldReportPartialResults = true

        let input = audioEngine.inputNode
        recognitionTask = recognizer.recognitionTask(with: request) { result, error in
            if let result {
                let text = result.bestTranscription.formattedString
                onPartial(text)
                if result.isFinal {
                    onFinish(text)
                }
            }
            if error != nil {
                onFinish("")
            }
        }

        let format = input.outputFormat(forBus: 0)
        input.installTap(onBus: 0, bufferSize: 1024, format: format) { buffer, _ in
            request.append(buffer)
        }
        audioEngine.prepare()
        try audioEngine.start()
    }

    func stopListening() {
        recognitionTask?.cancel()
        recognitionTask = nil
        if audioEngine.isRunning {
            audioEngine.stop()
            audioEngine.inputNode.removeTap(onBus: 0)
        }
    }

    static func matchedCharacterIndices(in phrase: String, recognition: String) -> Set<Int> {
        let chars = Array(phrase)
        var matched = Set<Int>()
        guard !recognition.isEmpty else { return matched }
        for (index, char) in chars.enumerated() {
            if recognition.contains(char) {
                matched.insert(index)
            }
        }
        return matched
    }
}
