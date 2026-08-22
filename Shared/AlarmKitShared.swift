import AlarmKit
import Foundation

nonisolated struct EmptyAlarmMetadata: AlarmMetadata {}

/// Seconds between re-alerts when the system alarm is dismissed before the mission completes.
enum AlarmEnforcement {
    static let reAlertDelay: TimeInterval = 1
    static let reAlertDebounce: TimeInterval = 0.4
    /// Short backup burst if the app cannot re-alert via AlarmKit (e.g. after force-quit).
    static let notificationBackupCount = 5
    static let notificationBackupInterval: TimeInterval = 30
}
