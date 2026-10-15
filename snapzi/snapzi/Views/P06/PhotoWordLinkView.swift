import SwiftUI
import SwiftData

struct PhotoWordLinkView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(CaptureFlowStore.self) private var captureStore
    @Binding var path: NavigationPath
    let character: String

    @State private var pickerWord: String = ""
    @State private var customWord: String = ""
    @State private var previewPath: String?

    var body: some View {
        let saved = CharacterProgressStore.photos(for: character, in: modelContext)
        let suggested = captureStore.suggestedWords.isEmpty
            ? (KeywordCatalog.shared.entry(for: character)?.relatedWords ?? [])
            : captureStore.suggestedWords
        let pickerOptions = pickerOptions(from: suggested)

        ZStack {
            AppTheme.sky.ignoresSafeArea()
            HStack(spacing: 20) {
                ScrollView {
                    VStack(spacing: 10) {
                        ForEach(saved, id: \.relativePath) { photo in
                            Button {
                                previewPath = photo.relativePath
                                pickerWord = photo.wordPhrase
                                customWord = ""
                            } label: {
                                PhotoTile(relativePath: photo.relativePath, label: photo.wordPhrase)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
                .frame(width: 160)

                VStack(spacing: 16) {
                    if let image = captureStore.squareImage {
                        Image(uiImage: image)
                            .resizable()
                            .scaledToFill()
                            .frame(width: 360, height: 360)
                            .clipShape(RoundedRectangle(cornerRadius: 16))
                    } else if let previewPath, let ui = PhotoStorage.load(relativePath: previewPath) {
                        Image(uiImage: ui)
                            .resizable()
                            .scaledToFill()
                            .frame(width: 360, height: 360)
                            .clipShape(RoundedRectangle(cornerRadius: 16))
                    }

                    Text("选推荐词或自己输入")
                        .font(.headline)

                    if !pickerOptions.isEmpty {
                        Picker("推荐词语", selection: $pickerWord) {
                            ForEach(pickerOptions, id: \.self) { word in
                                Text(word).tag(word)
                            }
                        }
                        .pickerStyle(.wheel)
                        .frame(height: 100)
                    }

                    TextField("自己输入，如：玻璃门", text: $customWord)
                        .textFieldStyle(.roundedBorder)
                        .font(.title3)
                        .padding(.horizontal, 8)
                }

                VStack(spacing: 24) {
                    SnapZiCircleButton(systemName: "arrow.left", size: 64) {
                        path.removeLast()
                    }
                    SnapZiCircleButton(systemName: "checkmark", size: 88) {
                        saveLinkedPhoto()
                    }
                }
                .padding(.trailing, 32)
            }
            .padding(24)
        }
        .navigationBarHidden(true)
        .onAppear {
            if pickerWord.isEmpty {
                pickerWord = pickerOptions.first ?? character
            }
        }
    }

    private func pickerOptions(from suggested: [String]) -> [String] {
        var list = suggested
        if !list.contains(character) {
            list.insert(character, at: 0)
        }
        return list
    }

    private var resolvedWordPhrase: String {
        let typed = customWord.trimmingCharacters(in: .whitespacesAndNewlines)
        if !typed.isEmpty { return typed }
        return pickerWord.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private func saveLinkedPhoto() {
        guard let image = captureStore.squareImage else { return }
        let phrase = resolvedWordPhrase
        guard !phrase.isEmpty else { return }

        do {
            let path = try PhotoStorage.save(image)
            let photo = CapturedWordPhoto(
                keywordCharacter: character,
                wordPhrase: phrase,
                relativePath: path
            )
            modelContext.insert(photo)
            CharacterProgressStore.resetPracticeAfterNewPhoto(for: character, in: modelContext)
            try modelContext.save()
            captureStore.squareImage = nil
            NotificationCenter.default.post(name: .snapziPhotosDidUpdate, object: character)
            popToHub()
        } catch {
            print("[SnapZi] save photo failed: \(error)")
        }
    }

    private func popToHub() {
        for _ in 0..<3 where !path.isEmpty {
            path.removeLast()
        }
    }
}

extension Notification.Name {
    static let snapziPhotosDidUpdate = Notification.Name("snapziPhotosDidUpdate")
}
