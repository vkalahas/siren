import ActivityKit
import AlarmKit
import Foundation
import SwiftUI

@Observable
@MainActor
final class AlarmScheduler {
    static let shared = AlarmScheduler()

    private let manager = AlarmManager.shared

    /// The alarm currently showing the in-app ringing UI. Cleared only after the mission completes or an explicit cancel.
    var alertingAlarmID: UUID?

    private init() {}

    func requestAuthorization() async {
        switch manager.authorizationState {
        case .authorized:
            return
        case .denied:
            return
        case .notDetermined:
            do {
                _ = try await manager.requestAuthorization()
            } catch {
                print("Failed to authorize AlarmKit: \(error)")
            }
        @unknown default:
            return
        }
    }

    func startObserving() async {
        do {
            apply(try manager.alarms)
        } catch {
            print("Failed to load AlarmKit alarms: \(error)")
        }

        for await updatedAlarms in manager.alarmUpdates {
            apply(updatedAlarms)
        }
    }

    func presentRinging(id: UUID) {
        alertingAlarmID = id
    }

    func scheduleAlarm(for item: AlarmItem) {
        guard item.isActive else { return }

        Task {
            await requestAuthorization()
            guard manager.authorizationState == .authorized else { return }

            let components = Calendar.current.dateComponents([.hour, .minute], from: item.time)
            guard let hour = components.hour, let minute = components.minute else { return }

            let kind = item.mission.kind
            let alert = AlarmPresentation.Alert(
                title: LocalizedStringResource("Wake Up"),
                secondaryButton: AlarmButton(
                    text: LocalizedStringResource(stringLiteral: kind.alarmButtonTitle),
                    textColor: .white,
                    systemImageName: kind.systemImage
                ),
                secondaryButtonBehavior: .custom
            )
            let attributes = AlarmAttributes<EmptyAlarmMetadata>(
                presentation: AlarmPresentation(alert: alert),
                metadata: nil,
                tintColor: .red
            )
            let openIntent = OpenAlarmIntent(alarmID: item.id.uuidString)
            let configuration = AlarmManager.AlarmConfiguration.alarm(
                schedule: .relative(.init(
                    time: .init(hour: hour, minute: minute),
                    repeats: .never
                )),
                attributes: attributes,
                stopIntent: openIntent,
                secondaryIntent: openIntent,
                sound: .default
            )

            do {
                _ = try await manager.schedule(id: item.id, configuration: configuration)
            } catch {
                print("Failed to schedule alarm: \(error)")
            }
        }
    }

    func cancelAlarm(for item: AlarmItem) {
        if alertingAlarmID == item.id {
            alertingAlarmID = nil
        }
        do {
            try manager.cancel(id: item.id)
        } catch {
            print("Failed to cancel alarm: \(error)")
        }
    }

    /// Stops the system alarm only after the dismissal mission succeeds.
    func completeMission(for item: AlarmItem) {
        item.isActive = false
        alertingAlarmID = nil
        do {
            try manager.stop(id: item.id)
        } catch {
            do {
                try manager.cancel(id: item.id)
            } catch {
                print("Failed to stop alarm: \(error)")
            }
        }
    }

    private func apply(_ alarms: [Alarm]) {
        if let alerting = alarms.first(where: { $0.state == .alerting }) {
            alertingAlarmID = alerting.id
        }
    }
}
