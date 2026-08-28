import SwiftUI

public struct GlassCircleButton: View {
    private let icon: String
    private let size: CGFloat
    private let iconSize: CGFloat
    private let action: () -> Void

    @State private var isPressed = false

    public init(icon: String, size: CGFloat, iconSize: CGFloat, action: @escaping () -> Void) {
        self.icon = icon
        self.size = size
        self.iconSize = iconSize
        self.action = action
    }

    public var body: some View {
        Button(action: action) {
            Image(systemName: icon)
                .font(.system(size: iconSize, weight: .semibold))
                .foregroundStyle(.primary)
                .frame(width: size, height: size)
                .background(.ultraThinMaterial)
                .clipShape(Circle())
                .overlay(
                    Circle()
                        .stroke(Color.primary.opacity(0.15), lineWidth: 1)
                )
                .shadow(color: Color.primary.opacity(0.1), radius: 3, x: 0, y: 2)
                .scaleEffect(isPressed ? 0.95 : 1)
                .contentShape(Circle())
                .animation(.spring(duration: 0.2), value: isPressed)
                .onLongPressGesture(minimumDuration: 0, maximumDistance: 50, pressing: { pressing in
                    isPressed = pressing
                }, perform: {})
        }
        .buttonStyle(.plain)
        .accessibilityAddTraits(.isButton)
    }
}

#Preview {
    VStack(spacing: 30) {
        GlassCircleButton(icon: "heart.fill", size: 60, iconSize: 28) {}
        GlassCircleButton(icon: "star.fill", size: 80, iconSize: 36) {}
    }
    .padding()
    .previewLayout(.sizeThatFits)
    .background {
        Color(.systemBackground)
            .ignoresSafeArea()
    }
    .preferredColorScheme(.light)
}

#Preview {
    VStack(spacing: 30) {
        GlassCircleButton(icon: "heart.fill", size: 60, iconSize: 28) {}
        GlassCircleButton(icon: "star.fill", size: 80, iconSize: 36) {}
    }
    .padding()
    .previewLayout(.sizeThatFits)
    .background {
        Color(.systemBackground)
            .ignoresSafeArea()
    }
    .preferredColorScheme(.dark)
}
