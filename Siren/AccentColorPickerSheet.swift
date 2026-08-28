import SwiftUI

struct AccentColorPickerSheet: View {
    @Binding var color: Color
    let onSave: () -> Void
    let onCancel: () -> Void

    @State private var hue = 0.0
    @State private var saturation = 1.0
    @State private var brightness = 1.0

    var body: some View {
        NavigationStack {
            VStack(spacing: 20) {
                ColorSpectrumView(hue: $hue, saturation: $saturation, brightness: brightness)
                    .frame(height: 260)
                    .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))

                BrightnessSlider(hue: hue, saturation: saturation, brightness: $brightness)
                    .frame(height: 32)
            }
            .padding()
            .navigationTitle("Accent Color")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel", action: onCancel)
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save", action: onSave)
                }
            }
            .onAppear {
                syncFromColor(color)
            }
            .onChange(of: hue) { _, _ in syncToColor() }
            .onChange(of: saturation) { _, _ in syncToColor() }
            .onChange(of: brightness) { _, _ in syncToColor() }
        }
        .presentationDetents([.medium])
    }

    private func syncFromColor(_ color: Color) {
        let components = color.hsbComponents
        hue = components.hue
        saturation = components.saturation
        brightness = components.brightness
    }

    private func syncToColor() {
        color = Color(hue: hue, saturation: saturation, brightness: brightness)
    }
}

private struct ColorSpectrumView: View {
    @Binding var hue: Double
    @Binding var saturation: Double
    let brightness: Double

    var body: some View {
        GeometryReader { geometry in
            ZStack(alignment: .topLeading) {
                LinearGradient(
                    colors: (0...6).map { step in
                        Color(hue: Double(step) / 6, saturation: 1, brightness: brightness)
                    },
                    startPoint: .leading,
                    endPoint: .trailing
                )

                LinearGradient(
                    colors: [.white, .clear],
                    startPoint: .bottom,
                    endPoint: .top
                )

                Circle()
                    .strokeBorder(.white, lineWidth: 2)
                    .shadow(color: .black.opacity(0.25), radius: 2, y: 1)
                    .frame(width: 26, height: 26)
                    .position(selectorPosition(in: geometry.size))
            }
            .contentShape(Rectangle())
            .gesture(
                DragGesture(minimumDistance: 0)
                    .onChanged { value in
                        updateSelection(at: value.location, in: geometry.size)
                    }
            )
        }
    }

    private func selectorPosition(in size: CGSize) -> CGPoint {
        CGPoint(
            x: hue.clamped(to: 0...1) * size.width,
            y: (1 - saturation.clamped(to: 0...1)) * size.height
        )
    }

    private func updateSelection(at location: CGPoint, in size: CGSize) {
        hue = (location.x / size.width).clamped(to: 0...1)
        saturation = (1 - location.y / size.height).clamped(to: 0...1)
    }
}

private struct BrightnessSlider: View {
    let hue: Double
    let saturation: Double
    @Binding var brightness: Double

    var body: some View {
        GeometryReader { geometry in
            let thumbSize: CGFloat = 28
            let trackWidth = geometry.size.width - thumbSize

            ZStack(alignment: .leading) {
                Capsule()
                    .fill(
                        LinearGradient(
                            colors: [
                                Color(hue: hue, saturation: saturation, brightness: 0),
                                Color(hue: hue, saturation: saturation, brightness: 1),
                            ],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )

                Circle()
                    .fill(Color(hue: hue, saturation: saturation, brightness: brightness))
                    .overlay {
                        Circle()
                            .strokeBorder(.white, lineWidth: 2)
                    }
                    .shadow(color: .black.opacity(0.2), radius: 2, y: 1)
                    .frame(width: thumbSize, height: thumbSize)
                    .offset(x: brightness.clamped(to: 0...1) * trackWidth)
            }
            .contentShape(Rectangle())
            .gesture(
                DragGesture(minimumDistance: 0)
                    .onChanged { value in
                        brightness = (value.location.x / geometry.size.width).clamped(to: 0...1)
                    }
            )
        }
    }
}

private extension Color {
    var hsbComponents: (hue: Double, saturation: Double, brightness: Double) {
        var hue: CGFloat = 0
        var saturation: CGFloat = 0
        var brightness: CGFloat = 0
        var alpha: CGFloat = 0
        UIColor(self).getHue(&hue, saturation: &saturation, brightness: &brightness, alpha: &alpha)
        return (Double(hue), Double(saturation), Double(brightness))
    }

    init(hue: Double, saturation: Double, brightness: Double) {
        self.init(
            uiColor: UIColor(
                hue: hue,
                saturation: saturation,
                brightness: brightness,
                alpha: 1
            )
        )
    }
}

private extension Comparable {
    func clamped(to range: ClosedRange<Self>) -> Self {
        min(max(self, range.lowerBound), range.upperBound)
    }
}
