import AlarmKit
import CryptoKit
import Foundation

nonisolated struct EmptyAlarmMetadata: AlarmMetadata {}

/// Seconds between re-alerts when the system alarm is dismissed before the mission completes.
enum AlarmEnforcement {
    static let reAlertDelay: TimeInterval = 1
    static let reAlertDebounce: TimeInterval = 0.4
    /// Stacked AlarmKit payloads at T+1, T+2, T+3 minutes when the app cannot re-alert (e.g. after force-quit).
    static let stackAlarmCount = 3
    static let stackAlarmInterval: TimeInterval = 60

    /// A deterministic AlarmKit ID for a stacked enforcement alarm derived from the parent alarm.
    static func stackAlarmID(parent: UUID, index: Int) -> UUID {
        precondition(index >= 0 && index < stackAlarmCount)
        let input = Data("siren.stack.\(parent.uuidString).\(index)".utf8)
        let digest = SHA256.hash(data: input)
        var bytes = Array(digest.prefix(16))
        bytes[6] = (bytes[6] & 0x0F) | 0x50
        bytes[8] = (bytes[8] & 0x3F) | 0x80
        return UUID(uuid: (
            bytes[0], bytes[1], bytes[2], bytes[3],
            bytes[4], bytes[5], bytes[6], bytes[7],
            bytes[8], bytes[9], bytes[10], bytes[11],
            bytes[12], bytes[13], bytes[14], bytes[15]
        ))
    }

    /// Resolves a stacked enforcement alarm ID back to its parent alarm ID.
    static func parentAlarmID(fromStackID stackID: UUID, knownParents: [UUID]) -> UUID? {
        for parent in knownParents {
            for index in 0..<stackAlarmCount where stackAlarmID(parent: parent, index: index) == stackID {
                return parent
            }
        }
        return nil
    }
}
