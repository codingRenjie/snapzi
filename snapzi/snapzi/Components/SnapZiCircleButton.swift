import SwiftUI

struct SnapZiCircleButton: View {
    let systemName: String
    var size: CGFloat = 72
    var color: Color = AppTheme.orange
    var disabled: Bool = false
    var action: () -> Void

    var body: some View {
        Button(action: action) {
            Image(systemName: systemName)
                .font(.system(size: size * 0.38, weight: .bold))
                .foregroundStyle(.white)
                .frame(width: size, height: size)
                .background(disabled ? Color.gray.opacity(0.4) : color, in: Circle())
        }
        .disabled(disabled)
    }
}

struct SnapZiWideButton: View {
    let title: String
    let systemName: String
    var color: Color = AppTheme.orange
    var disabled: Bool = false
    var action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 16) {
                Image(systemName: systemName)
                    .font(.title.bold())
                Text(title)
                    .font(.title.bold())
            }
            .foregroundStyle(.white)
            .frame(maxWidth: 420, minHeight: 88)
            .background(disabled ? Color.gray.opacity(0.45) : color, in: RoundedRectangle(cornerRadius: 20))
        }
        .disabled(disabled)
    }
}
