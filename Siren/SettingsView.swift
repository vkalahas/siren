import SwiftUI

struct SettingsView: View {
    @AppStorage("advancedModeEnabled") private var advancedModeEnabled = false

    var body: some View {
        NavigationStack {
            Form {
                Toggle("Advanced Mode", isOn: $advancedModeEnabled)
            }
            .contentMargins(.top, 16, for: .scrollContent)
            .navigationTitle("Settings")
        }
    }
}
