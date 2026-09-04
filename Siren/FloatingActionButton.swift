import SwiftUI

struct FloatingActionButton: View {
    @AppStorage(DisplaySettings.leftHandedKey) private var isLeftHanded = false

    var icon: String = "plus"
    var backgroundColor: Color = .accentColor
    var foregroundColor: Color = .white
    var action: () -> Void

    var body: some View {
        GlassCircleButton(
            icon: icon,
            size: 60,
            iconSize: 24,
            backgroundColor: backgroundColor,
            foregroundColor: foregroundColor,
            action: action
        )
        .shadow(color: .black.opacity(0.3), radius: 5, x: isLeftHanded ? -3 : 3, y: 3)
        .padding()
        .padding(isLeftHanded ? .leading : .trailing)
    }
}
