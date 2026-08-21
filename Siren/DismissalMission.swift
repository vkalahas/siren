import Foundation

/// A dismissal challenge that must be completed before an alarm can stop.
///
/// Add new cases (math, shake, and so on) here and in the matching setup/challenge views.
/// Do not put mission-specific fields on `AlarmItem`.
nonisolated enum DismissalMission: Codable, Hashable, Sendable {
    case barcode(targetCode: String)

    nonisolated enum Kind: String, Codable, CaseIterable, Identifiable, Hashable, Sendable {
        case barcode
        case math
        case shake

        var id: String { rawValue }

        var title: String {
            switch self {
            case .barcode: "Barcode"
            case .math: "Math"
            case .shake: "Shake"
            }
        }

        var subtitle: String {
            switch self {
            case .barcode: "Scan a code"
            case .math: "Solve problems"
            case .shake: "Shake to wake"
            }
        }

        var systemImage: String {
            switch self {
            case .barcode: "barcode.viewfinder"
            case .math: "function"
            case .shake: "iphone.radiowaves.left.and.right"
            }
        }

        var isAvailable: Bool {
            switch self {
            case .barcode: true
            case .math, .shake: false
            }
        }

        var challengePrompt: String {
            switch self {
            case .barcode: "Scan the registered barcode to dismiss."
            case .math: "Solve the math problem to dismiss."
            case .shake: "Shake your phone to dismiss."
            }
        }

        var alarmButtonTitle: String {
            switch self {
            case .barcode: "Scan"
            case .math: "Solve"
            case .shake: "Shake"
            }
        }
    }

    var kind: Kind {
        switch self {
        case .barcode: .barcode
        }
    }

    var summary: String {
        switch self {
        case .barcode(let targetCode):
            "Barcode: \(targetCode)"
        }
    }
}
