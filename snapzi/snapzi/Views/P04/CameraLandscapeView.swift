import SwiftUI
import AVFoundation

struct CameraLandscapeView: View {
    @Binding var path: NavigationPath
    @Environment(CaptureFlowStore.self) private var captureStore
    let character: String

    @State private var zoom: CGFloat = 1
    @State private var showPicker = false

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            HStack(spacing: 0) {
                ZStack {
                    CameraPreviewRepresentable(zoom: $zoom)
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color.white, lineWidth: 3)
                        .frame(width: 320, height: 320)
                        .allowsHitTesting(false)
                        .overlay {
                            Text("把东西放进方框里")
                                .font(.headline)
                                .foregroundStyle(.white)
                                .padding(8)
                                .background(.black.opacity(0.35), in: Capsule())
                                .offset(y: -190)
                        }
                }
                .padding(24)
                .gesture(MagnificationGesture().onChanged { value in
                    zoom = min(max(value, 1), 3)
                })

                VStack(spacing: 24) {
                    SnapZiCircleButton(systemName: "xmark", size: 64) {
                        path.removeLast()
                    }
                    SnapZiCircleButton(systemName: "camera.fill", size: 88) {
                        NotificationCenter.default.post(name: .snapziCapturePhoto, object: nil)
                    }
                    SnapZiCircleButton(systemName: "photo.on.rectangle", size: 64) {
                        showPicker = true
                    }
                }
                .padding(.trailing, 40)
            }
        }
        .navigationBarHidden(true)
        .sheet(isPresented: $showPicker) {
            LegacyImagePicker { image in
                finishWithImage(image)
            }
        }
        .onAppear {
            captureStore.keywordCharacter = character
            captureStore.suggestedWords = KeywordCatalog.shared.entry(for: character)?.relatedWords ?? []
        }
        .onReceive(NotificationCenter.default.publisher(for: .snapziPhotoCaptured)) { note in
            guard let image = note.object as? UIImage else { return }
            finishWithImage(image)
        }
    }

    private func finishWithImage(_ image: UIImage) {
        let normalized = image.normalizedUpOrientation()
        captureStore.squareImage = ImageSquareProcessor.squareCrop(normalized)
        path.append(SnapZiRoute.photoConfirm(character))
    }
}

extension Notification.Name {
    static let snapziCapturePhoto = Notification.Name("snapziCapturePhoto")
    static let snapziPhotoCaptured = Notification.Name("snapziPhotoCaptured")
}

// MARK: - Preview

struct CameraPreviewRepresentable: UIViewRepresentable {
    @Binding var zoom: CGFloat

    func makeUIView(context: Context) -> CameraPreviewUIView {
        let view = CameraPreviewUIView()
        context.coordinator.attach(to: view)
        return view
    }

    func updateUIView(_ uiView: CameraPreviewUIView, context: Context) {
        context.coordinator.setZoom(zoom)
        context.coordinator.updatePreviewOrientation(for: uiView.previewLayer)
    }

    func makeCoordinator() -> Coordinator { Coordinator() }

    static func dismantleUIView(_ uiView: CameraPreviewUIView, coordinator: Coordinator) {
        coordinator.stop()
    }

    final class Coordinator: NSObject, AVCapturePhotoCaptureDelegate {
        private let session = AVCaptureSession()
        private let output = AVCapturePhotoOutput()
        private var device: AVCaptureDevice?
        private weak var previewView: CameraPreviewUIView?
        private var rotationCoordinator: AVCaptureDevice.RotationCoordinator?

        func attach(to view: CameraPreviewUIView) {
            previewView = view
            guard AVCaptureDevice.authorizationStatus(for: .video) == .authorized
                || AVCaptureDevice.authorizationStatus(for: .video) == .notDetermined
            else { return }

            if AVCaptureDevice.authorizationStatus(for: .video) == .notDetermined {
                AVCaptureDevice.requestAccess(for: .video) { granted in
                    guard granted else { return }
                    DispatchQueue.main.async { self.startSession(on: view) }
                }
                return
            }
            startSession(on: view)
        }

        private func startSession(on view: CameraPreviewUIView) {
            session.beginConfiguration()
            session.sessionPreset = .photo
            guard
                let camera = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .back),
                let input = try? AVCaptureDeviceInput(device: camera),
                session.canAddInput(input),
                session.canAddOutput(output)
            else {
                session.commitConfiguration()
                return
            }
            session.addInput(input)
            session.addOutput(output)
            device = camera
            session.commitConfiguration()

            view.previewLayer.session = session
            view.previewLayer.videoGravity = .resizeAspectFill

            rotationCoordinator = AVCaptureDevice.RotationCoordinator(
                device: camera,
                previewLayer: view.previewLayer
            )
            syncPreviewTransform(on: view.previewLayer)

            UIDevice.current.beginGeneratingDeviceOrientationNotifications()
            NotificationCenter.default.addObserver(
                self,
                selector: #selector(onOrientationChanged),
                name: UIDevice.orientationDidChangeNotification,
                object: nil
            )
            NotificationCenter.default.addObserver(
                self,
                selector: #selector(captureNow),
                name: .snapziCapturePhoto,
                object: nil
            )

            DispatchQueue.global(qos: .userInitiated).async { [weak self] in
                self?.session.startRunning()
            }
        }

        @objc private func onOrientationChanged() {
            guard let layer = previewView?.previewLayer else { return }
            syncPreviewTransform(on: layer)
        }

        func updatePreviewOrientation(for layer: AVCaptureVideoPreviewLayer) {
            syncPreviewTransform(on: layer)
        }

        /// 后置相机：不镜像；旋转用系统 RotationCoordinator，避免上下颠倒/左右反。
        private func syncPreviewTransform(on layer: AVCaptureVideoPreviewLayer) {
            guard let connection = layer.connection else { return }

            if connection.isVideoMirroringSupported {
                connection.automaticallyAdjustsVideoMirroring = false
                connection.isVideoMirrored = false
            }

            guard let rotationCoordinator else { return }
            let angle = rotationCoordinator.videoRotationAngleForHorizonLevelPreview
            if connection.isVideoRotationAngleSupported(angle) {
                connection.videoRotationAngle = angle
            }
        }

        func setZoom(_ factor: CGFloat) {
            guard let device else { return }
            try? device.lockForConfiguration()
            device.videoZoomFactor = min(max(factor, 1), device.activeFormat.videoMaxZoomFactor)
            device.unlockForConfiguration()
        }

        @objc private func captureNow() {
            guard session.isRunning else { return }
            let settings = AVCapturePhotoSettings()
            if let connection = output.connection(with: .video), let rotationCoordinator {
                if connection.isVideoMirroringSupported {
                    connection.automaticallyAdjustsVideoMirroring = false
                    connection.isVideoMirrored = false
                }
                let angle = rotationCoordinator.videoRotationAngleForHorizonLevelCapture
                if connection.isVideoRotationAngleSupported(angle) {
                    connection.videoRotationAngle = angle
                }
            }
            output.capturePhoto(with: settings, delegate: self)
        }

        func photoOutput(_ output: AVCapturePhotoOutput, didFinishProcessingPhoto photo: AVCapturePhoto, error: Error?) {
            guard let data = photo.fileDataRepresentation(), var image = UIImage(data: data) else { return }
            image = image.normalizedUpOrientation()
            DispatchQueue.main.async {
                NotificationCenter.default.post(name: .snapziPhotoCaptured, object: image)
            }
        }

        func stop() {
            NotificationCenter.default.removeObserver(self)
            UIDevice.current.endGeneratingDeviceOrientationNotifications()
            rotationCoordinator = nil
            if session.isRunning {
                session.stopRunning()
            }
        }

        deinit { stop() }
    }
}

final class CameraPreviewUIView: UIView {
    override class var layerClass: AnyClass {
        AVCaptureVideoPreviewLayer.self
    }

    var previewLayer: AVCaptureVideoPreviewLayer {
        layer as! AVCaptureVideoPreviewLayer
    }
}

struct LegacyImagePicker: UIViewControllerRepresentable {
    var onImage: (UIImage) -> Void
    @Environment(\.dismiss) private var dismiss

    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.sourceType = .photoLibrary
        picker.delegate = context.coordinator
        return picker
    }

    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {}

    func makeCoordinator() -> Coordinator { Coordinator(parent: self) }

    final class Coordinator: NSObject, UINavigationControllerDelegate, UIImagePickerControllerDelegate {
        let parent: LegacyImagePicker
        init(parent: LegacyImagePicker) { self.parent = parent }

        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            parent.dismiss()
        }

        func imagePickerController(
            _ picker: UIImagePickerController,
            didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey: Any]
        ) {
            defer { parent.dismiss() }
            if let image = info[.originalImage] as? UIImage {
                parent.onImage(image)
            }
        }
    }
}
