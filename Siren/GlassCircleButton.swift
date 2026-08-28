import SwiftUI

struct GlassCircleButton: View {
    var icon: String
    var size: CGFloat = 44
    var iconSize: CGFloat = 18
    var backgroundColor: Color = .accentColor
    var foregroundColor: Color = .white
    var usesClearGlass: Bool = false
    var action: () -> Void

    var body: some View {
        Button(action: action) {
            Image(systemName: icon)
                .font(.system(size: iconSize))
                .foregroundStyle(foregroundColor)
                .frame(width: size, height: size)
                .background(Circle().fill(.clear))
                .glassEffect(
                    usesClearGlass
                        ? .clear.tint(backgroundColor).interactive()
                        : .regular.tint(backgroundColor).interactive(),
                    in: .circle
                )
                .contentShape(Circle())
        }
        .buttonStyle(.plain)
    }
}
