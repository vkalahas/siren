import AlarmKit
import SwiftUI
import UIKit

struct AlarmPermissionBanner: View {
    let state: AlarmManager.AuthorizationState

    var body: some View {
        switch state {
        case .denied:
            VStack(alignment: .leading, spacing: 8) {
                Label("Alarms are disabled", systemImage: "alarm.waves.left.and.right.fill")
                    .font(.subheadline.weight(.semibold))

                Text("Siren can’t schedule alarms until you allow alarm access in Settings.")
                    .font(.footnote)
                    .foregroundStyle(.secondary)

                Button("Open Settings") {
                    guard let url = URL(string: UIApplication.openSettingsURLString) else { return }
                    UIApplication.shared.open(url)
                }
                .font(.footnote.weight(.semibold))
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding()
            .background(.orange.opacity(0.15))

        case .notDetermined, .authorized:
            EmptyView()

        @unknown default:
            EmptyView()
        }
    }
}
