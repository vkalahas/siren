import ActivityKit
import AlarmKit
import Foundation
import SwiftUI

/// Cached alarm presentation data used to re-fire after a premature system dismiss.
struct AlarmConfigurationSnapshot: Sendable {
    let id: UUID
    let hour: Int
    let minute: Int
    let primaryKind: DismissalMission.Kind
}

@Observable
@MainActor
final class AlarmScheduler {
    static let shared = AlarmScheduler()

    private let manager = AlarmManager.shared

    /// The alarm currently showing the in-app ringing UI. Cleared only after the mission completes or an explicit cancel.
    var alertingAlarmID: UUID?

    private(set) var authorizationState: AlarmManager.AuthorizationState = .notDetermined

    private var configurationSnapshots: [UUID: AlarmConfigurationSnapshot] = [:]
    private var pendingMissionIDs: Set<UUID> = []
    private var authorizedStopIDs: Set<UUID> = []
    private var lastReAlertTimes: [UUID: Date] = [:]
    private var reAlertTasks: [UUID: Task<Void, Never>] = [:]

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

    /// Called when the user interacts with the system alarm UI (Stop or secondary action).
    func handleSystemAlarmInteraction(for id: UUID) {
        beginMissionSession(for: id)
        presentRinging(id: id)
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

            let snapshot = AlarmConfigurationSnapshot(
                id: item.id,
                hour: hour,
                minute: minute,
                primaryKind: primaryKind
            )
            configurationSnapshots[item.id] = snapshot
            authorizedStopIDs.remove(item.id)

            let schedule = Alarm.Schedule.relative(.init(
                time: .init(hour: hour, minute: minute),
                repeats: .never
            ))
            let configuration = makeConfiguration(for: snapshot, schedule: schedule)

            do {
                _ = try await manager.schedule(id: item.id, configuration: configuration)
                NotificationBackupScheduler.shared.scheduleBackup(for: item)
            } catch {
                print("Failed to schedule alarm: \(error)")
            }
        }
    }

    func cancelAlarm(for item: AlarmItem) {
        authorizedStopIDs.insert(item.id)
        endMissionSession(for: item.id)
        configurationSnapshots.removeValue(forKey: item.id)
        NotificationBackupScheduler.shared.cancelBackup(for: item.id)
        removeFromAlarmKit(id: item.id)
    }

    /// Stops the system alarm only after the dismissal mission succeeds.
    func completeMission(for item: AlarmItem) {
        authorizedStopIDs.insert(item.id)
        item.isActive = false
        endMissionSession(for: item.id)
        configurationSnapshots.removeValue(forKey: item.id)
        NotificationBackupScheduler.shared.cancelBackup(for: item.id)
        removeFromAlarmKit(id: item.id, preferStop: true)
    }

    private func beginMissionSession(for id: UUID) {
        pendingMissionIDs.insert(id)
        alertingAlarmID = id
        AlarmRinger.shared.start()
    }

    private func endMissionSession(for id: UUID) {
        pendingMissionIDs.remove(id)
        reAlertTasks[id]?.cancel()
        reAlertTasks.removeValue(forKey: id)
        lastReAlertTimes.removeValue(forKey: id)

        if alertingAlarmID == id {
            alertingAlarmID = nil
        }

        if pendingMissionIDs.isEmpty {
            AlarmRinger.shared.stop()
        }
    }

    private func makeConfiguration(
        for snapshot: AlarmConfigurationSnapshot,
        schedule: Alarm.Schedule
    ) -> AlarmManager.AlarmConfiguration<EmptyAlarmMetadata> {
        let kind = snapshot.primaryKind
        let alert = AlarmPresentation.Alert(
            title: LocalizedStringResource("Wake Up"),
            secondaryButton: AlarmButton(
                text: LocalizedStringResource(stringLiteral: kind.alarmButtonTitle),
                textColor: .white,
                systemImageName: kind.systemImage
            ),
            secondaryButtonBehavior: .custom
        )
        let countdown = AlarmPresentation.Countdown(
            title: LocalizedStringResource("Wake Up"),
            pauseButton: nil
        )
        let presentation = AlarmPresentation(alert: alert, countdown: countdown)
        let attributes = AlarmAttributes<EmptyAlarmMetadata>(
            presentation: presentation,
            metadata: nil,
            tintColor: .red
        )
        let openIntent = OpenAlarmIntent(alarmID: snapshot.id.uuidString)
        let countdownDuration = Alarm.CountdownDuration(
            preAlert: nil,
            postAlert: AlarmEnforcement.reAlertDelay
        )

        return AlarmManager.AlarmConfiguration(
            countdownDuration: countdownDuration,
            schedule: schedule,
            attributes: attributes,
            stopIntent: openIntent,
            secondaryIntent: openIntent,
            sound: .default
        )
    }

    private func scheduleReAlert(for id: UUID) {
        guard pendingMissionIDs.contains(id) else { return }
        guard !authorizedStopIDs.contains(id) else { return }
        guard let snapshot = configurationSnapshots[id] else { return }

        if let lastTime = lastReAlertTimes[id],
           Date().timeIntervalSince(lastTime) < AlarmEnforcement.reAlertDebounce {
            return
        }
        lastReAlertTimes[id] = Date()

        reAlertTasks[id]?.cancel()
        reAlertTasks[id] = Task {
            try? await Task.sleep(for: .seconds(AlarmEnforcement.reAlertDelay))

            guard !Task.isCancelled else { return }
            guard pendingMissionIDs.contains(id), !authorizedStopIDs.contains(id) else { return }

            await requestAuthorization()
            guard manager.authorizationState == .authorized else { return }

            let fireDate = Date().addingTimeInterval(AlarmEnforcement.reAlertDelay)
            let schedule = Alarm.Schedule.fixed(fireDate)
            let configuration = makeConfiguration(for: snapshot, schedule: schedule)

            do {
                _ = try await manager.schedule(id: id, configuration: configuration)
            } catch {
                print("Failed to re-alert alarm: \(error)")
            }

            beginMissionSession(for: id)
            presentRinging(id: id)
        }
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
            try? manager.cancel(id: id)
        }
    }

    private func apply(_ alarms: [Alarm]) {
        let alertingIDs = Set(alarms.filter { $0.state == .alerting }.map(\.id))

        for id in alertingIDs {
            beginMissionSession(for: id)
        }

        let prematurelyStopped = pendingMissionIDs.subtracting(alertingIDs)
        for id in prematurelyStopped where !authorizedStopIDs.contains(id) {
            scheduleReAlert(for: id)
        }
    }
}
