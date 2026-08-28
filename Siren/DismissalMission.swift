import Foundation

/// A dismissal challenge that must be completed before an alarm can stop.
///
/// Add new cases here and in the matching setup/challenge views.
/// Do not put mission-specific fields on `AlarmItem`.
nonisolated enum DismissalMission: Codable, Hashable, Sendable {
    case barcode(targetCode: String)
    case shake(requiredShakes: Int)

    nonisolated enum Kind: String, Codable, CaseIterable, Identifiable, Hashable, Sendable {
        case barcode
        case shake

        var id: String { rawValue }

        var title: String {
            switch self {
            case .barcode: "Barcode"
            case .shake: "Shake"
            }
        }

        var subtitle: String {
            switch self {
            case .barcode: "Scan a code"
            case .shake: "Shake to wake"
            }
        }

        var systemImage: String {
            switch self {
            case .barcode: "barcode.viewfinder"
            case .shake: "iphone.radiowaves.left.and.right"
            }
        }

        var isAvailable: Bool {
            switch self {
            case .barcode, .shake: true
            }
        }

        var challengePrompt: String {
            switch self {
            case .barcode: "Scan the registered barcode to dismiss."
            case .shake: "Shake your phone to dismiss."
            }
        }

        var alarmButtonTitle: String {
            switch self {
            case .barcode: "Scan"
            case .shake: "Shake"
            }
        }
    }

    var kind: Kind {
        switch self {
        case .barcode: .barcode
        case .shake: .shake
        }
    }

    var summary: String {
        switch self {
        case .barcode(let targetCode):
            return "Barcode: \(targetCode)"
        case .shake(let requiredShakes):
            let count = max(1, requiredShakes)
            return "Shake: \(count) \(count == 1 ? "shake" : "shakes")"
        }
    }
}

enum ShakeMissionDefaults {
    static let requiredShakes = 15
}

enum BarcodeMissionDefaults {
    static let lostBarcodeFallbackShakes = 500
}
