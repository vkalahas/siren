import SwiftUI

struct SettingsView: View {
    @AppStorage(DisplaySettings.leftHandedKey) private var isLeftHanded = false
    @AppStorage(AccentColorSettings.usesCustomKey) private var usesCustomAccentColor = false
    @AppStorage(AccentColorSettings.redKey) private var accentColorRed = 0.0
    @AppStorage(AccentColorSettings.greenKey) private var accentColorGreen = 0.0
    @AppStorage(AccentColorSettings.blueKey) private var accentColorBlue = 0.0

    @State private var showingAccentColorPicker = false
    @State private var draftAccentColor = AccentColorSettings.systemAccent

    var body: some View {
        NavigationStack {
            Form {
                Section("Appearance") {
                    Toggle("Left-Handed Mode", isOn: $isLeftHanded)

                    HStack {
                        Text("Accent Color")

                        Spacer()

                        HStack(spacing: 10) {
                            Button(action: resetAccentColor) {
                                Image(systemName: "arrow.counterclockwise")
                                    .font(.body.weight(.medium))
                                    .foregroundStyle(usesCustomAccentColor ? .primary : .tertiary)
                                    .frame(width: 28, height: 28)
                                    .background(Circle().fill(Color(.systemGray5)))
                            }
                            .buttonStyle(.plain)
                            .disabled(!usesCustomAccentColor)
                            .accessibilityLabel("Reset to system accent color")

                            Button(action: {
                                draftAccentColor = currentAccentColor
                                showingAccentColorPicker = true
                            }) {
                                Circle()
                                    .fill(currentAccentColor)
                                    .frame(width: 28, height: 28)
                                    .overlay {
                                        Circle()
                                            .strokeBorder(.primary.opacity(0.15), lineWidth: 1)
                                    }
                            }
                            .buttonStyle(.plain)
                            .accessibilityLabel("Choose accent color")
                        }
                    }
                }

                Section("Open Source") {
                    Link(destination: URL(string: "https://github.com/vkalahas/siren")!) {
                        HStack {
                            Text("GitHub")
                            Spacer()
                            Image(systemName: "arrow.up.right.square")
                                .foregroundStyle(.secondary)
                        }
                    }
                }
            }
            .contentMargins(.top, 16, for: .scrollContent)
            .navigationTitle("Settings")
            .sheet(isPresented: $showingAccentColorPicker) {
                AccentColorPickerSheet(
                    color: $draftAccentColor,
                    onSave: {
                        applyAccentColor(draftAccentColor)
                        showingAccentColorPicker = false
                    },
                    onCancel: {
                        showingAccentColorPicker = false
                    }
                )
            }
        }
    }

    private var currentAccentColor: Color {
        AccentColorSettings.resolvedColor(
            usesCustom: usesCustomAccentColor,
            red: accentColorRed,
            green: accentColorGreen,
            blue: accentColorBlue
        )
    }

    private func applyAccentColor(_ color: Color) {
        let rgb = AccentColorSettings.storeRGB(from: color)
        accentColorRed = rgb.red
        accentColorGreen = rgb.green
        accentColorBlue = rgb.blue
        usesCustomAccentColor = true
    }

    private func resetAccentColor() {
        usesCustomAccentColor = false
    }
}
