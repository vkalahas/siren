import SwiftUI
import VisionKit

struct BarcodeScannerView: UIViewControllerRepresentable {
    var onCodeScanned: (String) -> Void

    func makeCoordinator() -> Coordinator {
        Coordinator(onCodeScanned: onCodeScanned)
    }

    func makeUIViewController(context: Context) -> DataScannerViewController {
        let scanner = DataScannerViewController(
            recognizedDataTypes: [.barcode()],
            qualityLevel: .fast,
            recognizesMultipleItems: false,
            isHighFrameRateTrackingEnabled: false,
            isHighlightingEnabled: true
        )
        scanner.delegate = context.coordinator
        return scanner
    }

    func updateUIViewController(_ uiViewController: DataScannerViewController, context: Context) {
        context.coordinator.onCodeScanned = onCodeScanned
        guard DataScannerViewController.isSupported, DataScannerViewController.isAvailable else { return }
        if !uiViewController.isScanning {
            try? uiViewController.startScanning()
        }
    }

    static func dismantleUIViewController(_ uiViewController: DataScannerViewController, coordinator: Coordinator) {
        if uiViewController.isScanning {
            uiViewController.stopScanning()
        }
    }

    final class Coordinator: NSObject, DataScannerViewControllerDelegate {
        var onCodeScanned: (String) -> Void

        init(onCodeScanned: @escaping (String) -> Void) {
            self.onCodeScanned = onCodeScanned
        }

        func dataScanner(_ dataScanner: DataScannerViewController, didAdd addedItems: [RecognizedItem], allItems: [RecognizedItem]) {
            handle(addedItems)
        }

        func dataScanner(_ dataScanner: DataScannerViewController, didTapOn item: RecognizedItem) {
            handle([item])
        }

        private func handle(_ items: [RecognizedItem]) {
            guard let item = items.first, case .barcode(let barcode) = item,
                  let payload = barcode.payloadStringValue, !payload.isEmpty else { return }
            onCodeScanned(payload)
        }
    }
}

struct BarcodeCaptureView: View {
    var onCodeScanned: (String) -> Void
    @State private var manualCode = ""

    private var scannerAvailable: Bool {
        DataScannerViewController.isSupported && DataScannerViewController.isAvailable
    }

    var body: some View {
        if scannerAvailable {
            BarcodeScannerView(onCodeScanned: onCodeScanned)
        } else {
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
    }
}
