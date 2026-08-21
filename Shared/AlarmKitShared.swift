import AlarmKit
import Foundation

nonisolated struct EmptyAlarmMetadata: AlarmMetadata {}

/// Seconds between re-alerts when the system alarm is dismissed before the mission completes.
enum AlarmEnforcement {
    static let reAlertDelay: TimeInterval = 1
    static let reAlertDebounce: TimeInterval = 0.4
    static let notificationBurstCount = 30
    static let notificationBurstInterval: TimeInterval = 2
}
