import SwiftUI
import SwiftData

struct ContentView: View {
    @State private var captureStore = CaptureFlowStore()

    var body: some View {
        RootNavigationView()
            .environment(captureStore)
    }
}

#Preview {
    ContentView()
        .modelContainer(for: [LearnedCharacter.self, CapturedWordPhoto.self], inMemory: true)
}
