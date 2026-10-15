import SwiftUI
import SwiftData

struct CharacterLibraryView: View {
    @Environment(\.modelContext) private var modelContext
    @Binding var path: NavigationPath

    var body: some View {
        let mastered = CharacterProgressStore.masteredCharacters(in: modelContext)
        libraryShell(
            count: mastered.count,
            caption: "你学了\(mastered.count)个字",
            toggleTitle: "切换照片库",
            toggleRoute: .photoLibrary
        ) {
            LazyVGrid(columns: [GridItem(.adaptive(minimum: 80), spacing: 12)], spacing: 12) {
                ForEach(mastered, id: \.character) { item in
                    Button {
                        path.append(SnapZiRoute.characterHub(item.character))
                    } label: {
                        Text(item.character)
                            .font(.system(size: 44, weight: .bold))
                            .frame(width: 80, height: 80)
                            .background(.white.opacity(0.7), in: RoundedRectangle(cornerRadius: 12))
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }

    @ViewBuilder
    private func libraryShell<Content: View>(
        count: Int,
        caption: String,
        toggleTitle: String,
        toggleRoute: SnapZiRoute,
        @ViewBuilder content: () -> Content
    ) -> some View {
        ZStack {
            AppTheme.sky.ignoresSafeArea()
            HStack(spacing: 24) {
                VStack(alignment: .leading, spacing: 20) {
                    SnapZiCircleButton(systemName: "arrow.left", size: 56) {
                        path.removeLast()
                    }
                    Image(systemName: "medal.fill")
                        .font(.system(size: 100))
                        .foregroundStyle(AppTheme.orange)
                    Text("\(count)")
                        .font(.system(size: 72, weight: .bold))
                        .foregroundStyle(AppTheme.orange)
                    Text(caption)
                        .font(.title2)
                    SnapZiWideButton(title: "复习", systemName: "arrow.triangle.2.circlepath", disabled: true) {}
                    Button(toggleTitle) {
                        path.append(toggleRoute)
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(AppTheme.orange)
                    Spacer()
                }
                .padding(24)
                .frame(width: 260)

                VStack {
                    content()
                }
                .padding(24)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(.white.opacity(0.55), in: RoundedRectangle(cornerRadius: 24))
                .overlay(RoundedRectangle(cornerRadius: 24).stroke(AppTheme.orange, lineWidth: 4))
                .padding(24)
            }
        }
        .navigationBarHidden(true)
    }
}

struct PhotoLibraryView: View {
    @Environment(\.modelContext) private var modelContext
    @Binding var path: NavigationPath

    var body: some View {
        let photos = CharacterProgressStore.allPhotos(in: modelContext)
        ZStack {
            AppTheme.sky.ignoresSafeArea()
            HStack(spacing: 24) {
                VStack(alignment: .leading, spacing: 20) {
                    SnapZiCircleButton(systemName: "arrow.left", size: 56) {
                        path.removeLast()
                    }
                    Image(systemName: "medal.fill")
                        .font(.system(size: 100))
                        .foregroundStyle(AppTheme.orange)
                    Text("\(photos.count)")
                        .font(.system(size: 72, weight: .bold))
                        .foregroundStyle(AppTheme.orange)
                    Text("你收集了\(photos.count)张照片")
                        .font(.title2)
                    SnapZiWideButton(title: "复习", systemName: "arrow.triangle.2.circlepath", disabled: true) {}
                    Button("切换字库") {
                        path.append(SnapZiRoute.characterLibrary)
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(AppTheme.orange)
                    Spacer()
                }
                .padding(24)
                .frame(width: 260)

                ScrollView {
                    LazyVGrid(columns: [GridItem(.adaptive(minimum: 100), spacing: 12)], spacing: 12) {
                        ForEach(photos, id: \.relativePath) { photo in
                            PhotoTile(relativePath: photo.relativePath, label: photo.wordPhrase)
                        }
                    }
                }
                .padding(24)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(.white.opacity(0.55), in: RoundedRectangle(cornerRadius: 24))
                .overlay(RoundedRectangle(cornerRadius: 24).stroke(AppTheme.orange, lineWidth: 4))
                .padding(24)
            }
        }
        .navigationBarHidden(true)
    }
}
