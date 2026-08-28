import SwiftUI

struct BarcodeTargetScanView: View {
    var onCodeScanned: (String) -> Void

    var body: some View {
        VStack(spacing: 20) {
            Text("Point your camera at the barcode you want to register.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 20)

            BarcodeCaptureView(onCodeScanned: onCodeScanned)
                .frame(maxWidth: .infinity)
                .frame(height: 300)
                .clipShape(RoundedRectangle(cornerRadius: 28, style: .continuous))
                .overlay {
                    RoundedRectangle(cornerRadius: 28, style: .continuous)
                        .strokeBorder(Color.secondary.opacity(0.25), lineWidth: 1)
                }
                .padding(.horizontal, 20)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .padding(.top, 24)
    }
}

struct BarcodeMissionChallengeView: View {
    let targetCode: String
    let onComplete: () -> Void

    @State private var mismatchMessage: String?
    @State private var isUsingLostBarcodeFallback = false

    var body: some View {
        if isUsingLostBarcodeFallback {
            lostBarcodeFallbackContent
        } else {
            barcodeScanContent
        }
    }

    private var barcodeScanContent: some View {
        VStack(spacing: 12) {
            if let mismatchMessage {
                Text(mismatchMessage)
                    .font(.subheadline)
                    .foregroundStyle(.orange)
            }

            BarcodeCaptureView { code in
                if code == targetCode {
                    onComplete()
                } else {
                    mismatchMessage = "Wrong barcode. Try again."
                }
            }
            .frame(maxWidth: .infinity, minHeight: 280)
            .clipShape(RoundedRectangle(cornerRadius: 28, style: .continuous))

            Button("I lost my barcode, help!") {
                isUsingLostBarcodeFallback = true
            }
            .buttonStyle(.borderless)
            .foregroundStyle(.secondary)
            .padding(.top, 4)
        }
    }

    private var lostBarcodeFallbackContent: some View {
        VStack(spacing: 12) {
            Text("Can't find your barcode? Shake \(BarcodeMissionDefaults.lostBarcodeFallbackShakes) times to dismiss.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)

            ShakeMissionChallengeView(
                requiredShakes: BarcodeMissionDefaults.lostBarcodeFallbackShakes,
                onComplete: onComplete
            )
        }
    }
}
