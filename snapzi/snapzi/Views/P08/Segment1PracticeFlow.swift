import SwiftUI
import SwiftData

struct Segment1PracticeFlow: View {
    @Environment(\.modelContext) private var modelContext
    @Binding var path: NavigationPath
    let character: String

    @State private var session: Segment1Session
    @State private var phase: Phase = .question
    @State private var matched = Set<Int>()
    @State private var attempts = 0
    @State private var listening = false

    enum Phase { case question, correct, wrong }

    init(path: Binding<NavigationPath>, character: String, photos: [CapturedWordPhoto]) {
        _path = path
        self.character = character
        _session = State(initialValue: PracticeRouter.segment1Session(character: character, photos: photos))
    }

    var body: some View {
        let item = session.current
        ZStack {
            AppTheme.sky.ignoresSafeArea()
            if let item {
                HStack(spacing: 24) {
                    SnapZiCircleButton(systemName: "arrow.left", size: 56) {
                        path.removeLast()
                    }
                    .frame(maxWidth: 80)

                    VStack(spacing: 12) {
                        if let ui = PhotoStorage.load(relativePath: item.path) {
                            Image(uiImage: ui)
                                .resizable()
                                .scaledToFill()
                                .frame(width: 220, height: 220)
                                .clipShape(RoundedRectangle(cornerRadius: 16))
                        }
                        Button {
                            replayPrompt(for: item.word)
                        } label: {
                            Image(systemName: "speaker.wave.2.fill")
                                .padding(10)
                                .background(AppTheme.orange, in: Capsule())
                                .foregroundStyle(.white)
                        }
                    }

                    WordCharBoxes(word: item.word, matched: matched, success: phase == .correct)

                    Spacer()

                    statusIcon
                    if phase != .question {
                        SnapZiCircleButton(systemName: "arrow.right", size: 64) {
                            goNext(afterSuccess: phase == .correct)
                        }
                    }
                }
                .padding(32)
            }
        }
        .navigationBarHidden(true)
        .task { await beginQuestion() }
        .onDisappear { SpeechRecognitionService.shared.stopListening() }
    }

    @ViewBuilder
    private var statusIcon: some View {
        switch phase {
        case .question:
            SnapZiCircleButton(systemName: listening ? "mic.fill" : "mic", size: 100, color: AppTheme.orange) {}
                .disabled(true)
        case .correct:
            SnapZiCircleButton(systemName: "checkmark", size: 100, color: .green) {}
                .disabled(true)
        case .wrong:
            SnapZiCircleButton(systemName: "xmark", size: 100, color: .red) {}
                .disabled(true)
        }
    }

    private func beginQuestion() async {
        phase = .question
        matched = []
        attempts = 0
        guard let item = session.current else { return }
        let authorized = await SpeechRecognitionService.shared.requestAuthorization()
        SpeechService.shared.speak("这张照片是什么呀？小朋友请你读出来")
        try? await Task.sleep(for: .seconds(3))
        guard authorized else { return }
        startListening(for: item.word)
    }

    private func replayPrompt(for word: String) {
        SpeechService.shared.speak(word)
        Task {
            try? await Task.sleep(for: .milliseconds(800))
            startListening(for: word)
        }
    }

    private func startListening(for word: String) {
        listening = true
        Task {
            try? SpeechRecognitionService.shared.startListening { partial in
                matched = SpeechRecognitionService.matchedCharacterIndices(in: word, recognition: partial)
                if matched.count == word.count {
                    finishQuestion(success: true)
                }
            } onFinish: { final in
                matched = SpeechRecognitionService.matchedCharacterIndices(in: word, recognition: final)
                if matched.count == word.count {
                    finishQuestion(success: true)
                } else {
                    attempts += 1
                    if attempts >= 3 {
                        finishQuestion(success: false)
                    }
                }
            }
            try? await Task.sleep(for: .seconds(10))
            if phase == .question {
                attempts += 1
                finishQuestion(success: false)
            }
        }
    }

    private func finishQuestion(success: Bool) {
        SpeechRecognitionService.shared.stopListening()
        listening = false
        phase = success ? .correct : .wrong
    }

    private func goNext(afterSuccess: Bool) {
        if session.isLast {
            let record = CharacterProgressStore.record(for: character, in: modelContext)
            record.segment1Complete = true
            record.mastery = .recognizing
            try? modelContext.save()
            path.removeLast()
        } else {
            session.advance()
            Task { await beginQuestion() }
        }
    }
}

struct WordCharBoxes: View {
    let word: String
    let matched: Set<Int>
    var success: Bool = false

    var body: some View {
        HStack(spacing: 12) {
            ForEach(Array(word.enumerated()), id: \.offset) { index, char in
                Text(String(char))
                    .font(.system(size: 56, weight: .bold))
                    .frame(width: 80, height: 80)
                    .background(.white.opacity(0.8), in: RoundedRectangle(cornerRadius: 12))
                    .foregroundStyle(color(for: index))
            }
        }
    }

    private func color(for index: Int) -> Color {
        if success { return .green }
        return matched.contains(index) ? .green : .primary
    }
}

struct Segment1PracticeFlowLoader: View {
    @Environment(\.modelContext) private var modelContext
    @Binding var path: NavigationPath
    let character: String

    var body: some View {
        let photos = CharacterProgressStore.photos(for: character, in: modelContext)
        Segment1PracticeFlow(path: $path, character: character, photos: photos)
    }
}
