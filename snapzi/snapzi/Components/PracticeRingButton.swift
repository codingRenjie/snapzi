import SwiftUI

/// 页面 03/07：三段练习外圈 + 中央铅笔图标
struct PracticeRingButton: View {
    var segment1Done: Bool
    var segment2Done: Bool
    var segment3Done: Bool
    var enabled: Bool
    var action: () -> Void

    var body: some View {
        Button(action: action) {
            ZStack {
                Circle()
                    .stroke(Color.gray.opacity(0.35), lineWidth: 10)
                    .frame(width: 100, height: 100)
                PracticeRingArcs(
                    segment1Done: segment1Done,
                    segment2Done: segment2Done,
                    segment3Done: segment3Done
                )
                .frame(width: 100, height: 100)
                Circle()
                    .fill(enabled ? AppTheme.brown : Color.gray.opacity(0.35))
                    .frame(width: 72, height: 72)
                Image(systemName: "pencil")
                    .font(.title.bold())
                    .foregroundStyle(.white)
            }
        }
        .disabled(!enabled)
    }
}

private struct PracticeRingArcs: View {
    let segment1Done: Bool
    let segment2Done: Bool
    let segment3Done: Bool

    var body: some View {
        ZStack {
            ringSegment(start: -90, end: 30, filled: segment1Done)
            ringSegment(start: 30, end: 150, filled: segment2Done)
            ringSegment(start: 150, end: 270, filled: segment3Done)
        }
    }

    private func ringSegment(start: Double, end: Double, filled: Bool) -> some View {
        Circle()
            .trim(from: CGFloat((start + 90) / 360), to: CGFloat((end + 90) / 360))
            .stroke(filled ? AppTheme.orange : Color.clear, style: StrokeStyle(lineWidth: 10, lineCap: .round))
            .rotationEffect(.degrees(-90))
    }
}
