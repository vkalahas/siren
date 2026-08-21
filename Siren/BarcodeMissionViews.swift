import SwiftUI

struct BarcodeMissionSetupRows: View {
    @Binding var mission: DismissalMission?
    @State private var isScanning = false

    private var targetCode: String? {
        if case .barcode(let code) = mission { return code }
        return nil
    }

    var body: some View {
        Group {
            if let targetCode {
                Text("Target Barcode: \(targetCode)")
                    .foregroundStyle(.green)
                Button("Rescan Barcode") {
                    isScanning = true
                }
            } else {
                Button("Scan Target Barcode") {
                    isScanning = true
                }
            }
        }
        .sheet(isPresented: $isScanning) {
            NavigationStack {
                BarcodeCaptureView { code in
                    mission = .barcode(targetCode: code)
                    isScanning = false
                }
                .navigationTitle("Scan Target")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .cancellationAction) {
                        Button("Cancel") { isScanning = false }
                    }
                }
            }
        }
    }
}

struct BarcodeMissionChallengeView: View {
    let targetCode: String
    let onComplete: () -> Void

    @State private var mismatchMessage: String?

    var body: some View {
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
            .clipShape(RoundedRectangle(cornerRadius: 12))
        }
    }
}
