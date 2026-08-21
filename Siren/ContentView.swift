import SwiftUI
import SwiftData

struct ContentView: View {
    @Environment(\.scenePhase) private var scenePhase
    @Query private var alarms: [AlarmItem]

    @State private var scheduler = AlarmScheduler.shared

    private var ringingAlarm: AlarmItem? {
        guard let id = scheduler.alertingAlarmID else { return nil }
        return alarms.first { $0.id == id }
    }

    var body: some View {
        TabView {
            Tab("Alarms", systemImage: "alarm") {
                AlarmsView()
            }

            Tab("Settings", systemImage: "gearshape") {
                SettingsView()
            }
        }
        .safeAreaInset(edge: .top, spacing: 0) {
            AlarmPermissionBanner(state: scheduler.authorizationState)
        }
        .fullScreenCover(isPresented: ringingCoverBinding) {
            if let alarm = ringingAlarm {
                RingingView(alarm: alarm)
            }
        }
        .task {
            await scheduler.requestAuthorization()
            await scheduler.startObserving()
        }
        .onChange(of: scenePhase) { _, newPhase in
            switch newPhase {
            case .active:
                scheduler.refreshAuthorizationState()
                if scheduler.alertingAlarmID != nil {
                    AlarmRinger.shared.start()
                }
            case .background, .inactive:
                if scheduler.alertingAlarmID != nil {
                    AlarmRinger.shared.start()
                }
            @unknown default:
                break
            }
        }
    }

    private var ringingCoverBinding: Binding<Bool> {
        Binding(
            get: { ringingAlarm != nil },
            set: { presented in
                if presented { return }
                // Ringing UI stays up until the mission is completed (or the alarm is deleted/toggled off).
            }
        )
    }
}
