import SwiftUI

enum AccentColorSettings {
    static let usesCustomKey = "usesCustomAccentColor"
    static let redKey = "accentColorRed"
    static let greenKey = "accentColorGreen"
    static let blueKey = "accentColorBlue"

    static var systemAccent: Color {
        Color(uiColor: .systemBlue)
    }

    static func color(red: Double, green: Double, blue: Double) -> Color {
        Color(red: red, green: green, blue: blue)
    }

    static func resolvedColor(
        usesCustom: Bool,
        red: Double,
        green: Double,
        blue: Double
    ) -> Color {
        if usesCustom {
            return color(red: red, green: green, blue: blue)
        }
        return systemAccent
    }

    static func storeRGB(from color: Color) -> (red: Double, green: Double, blue: Double) {
        var red: CGFloat = 0
        var green: CGFloat = 0
        var blue: CGFloat = 0
        var alpha: CGFloat = 0
        UIColor(color).getRed(&red, green: &green, blue: &blue, alpha: &alpha)
        return (Double(red), Double(green), Double(blue))
    }
}

struct AccentColorModifier: ViewModifier {
    @AppStorage(AccentColorSettings.usesCustomKey) private var usesCustomAccentColor = false
    @AppStorage(AccentColorSettings.redKey) private var accentColorRed = 0.0
    @AppStorage(AccentColorSettings.greenKey) private var accentColorGreen = 0.0
    @AppStorage(AccentColorSettings.blueKey) private var accentColorBlue = 0.0

    func body(content: Content) -> some View {
        content.tint(resolvedAccentColor)
    }

    private var resolvedAccentColor: Color {
        AccentColorSettings.resolvedColor(
            usesCustom: usesCustomAccentColor,
            red: accentColorRed,
            green: accentColorGreen,
            blue: accentColorBlue
        )
    }
}

extension View {
    func appAccentColor() -> some View {
        modifier(AccentColorModifier())
    }
}
