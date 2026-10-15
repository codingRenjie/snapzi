import SwiftUI
import SwiftData

struct Segment2PracticeFlowLoader: View {
    @Environment(\.modelContext) private var modelContext
    @Binding var path: NavigationPath
    let character: String

    var body: some View {
        let photos = CharacterProgressStore.photos(for: character, in: modelContext)
        Segment2PracticeFlow(path: $path, character: character, photos: photos)
    }
}

struct Segment2PracticeFlow: View {
    @Environment(\.modelContext) private var modelContext
    @Binding var path: NavigationPath
    let character: String

    @State private var session: Segment2Session
    @State private var feedback: Feedback?

    enum Feedback { case correct, wrong }

    init(path: Binding<NavigationPath>, character: String, photos: [CapturedWordPhoto]) {
        _path = path
        self.character = character
        _session = State(initialValue: Segment2Session.build(character: character, photos: photos))
    }

    var body: some View {
        ZStack {
            AppTheme.sky.ignoresSafeArea()
            VStack {
                HStack {
                    SnapZiCircleButton(systemName: "arrow.left", size: 56) {
                        path.removeLast()
                    }
                    Spacer()
                    if feedback != nil {
                        SnapZiCircleButton(systemName: "arrow.right", size: 56) {
                            advance()
                        }
                    }
                }
                .padding(.horizontal, 24)

                if let question = session.current {
                    questionView(question)
                }
            }
        }
        .navigationBarHidden(true)
    }

    @ViewBuilder
    private func questionView(_ question: Segment2Kind) -> some View {
        switch question {
        case let .listenPickPhoto(word, correctPath):
            ListenPickPhotoView(
                word: word,
                correctPath: correctPath,
                photos: allPhotoPaths(),
                feedback: feedback
            ) { success in
                feedback = success ? .correct : .wrong
            }
        case let .threePhotosPickChar(paths, words):
            ThreePickCharView(
                character: character,
                paths: paths,
                words: words,
                feedback: feedback
            ) { success in
                feedback = success ? .correct : .wrong
            }
        case .readCharacter:
            ReadCharacterView(character: character, feedback: feedback) { success in
                feedback = success ? .correct : .wrong
            }
        }
    }

    private func allPhotoPaths() -> [(String, String)] {
        CharacterProgressStore.photos(for: character, in: modelContext)
            .map { ($0.relativePath, $0.wordPhrase) }
    }

    private func advance() {
        feedback = nil
        if session.isLast {
            let record = CharacterProgressStore.record(for: character, in: modelContext)
            record.segment2Complete = true
            try? modelContext.save()
            path.removeLast()
        } else {
            session.advance()
        }
    }
}

private struct ListenPickPhotoView: View {
    let word: String
    let correctPath: String
    let photos: [(String, String)]
    let feedback: Segment2PracticeFlow.Feedback?
    var onAnswer: (Bool) -> Void

    var body: some View {
        HStack(spacing: 32) {
            Button {
                SpeechService.shared.speak(word)
            } label: {
                Image(systemName: "speaker.wave.3.fill")
                    .font(.system(size: 80))
                    .foregroundStyle(AppTheme.orange)
            }
            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 16) {
                ForEach(options(), id: \.0) { path, _ in
                    Button {
                        onAnswer(path == correctPath)
                    } label: {
                        PhotoTile(relativePath: path, label: "")
                    }
                    .disabled(feedback != nil)
                }
            }
            feedbackIcon
        }
        .padding(32)
    }

    private func options() -> [(String, String)] {
        var set = photos.shuffled()
        if !set.contains(where: { $0.0 == correctPath }) {
            set.insert((correctPath, word), at: 0)
        }
        return Array(set.prefix(4))
    }

    @ViewBuilder
    private var feedbackIcon: some View {
        switch feedback {
        case .correct:
            Image(systemName: "checkmark.circle.fill").font(.system(size: 80)).foregroundStyle(.green)
        case .wrong:
            Image(systemName: "xmark.circle.fill").font(.system(size: 80)).foregroundStyle(.red)
        case nil:
            EmptyView()
        }
    }
}

private struct ThreePickCharView: View {
    let character: String
    let paths: [String]
    let words: [String]
    let feedback: Segment2PracticeFlow.Feedback?
    var onAnswer: (Bool) -> Void

    var body: some View {
        HStack(spacing: 24) {
            VStack(spacing: 12) {
                ForEach(Array(paths.enumerated()), id: \.offset) { index, path in
                    VStack {
                        PhotoTile(relativePath: path, label: words.indices.contains(index) ? words[index] : "")
                        Button {
                            SpeechService.shared.speak(words.indices.contains(index) ? words[index] : "")
                        } label: {
                            Image(systemName: "speaker.wave.2.fill")
                        }
                    }
                }
            }
            LazyVGrid(columns: [GridItem(), GridItem()], spacing: 16) {
                ForEach(options(), id: \.self) { char in
                    Button {
                        onAnswer(char == character)
                    } label: {
                        Text(char)
                    }
                    .font(.system(size: 48, weight: .bold))
                    .frame(width: 90, height: 90)
                    .background(.white.opacity(0.8), in: RoundedRectangle(cornerRadius: 12))
                    .disabled(feedback != nil)
                }
            }
            feedbackIcon
        }
        .padding(24)
    }

    private func options() -> [String] {
        var chars = [character]
        chars.append(contentsOf: KeywordCatalog.shared.randomDistractors(excluding: character, count: 3))
        return chars.shuffled()
    }

    @ViewBuilder
    private var feedbackIcon: some View {
        switch feedback {
        case .correct:
            Image(systemName: "checkmark.circle.fill").font(.system(size: 80)).foregroundStyle(.green)
        case .wrong:
            Image(systemName: "xmark.circle.fill").font(.system(size: 80)).foregroundStyle(.red)
        case nil:
            EmptyView()
        }
    }
}

private struct ReadCharacterView: View {
    let character: String
    let feedback: Segment2PracticeFlow.Feedback?
    var onAnswer: (Bool) -> Void

    @State private var matched = false

    var body: some View {
        HStack(spacing: 40) {
            Text(character)
                .font(.system(size: 160, weight: .bold))
            VStack {
                SnapZiCircleButton(systemName: "mic.fill", size: 100) {}
                    .disabled(true)
                if matched { Text("读好了").foregroundStyle(.green) }
            }
            feedbackIcon
        }
        .task { await listen() }
    }

    private func listen() async {
        guard await SpeechRecognitionService.shared.requestAuthorization() else {
            onAnswer(false)
            return
        }
        SpeechService.shared.speak(character)
        try? await Task.sleep(for: .seconds(1))
        try? SpeechRecognitionService.shared.startListening { partial in
            if partial.contains(character) {
                matched = true
                SpeechRecognitionService.shared.stopListening()
                onAnswer(true)
            }
        } onFinish: { final in
            onAnswer(final.contains(character))
        }
        try? await Task.sleep(for: .seconds(10))
        SpeechRecognitionService.shared.stopListening()
        if !matched { onAnswer(false) }
    }

    @ViewBuilder
    private var feedbackIcon: some View {
        switch feedback {
        case .correct:
            Image(systemName: "checkmark.circle.fill").font(.system(size: 80)).foregroundStyle(.green)
        case .wrong:
            Image(systemName: "xmark.circle.fill").font(.system(size: 80)).foregroundStyle(.red)
        case nil:
            EmptyView()
        }
    }
}
