import SwiftUI

struct RootNavigationView: View {
    @State private var path = NavigationPath()
    @Environment(CaptureFlowStore.self) private var captureStore

    var body: some View {
        NavigationStack(path: $path) {
            HomePageView(path: $path)
                .navigationDestination(for: SnapZiRoute.self) { route in
                    switch route {
                    case .keywordPick:
                        KeywordSelectionView(path: $path)
                    case let .characterHub(char):
                        CharacterHubView(path: $path, character: char)
                    case let .camera(char):
                        CameraLandscapeView(path: $path, character: char)
                    case let .photoConfirm(char):
                        PhotoConfirmPageView(path: $path, character: char)
                    case let .photoWordLink(char):
                        PhotoWordLinkView(path: $path, character: char)
                    case let .segment1(char):
                        Segment1PracticeFlowLoader(path: $path, character: char)
                    case let .segment2(char):
                        Segment2PracticeFlowLoader(path: $path, character: char)
                    case let .segment3Intro(char):
                        Segment3IntroView(path: $path, character: char)
                    case let .segment3Fixed(char):
                        Segment3FixedWritingView(path: $path, character: char)
                    case let .segment3Free(char):
                        Segment3FreeWritingView(path: $path, character: char)
                    case .characterLibrary:
                        CharacterLibraryView(path: $path)
                    case .photoLibrary:
                        PhotoLibraryView(path: $path)
                    }
                }
        }
        .environment(captureStore)
    }
}
