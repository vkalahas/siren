import SwiftUI

struct FloatingActionButton: View {
    var icon: String = "plus"
    var backgroundColor: Color = .accentColor
    var foregroundColor: Color = .white
    var action: () -> Void

    var body: some View {
        Button(action: action) {
            Image(systemName: icon)
                .font(.system(size: 24))
                .foregroundStyle(foregroundColor)
                .frame(width: 60, height: 60)
                .background(Circle().fill(.clear))
                .glassEffect(.regular.tint(backgroundColor).interactive(), in: .circle)
                .shadow(color: .black.opacity(0.3), radius: 5, x: 3, y: 3)
                .contentShape(Circle())
        }
        .padding()
        .padding(.trailing)
    }
}
