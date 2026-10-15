import SwiftUI
import SwiftData

struct CharacterHubView: View {
    @Environment(\.modelContext) private var modelContext
    @Binding var path: NavigationPath
    let character: String

    @Query private var photos: [CapturedWordPhoto]
    @Query private var records: [LearnedCharacter]

    @State private var showNeedPhotoAlert = false
    @State private var deleteMarkedPath: String?
    @State private var photoPendingDelete: CapturedWordPhoto?
    @State private var showDeleteConfirm = false

    init(path: Binding<NavigationPath>, character: String) {
        self.character = character
        _path = path
        let keyword = character
        _photos = Query(
            filter: #Predicate<CapturedWordPhoto> { $0.keywordCharacter == keyword },
            sort: [SortDescriptor(\.createdAt)]
        )
        _records = Query(
            filter: #Predicate<LearnedCharacter> { $0.character == keyword }
        )
    }

    private var entry: KeywordEntry? { KeywordCatalog.shared.entry(for: character) }

    var body: some View {
        let record = records.first
        ZStack {
            AppTheme.sky.ignoresSafeArea()
            HStack(alignment: .top, spacing: 24) {
                VStack(spacing: 16) {
                    Text(character)
                        .font(.system(size: 120, weight: .bold))
                    photoGrid(photos: photos, entry: entry)
                    Spacer()
                }
                .padding(.leading, 32)

                VStack(spacing: 20) {
                    SnapZiCircleButton(systemName: "medal.fill", size: 56) {
                        path.append(SnapZiRoute.characterLibrary)
                    }
                    SnapZiCircleButton(systemName: "arrow.left", size: 56) {
                        path.removeLast()
                    }
                    SnapZiCircleButton(systemName: "camera.fill", size: 88) {
                        path.append(SnapZiRoute.camera(character))
                    }
                    PracticeRingButton(
                        segment1Done: record?.segment1Complete ?? false,
                        segment2Done: record?.segment2Complete ?? false,
                        segment3Done: record?.segment3Complete ?? false,
                        enabled: !photos.isEmpty
                    ) {
                        startPractice(record: record, photos: photos)
                    }
                }
                .padding(.trailing, 32)
                .padding(.top, 24)
            }
        }
        .navigationBarHidden(true)
        .alert("请先拍至少一张照片", isPresented: $showNeedPhotoAlert) {
            Button("好", role: .cancel) {}
        }
        .alert("删除这张照片？", isPresented: $showDeleteConfirm) {
            Button("删除", role: .destructive) {
                if let photoPendingDelete {
                    deletePhoto(photoPendingDelete)
                }
            }
            Button("取消", role: .cancel) {
                photoPendingDelete = nil
            }
        } message: {
            if let photoPendingDelete {
                Text("「\(photoPendingDelete.wordPhrase)」将从本字和照片库中移除，无法恢复。")
            }
        }
        .onAppear {
            if records.isEmpty {
                _ = CharacterProgressStore.record(for: character, in: modelContext)
            }
        }
    }

    @ViewBuilder
    private func photoGrid(photos: [CapturedWordPhoto], entry: KeywordEntry?) -> some View {
        let columns = [GridItem(.adaptive(minimum: 140), spacing: 12)]
        ScrollView {
            LazyVGrid(columns: columns, spacing: 12) {
                ForEach(photos, id: \.persistentModelID) { photo in
                    HubPhotoTile(
                        photo: photo,
                        showsDelete: deleteMarkedPath == photo.relativePath,
                        onLongPress: {
                            deleteMarkedPath = photo.relativePath
                        },
                        onDelete: {
                            photoPendingDelete = photo
                            showDeleteConfirm = true
                        }
                    )
                }
                if let entry {
                    let capturedWords = Set(photos.map(\.wordPhrase))
                    let pending = entry.relatedWords.filter { !capturedWords.contains($0) }
                    if !pending.isEmpty {
                        VStack(alignment: .leading, spacing: 6) {
                            ForEach(pending.prefix(4), id: \.self) { word in
                                Text(word).font(.caption)
                            }
                        }
                        .padding()
                        .frame(minWidth: 140, minHeight: 120)
                        .background(AppTheme.card, in: RoundedRectangle(cornerRadius: 12))
                    }
                }
            }
            .frame(maxWidth: 700, minHeight: 200, alignment: .leading)
        }
        .onTapGesture {
            deleteMarkedPath = nil
        }
    }

    private func deletePhoto(_ photo: CapturedWordPhoto) {
        CharacterProgressStore.deletePhoto(photo, in: modelContext)
        deleteMarkedPath = nil
        photoPendingDelete = nil
        NotificationCenter.default.post(name: .snapziPhotosDidUpdate, object: character)

        let remaining = CharacterProgressStore.photos(for: character, in: modelContext)
        if remaining.isEmpty {
            let record = CharacterProgressStore.record(for: character, in: modelContext)
            record.segment1Complete = false
            record.segment2Complete = false
            record.segment3Complete = false
            try? modelContext.save()
        }
    }

    private func startPractice(record: LearnedCharacter?, photos: [CapturedWordPhoto]) {
        guard !photos.isEmpty else {
            showNeedPhotoAlert = true
            return
        }
        let progress = record ?? CharacterProgressStore.record(for: character, in: modelContext)
        guard let entry = PracticeRouter.nextSegmentEntry(record: progress) else { return }
        switch entry {
        case .segment1:
            path.append(SnapZiRoute.segment1(character))
        case .segment2:
            path.append(SnapZiRoute.segment2(character))
        case .segment3Intro:
            path.append(SnapZiRoute.segment3Intro(character))
        case .segment3Fixed:
            path.append(SnapZiRoute.segment3Fixed(character))
        case .segment3Free:
            path.append(SnapZiRoute.segment3Free(character))
        }
    }
}

struct PhotoTile: View {
    let relativePath: String
    let label: String

    var body: some View {
        VStack(spacing: 6) {
            if let ui = PhotoStorage.load(relativePath: relativePath) {
                Image(uiImage: ui)
                    .resizable()
                    .scaledToFill()
                    .frame(width: 140, height: 120)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
            } else {
                RoundedRectangle(cornerRadius: 12)
                    .fill(AppTheme.card)
                    .frame(width: 140, height: 120)
            }
            if !label.isEmpty {
                Text(label)
                    .font(.caption.bold())
            }
        }
    }
}

private struct HubPhotoTile: View {
    let photo: CapturedWordPhoto
    let showsDelete: Bool
    var onLongPress: () -> Void
    var onDelete: () -> Void

    var body: some View {
        ZStack(alignment: .topTrailing) {
            PhotoTile(relativePath: photo.relativePath, label: photo.wordPhrase)
                .contentShape(Rectangle())
                .onLongPressGesture(minimumDuration: 0.45) {
                    onLongPress()
                }

            if showsDelete {
                Button(action: onDelete) {
                    Image(systemName: "xmark.circle.fill")
                        .font(.title)
                        .symbolRenderingMode(.palette)
                        .foregroundStyle(.white, Color.red)
                        .shadow(radius: 2)
                }
                .buttonStyle(.plain)
                .offset(x: 8, y: -8)
                .accessibilityLabel("删除照片")
            }
        }
    }
}
