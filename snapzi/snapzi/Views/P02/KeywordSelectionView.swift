import SwiftUI
import SwiftData

struct KeywordSelectionView: View {
    @Environment(\.modelContext) private var modelContext
    @Binding var path: NavigationPath
    @State private var selected: KeywordEntry?
    @State private var showNeedPickAlert = false

    @Query(sort: \LearnedCharacter.character) private var learnedRecords: [LearnedCharacter]

    private let catalog = KeywordCatalog.shared

    private var pickableKeywords: [KeywordEntry] {
        catalog.keywords.filter { entry in
            guard let record = learnedRecords.first(where: { $0.character == entry.char }) else {
                return true
            }
            return !record.fullyMastered
        }
    }

    var body: some View {
        ZStack {
            AppTheme.sky.ignoresSafeArea()
            VStack(spacing: 16) {
                HStack {
                    SnapZiCircleButton(systemName: "arrow.left", size: 56) {
                        path.removeLast()
                    }
                    Spacer()
                    SnapZiCircleButton(systemName: "checkmark", size: 56, disabled: selected == nil) {
                        guard let selected else {
                            showNeedPickAlert = true
                            return
                        }
                        path.append(SnapZiRoute.characterHub(selected.char))
                    }
                }
                .padding(.horizontal, 24)

                if pickableKeywords.isEmpty {
                    Spacer()
                    Text("暂时没有可新学的字")
                        .font(.title2)
                    Text("已完成三段练习的字请以后在「复习」中巩固（即将开放）。")
                        .font(.body)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 40)
                    Text("已学字可在首页徽章进入字库/照片库查看。")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                        .padding(.top, 8)
                    Spacer()
                } else {
                    ScrollView {
                        LazyVGrid(columns: [GridItem(.adaptive(minimum: 220), spacing: 16)], spacing: 16) {
                            ForEach(pickableKeywords) { entry in
                                KeywordTile(entry: entry, isSelected: selected?.char == entry.char) {
                                    selected = entry
                                }
                            }
                        }
                        .padding(24)
                    }
                }
            }
        }
        .navigationBarHidden(true)
        .alert("请先选一个汉字", isPresented: $showNeedPickAlert) {
            Button("好", role: .cancel) {}
        }
    }
}

private struct KeywordTile: View {
    let entry: KeywordEntry
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(alignment: .top, spacing: 12) {
                Text(entry.char)
                    .font(.system(size: 56, weight: .bold))
                VStack(alignment: .leading, spacing: 4) {
                    ForEach(entry.relatedWords.prefix(4), id: \.self) { word in
                        Text(word).font(.subheadline)
                    }
                }
                Spacer(minLength: 0)
            }
            .padding()
            .frame(maxWidth: .infinity, minHeight: 100, alignment: .leading)
            .background(isSelected ? AppTheme.orange.opacity(0.35) : AppTheme.card, in: RoundedRectangle(cornerRadius: 12))
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(isSelected ? AppTheme.orange : Color.white.opacity(0.6), lineWidth: isSelected ? 3 : 1)
            )
        }
        .buttonStyle(.plain)
    }
}
