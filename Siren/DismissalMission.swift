import Foundation

/// A dismissal challenge that must be completed before an alarm can stop.
///
/// Add new cases (math, shake, and so on) here and in the matching setup/challenge views.
/// Do not put mission-specific fields on `AlarmItem`.
nonisolated enum DismissalMission: Codable, Hashable, Sendable {
    case barcode(targetCode: String)

    nonisolated enum Kind: String, Codable, CaseIterable, Identifiable, Sendable {
        case barcode

        var id: String { rawValue }

        var title: String {
            switch self {
            case .barcode: "Barcode"
            }
        }

        var systemImage: String {
            switch self {
            case .barcode: "barcode.viewfinder"
            }
        }

        var challengePrompt: String {
            switch self {
            case .barcode: "Scan the registered barcode to dismiss."
            }
        }

        var alarmButtonTitle: String {
            switch self {
            case .barcode: "Scan"
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
