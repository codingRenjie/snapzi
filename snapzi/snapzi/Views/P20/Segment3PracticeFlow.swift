import SwiftUI
import SwiftData
import PencilKit

struct Segment3IntroView: View {
    @Binding var path: NavigationPath
    let character: String
    @State private var animate = false

    var body: some View {
        ZStack {
            AppTheme.sky.ignoresSafeArea()
            HStack {
                SnapZiCircleButton(systemName: "arrow.left", size: 56) {
                    path.removeLast()
                }
                .padding(.leading, 24)
                Spacer()
                WritingGridCharacterView(character: character, progress: animate ? 1 : 0.35)
                    .onTapGesture {
                        withAnimation(.easeInOut(duration: 1.2)) { animate.toggle() }
                        SpeechService.shared.speak(character)
                    }
                Spacer()
                SnapZiCircleButton(systemName: "pencil", size: 88) {
                    path.append(SnapZiRoute.segment3Fixed(character))
                }
                .padding(.trailing, 32)
            }
        }
        .navigationBarHidden(true)
        .onAppear {
            SpeechService.shared.speak(character)
            withAnimation(.easeInOut(duration: 1.0)) { animate = true }
        }
    }
}

struct Segment3FixedWritingView: View {
    @Binding var path: NavigationPath
    let character: String
    @State private var feedback: Feedback?

    enum Feedback { case correct, wrong }

    var body: some View {
        ZStack {
            AppTheme.sky.ignoresSafeArea()
            HStack {
                WritingGridCharacterView(character: character, progress: 0.2, showGuide: true)
                if feedback == .correct {
                    SnapZiCircleButton(systemName: "checkmark", size: 88, color: .green) {}
                        .disabled(true)
                    SnapZiCircleButton(systemName: "arrow.right", size: 64) {
                        path.append(SnapZiRoute.segment3Free(character))
                    }
                } else if feedback == .wrong {
                    SnapZiCircleButton(systemName: "xmark", size: 88, color: .red) {}
                        .disabled(true)
                    SnapZiCircleButton(systemName: "arrow.right", size: 64) {
                        path.append(SnapZiRoute.segment3Free(character))
                    }
                } else {
                    FixedStrokeTracingView(character: character) { ok in
                        feedback = ok ? .correct : .wrong
                    }
                }
            }
            .padding(24)
        }
        .navigationBarHidden(true)
    }
}

struct Segment3FreeWritingView: View {
    @Environment(\.modelContext) private var modelContext
    @Binding var path: NavigationPath
    let character: String
    @State private var drawing = PKDrawing()
    @State private var feedback: Segment3FixedWritingView.Feedback?

    var body: some View {
        ZStack {
            AppTheme.sky.ignoresSafeArea()
            HStack {
                WritingGridCharacterView(character: character, progress: 0.15)
                VStack(spacing: 16) {
                    PencilCanvasRepresentable(drawing: $drawing)
                        .frame(width: 320, height: 320)
                        .background(.white.opacity(0.8), in: RoundedRectangle(cornerRadius: 12))
                    Button("写好了") {
                        let ok = !drawing.strokes.isEmpty
                        feedback = ok ? .correct : .wrong
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(AppTheme.orange)
                }
                if feedback == .correct {
                    SnapZiCircleButton(systemName: "checkmark", size: 88, color: .green) {}
                    SnapZiCircleButton(systemName: "arrow.right", size: 64) {
                        finishSegment3()
                    }
                } else if feedback == .wrong {
                    SnapZiCircleButton(systemName: "xmark", size: 88, color: .red) {}
                    SnapZiCircleButton(systemName: "arrow.right", size: 64) {
                        finishSegment3()
                    }
                }
            }
            .padding(24)
        }
        .navigationBarHidden(true)
    }

    private func finishSegment3() {
        let record = CharacterProgressStore.record(for: character, in: modelContext)
        record.segment3Complete = true
        record.mastery = .solid
        try? modelContext.save()
        for _ in 0..<3 where !path.isEmpty {
            path.removeLast()
        }
    }
}

struct WritingGridCharacterView: View {
    let character: String
    var progress: CGFloat = 1
    var showGuide: Bool = false

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 12)
                .fill(.white.opacity(0.85))
                .frame(width: 320, height: 320)
            GridLines()
            Text(character)
                .font(.system(size: 180, weight: .bold))
                .foregroundStyle(showGuide ? Color.gray.opacity(0.35) : Color.primary.opacity(Double(progress)))
        }
    }
}

private struct GridLines: View {
    var body: some View {
        ZStack {
            Rectangle().stroke(AppTheme.gridLine, lineWidth: 2).frame(width: 280, height: 280)
            Path { path in
                path.move(to: CGPoint(x: 0, y: 140))
                path.addLine(to: CGPoint(x: 280, y: 140))
                path.move(to: CGPoint(x: 140, y: 0))
                path.addLine(to: CGPoint(x: 140, y: 280))
            }
            .stroke(style: StrokeStyle(lineWidth: 1, dash: [6, 6]))
            .foregroundStyle(AppTheme.gridLine.opacity(0.8))
            .frame(width: 280, height: 280)
        }
    }
}

struct FixedStrokeTracingView: View {
    let character: String
    var onDone: (Bool) -> Void
    @State private var traced = false

    var body: some View {
        VStack(spacing: 16) {
            Text("跟着箭头写")
                .font(.headline)
            ZStack {
                WritingGridCharacterView(character: character, progress: 0.2, showGuide: true)
                Path { path in
                    path.move(to: CGPoint(x: 80, y: 40))
                    path.addLine(to: CGPoint(x: 80, y: 260))
                }
                .stroke(AppTheme.orange, style: StrokeStyle(lineWidth: 8, lineCap: .round))
                .frame(width: 320, height: 320)
            }
            .gesture(
                DragGesture(minimumDistance: 10)
                    .onChanged { _ in traced = true }
                    .onEnded { _ in onDone(traced) }
            )
        }
    }
}

struct PencilCanvasRepresentable: UIViewRepresentable {
    @Binding var drawing: PKDrawing

    func makeUIView(context: Context) -> PKCanvasView {
        let view = PKCanvasView()
        view.drawingPolicy = .anyInput
        view.tool = PKInkingTool(.pen, color: .orange, width: 8)
        view.backgroundColor = .clear
        view.delegate = context.coordinator
        return view
    }

    func updateUIView(_ uiView: PKCanvasView, context: Context) {
        if uiView.drawing != drawing {
            uiView.drawing = drawing
        }
    }

    func makeCoordinator() -> Coordinator { Coordinator(drawing: $drawing) }

    final class Coordinator: NSObject, PKCanvasViewDelegate {
        @Binding var drawing: PKDrawing
        init(drawing: Binding<PKDrawing>) { _drawing = drawing }
        func canvasViewDrawingDidChange(_ canvasView: PKCanvasView) {
            drawing = canvasView.drawing
        }
    }
}
