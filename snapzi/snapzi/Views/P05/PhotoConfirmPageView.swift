import SwiftUI

struct PhotoConfirmPageView: View {
    @Binding var path: NavigationPath
    @Environment(CaptureFlowStore.self) private var captureStore
    let character: String

    @State private var showCropper = false

    var body: some View {
        ZStack {
            AppTheme.sky.ignoresSafeArea()
            HStack {
                if let image = captureStore.squareImage {
                    Image(uiImage: image)
                        .resizable()
                        .scaledToFit()
                        .frame(maxWidth: 520, maxHeight: 520)
                        .clipShape(RoundedRectangle(cornerRadius: 16))
                        .padding(32)
                }
                VStack(spacing: 24) {
                    SnapZiCircleButton(systemName: "arrow.counterclockwise", size: 64) {
                        path.removeLast()
                    }
                    SnapZiCircleButton(systemName: "checkmark", size: 88) {
                        path.append(SnapZiRoute.photoWordLink(character))
                    }
                    SnapZiCircleButton(systemName: "crop", size: 64) {
                        showCropper = true
                    }
                }
                .padding(.trailing, 40)
            }
        }
        .navigationBarHidden(true)
        .sheet(isPresented: $showCropper) {
            if let image = captureStore.squareImage {
                SimpleCropSheet(source: image) { cropped in
                    captureStore.squareImage = ImageSquareProcessor.squareCrop(cropped)
                }
            }
        }
    }
}

struct SimpleCropSheet: View {
    @Environment(\.dismiss) private var dismiss
    let source: UIImage
    var onDone: (UIImage) -> Void

    var body: some View {
        NavigationStack {
            VStack {
                Image(uiImage: source)
                    .resizable()
                    .scaledToFit()
                Text("当前版本使用中心方形裁切")
                    .foregroundStyle(.secondary)
                Button("使用此图") {
                    onDone(source)
                    dismiss()
                }
                .buttonStyle(.borderedProminent)
                .tint(AppTheme.orange)
            }
            .padding()
            .navigationTitle("裁剪")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("取消") { dismiss() }
                }
            }
        }
    }
}
