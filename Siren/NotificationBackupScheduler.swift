import Foundation
import UserNotifications

/// Staggered local notifications that keep firing until the mission is completed or the alarm is cancelled.
@MainActor
final class NotificationBackupScheduler {
    static let shared = NotificationBackupScheduler()

    private init() {}

    func requestAuthorizationIfNeeded() async {
        let center = UNUserNotificationCenter.current()
        let settings = await center.notificationSettings()
        guard settings.authorizationStatus == .notDetermined else { return }
        _ = try? await center.requestAuthorization(options: [.alert, .sound, .badge])
    }

    func scheduleBackup(for item: AlarmItem) {
        Task {
            await requestAuthorizationIfNeeded()
            await scheduleBackupNotifications(for: item)
        }
    }

    func cancelBackup(for id: UUID) {
        let center = UNUserNotificationCenter.current()
        center.removePendingNotificationRequests(withIdentifiers: notificationIDs(for: id))
        center.removeDeliveredNotifications(withIdentifiers: notificationIDs(for: id))
    }

    func alarmID(from notificationIdentifier: String) -> UUID? {
        let parts = notificationIdentifier.split(separator: ".")
        guard parts.count >= 3, parts[0] == "siren", parts[1] == "backup" else { return nil }
        return UUID(uuidString: String(parts[2]))
    }

    private func scheduleBackupNotifications(for item: AlarmItem) async {
        let center = UNUserNotificationCenter.current()
        let identifiers = notificationIDs(for: item.id)
        center.removePendingNotificationRequests(withIdentifiers: identifiers)

        let content = UNMutableNotificationContent()
        content.title = "Siren"
        content.body = "Complete your mission to dismiss the alarm."
        content.sound = .default
        content.interruptionLevel = .timeSensitive

        for index in 0..<AlarmEnforcement.notificationBurstCount {
            let offsetSeconds = index * Int(AlarmEnforcement.notificationBurstInterval)
            guard let fireDate = Calendar.current.date(
                byAdding: .second,
                value: offsetSeconds,
                to: item.time
            ) else { continue }

            let components = Calendar.current.dateComponents(
                [.year, .month, .day, .hour, .minute, .second],
                from: fireDate
            )

            let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: false)
            let request = UNNotificationRequest(
                identifier: identifiers[index],
                content: content,
                trigger: trigger
            )

            try? await center.add(request)
        }
    }

    private func notificationIDs(for alarmID: UUID) -> [String] {
        (0..<AlarmEnforcement.notificationBurstCount).map { index in
            "siren.backup.\(alarmID.uuidString).\(index)"
        }
    }
}
