import UserNotifications

final class NotificationResponseHandler: NSObject, UNUserNotificationCenterDelegate {
    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification,
        withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void
    ) {
        let identifier = notification.request.identifier
        Task { @MainActor in
            if let alarmID = NotificationBackupScheduler.shared.alarmID(from: identifier) {
                AlarmScheduler.shared.handleSystemAlarmInteraction(for: alarmID)
            }
        }
        completionHandler([.sound, .banner, .list])
    }

    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        didReceive response: UNNotificationResponse,
        withCompletionHandler completionHandler: @escaping () -> Void
    ) {
        let identifier = response.notification.request.identifier
        Task { @MainActor in
            if let alarmID = NotificationBackupScheduler.shared.alarmID(from: identifier) {
                AlarmScheduler.shared.handleSystemAlarmInteraction(for: alarmID)
            }
            completionHandler()
        }
    }
}
