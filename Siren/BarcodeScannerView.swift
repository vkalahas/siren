import AVFoundation
import SwiftUI
import Vision

struct BarcodeScannerView: UIViewRepresentable {
    var onCodeScanned: (String) -> Void

    func makeCoordinator() -> Coordinator {
        Coordinator(onCodeScanned: onCodeScanned)
    }

    func makeUIView(context: Context) -> PreviewView {
        let view = PreviewView()
        view.previewLayer.session = context.coordinator.session
        view.previewLayer.videoGravity = .resizeAspectFill
        context.coordinator.start()
        return view
    }

    func updateUIView(_ uiView: PreviewView, context: Context) {
        context.coordinator.onCodeScanned = onCodeScanned
    }

    static func dismantleUIView(_ uiView: PreviewView, coordinator: Coordinator) {
        coordinator.stop()
    }

    final class PreviewView: UIView {
        override class var layerClass: AnyClass { AVCaptureVideoPreviewLayer.self }

        var previewLayer: AVCaptureVideoPreviewLayer {
            layer as! AVCaptureVideoPreviewLayer
        }

        override init(frame: CGRect) {
            super.init(frame: frame)
            clipsToBounds = true
            backgroundColor = .black
        }

        @available(*, unavailable)
        required init?(coder: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }
    }

    nonisolated final class Coordinator: NSObject, AVCaptureVideoDataOutputSampleBufferDelegate, @unchecked Sendable {
        nonisolated(unsafe) var onCodeScanned: (String) -> Void
        let session = AVCaptureSession()

        private let sessionQueue = DispatchQueue(label: "com.vk.Siren.barcode.session")
        private let visionQueue = DispatchQueue(label: "com.vk.Siren.barcode.vision")
        private let videoOutput = AVCaptureVideoDataOutput()
        private let stateLock = NSLock()
        nonisolated(unsafe) private var hasCommitted = false
        nonisolated(unsafe) private var isProcessing = false
        nonisolated(unsafe) private var shouldRun = false
        nonisolated(unsafe) private var isConfigured = false

        init(onCodeScanned: @escaping (String) -> Void) {
            self.onCodeScanned = onCodeScanned
            super.init()

            // Finish all session configuration before a preview layer can attach.
            // After initialization, this session only starts or stops.
            sessionQueue.sync {
                configureSession()
            }
        }

        func start() {
            stateLock.lock()
            shouldRun = true
            stateLock.unlock()

            sessionQueue.async { [weak self] in
                guard let self, self.wantsToRun, self.isConfigured, !self.session.isRunning else { return }
                self.session.startRunning()
            }
        }

        func stop() {
            stateLock.lock()
            hasCommitted = true
            shouldRun = false
            stateLock.unlock()

            // Wait for any pending start to finish before UIKit tears down the
            // preview layer that references this session.
            sessionQueue.sync {
                guard session.isRunning else { return }
                session.stopRunning()
            }
        }

        private func configureSession() {
            session.beginConfiguration()
            session.sessionPreset = .hd1280x720

            guard let device = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .back),
                  let input = try? AVCaptureDeviceInput(device: device),
                  session.canAddInput(input) else {
                session.commitConfiguration()
                return
            }
            session.addInput(input)

            videoOutput.alwaysDiscardsLateVideoFrames = true
            videoOutput.videoSettings = [
                kCVPixelBufferPixelFormatTypeKey as String: kCVPixelFormatType_420YpCbCr8BiPlanarFullRange
            ]
            videoOutput.setSampleBufferDelegate(self, queue: visionQueue)
            guard session.canAddOutput(videoOutput) else {
                session.commitConfiguration()
                return
            }
            session.addOutput(videoOutput)

            if let connection = videoOutput.connection(with: .video), connection.isVideoRotationAngleSupported(90) {
                connection.videoRotationAngle = 90
            }

            session.commitConfiguration()
            isConfigured = true
        }

        private var wantsToRun: Bool {
            stateLock.lock()
            defer { stateLock.unlock() }
            return shouldRun
        }

        nonisolated func captureOutput(
            _ output: AVCaptureOutput,
            didOutput sampleBuffer: CMSampleBuffer,
            from connection: AVCaptureConnection
        ) {
            stateLock.lock()
            let shouldSkip = hasCommitted || isProcessing
            if !shouldSkip {
                isProcessing = true
            }
            stateLock.unlock()
            guard !shouldSkip else { return }
            guard let pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else {
                finishProcessing()
                return
            }

            Task { [weak self] in
                await self?.recognizeBarcode(in: pixelBuffer)
            }
        }

        private nonisolated func recognizeBarcode(in pixelBuffer: CVPixelBuffer) async {
            defer { finishProcessing() }

            var request = DetectBarcodesRequest()
            request.symbologies = [
                .qr, .ean13, .ean8, .upce, .code128, .code39, .code93, .pdf417, .aztec, .dataMatrix, .itf14
            ]

            let observations: [BarcodeObservation]
            do {
                observations = try await request.perform(on: pixelBuffer, orientation: .right)
            } catch {
                return
            }

            guard let payload = observations
                .compactMap(\.payloadString)
                .first(where: { !$0.isEmpty }) else { return }

            commit(payload)
        }

        private nonisolated func finishProcessing() {
            stateLock.lock()
            isProcessing = false
            stateLock.unlock()
        }

        private nonisolated func commit(_ payload: String) {
            stateLock.lock()
            let alreadyCommitted = hasCommitted
            hasCommitted = true
            stateLock.unlock()
            guard !alreadyCommitted else { return }

            stateLock.lock()
            shouldRun = false
            stateLock.unlock()

            sessionQueue.async { [weak self] in
                guard let self, self.session.isRunning else { return }
                self.session.stopRunning()
            }

            let callback = onCodeScanned
            DispatchQueue.main.async {
                callback(payload)
            }
        }
    }
}

struct BarcodeCaptureView: View {
    var onCodeScanned: (String) -> Void
    @State private var manualCode = ""
    @State private var cameraAuthorized = false
    @State private var didCheckCamera = false

    var body: some View {
        Group {
            if cameraAuthorized {
                BarcodeScannerView(onCodeScanned: onCodeScanned)
            } else if didCheckCamera {
                manualEntryView
            } else {
                Color.black
            }
        }
        .task {
            guard !didCheckCamera else { return }
            cameraAuthorized = await requestCameraIfNeeded()
            didCheckCamera = true
        }
    }

    private var manualEntryView: some View {
        VStack(spacing: 16) {
            Text("Camera barcode scanning isn’t available on this device. Enter the barcode value instead.")
                .multilineTextAlignment(.center)
                .foregroundStyle(.secondary)
            TextField("Barcode", text: $manualCode)
                .textInputAutocapitalization(.never)
                .autocorrectionDisabled()
                .textFieldStyle(.roundedBorder)
            Button("Use Barcode") {
                let value = manualCode.trimmingCharacters(in: .whitespacesAndNewlines)
                guard !value.isEmpty else { return }
                onCodeScanned(value)
            }
            .buttonStyle(.borderedProminent)
            .disabled(manualCode.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
        }
        .padding()
    }

    private func requestCameraIfNeeded() async -> Bool {
        switch AVCaptureDevice.authorizationStatus(for: .video) {
        case .authorized:
            return true
        case .notDetermined:
            return await AVCaptureDevice.requestAccess(for: .video)
        default:
            return false
        }
    }
}
