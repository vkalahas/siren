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

    private(set) var authorizationState: AlarmManager.AuthorizationState = .notDetermined

    private init() {
        authorizationState = manager.authorizationState
    }

    func requestAuthorization() async {
        refreshAuthorizationState()

        switch authorizationState {
        case .authorized:
            return
        case .denied:
            return
        case .notDetermined:
            do {
                authorizationState = try await manager.requestAuthorization()
            } catch {
                print("Failed to authorize AlarmKit: \(error)")
            }
        @unknown default:
            return
        }
    }

    func startObserving() async {
        refreshAuthorizationState()

        Task {
            for await state in manager.authorizationUpdates {
                authorizationState = state
            }
        }

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

    func refreshAuthorizationState() {
        authorizationState = manager.authorizationState
    }

    func scheduleAlarm(for item: AlarmItem) {
        guard item.isActive else { return }

        Task {
            await requestAuthorization()
            guard manager.authorizationState == .authorized else { return }

            let components = Calendar.current.dateComponents([.hour, .minute], from: item.time)
            guard let hour = components.hour, let minute = components.minute else { return }

            guard let primaryKind = item.missions.first?.kind else { return }

            let kind = primaryKind
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
        removeFromAlarmKit(id: item.id)
    }

    /// Stops the system alarm only after the dismissal mission succeeds.
    func completeMission(for item: AlarmItem) {
        item.isActive = false
        alertingAlarmID = nil
        removeFromAlarmKit(id: item.id, preferStop: true)
    }

    private func removeFromAlarmKit(id: UUID, preferStop: Bool = false) {
        guard manager.authorizationState == .authorized else { return }

        let systemAlarm: Alarm?
        do {
            systemAlarm = try manager.alarms.first { $0.id == id }
        } catch {
            return
        }

        guard let systemAlarm else { return }

        do {
            if preferStop || systemAlarm.state == .alerting {
                try manager.stop(id: id)
            } else {
                try manager.cancel(id: id)
            }
        } catch {
            // The alarm may have already been removed between lookup and mutation.
            try? manager.cancel(id: id)
        }
    }

    private func apply(_ alarms: [Alarm]) {
        if let alerting = alarms.first(where: { $0.state == .alerting }) {
            alertingAlarmID = alerting.id
        }
    }
}
