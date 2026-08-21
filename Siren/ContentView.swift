import SwiftUI
import SwiftData

struct ContentView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \AlarmItem.time) private var alarms: [AlarmItem]

    @State private var scheduler = AlarmScheduler.shared
    @State private var showingCreateAlarm = false

    private var ringingAlarm: AlarmItem? {
        guard let id = scheduler.alertingAlarmID else { return nil }
        return alarms.first { $0.id == id }
    }

    var body: some View {
        NavigationStack {
            List {
                ForEach(alarms) { alarm in
                    HStack {
                        VStack(alignment: .leading) {
                            Text(alarm.time, format: .dateTime.hour().minute())
                                .font(.title)
                            Text(alarm.mission.summary)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }

                        Spacer()

                        Toggle("", isOn: Binding(
                            get: { alarm.isActive },
                            set: { newValue in
                                alarm.isActive = newValue
                                if newValue {
                                    scheduler.scheduleAlarm(for: alarm)
                                } else {
                                    scheduler.cancelAlarm(for: alarm)
                                }
                            }
                        ))
                    }
                }
                .onDelete(perform: deleteAlarms)
            }
            .navigationTitle("Alarms")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        showingCreateAlarm = true
                    } label: {
                        Image(systemName: "plus")
                    }
                }
            }
            .sheet(isPresented: $showingCreateAlarm) {
                CreateAlarmView()
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

    private func deleteAlarms(offsets: IndexSet) {
        withAnimation {
            for index in offsets {
                let alarm = alarms[index]
                scheduler.cancelAlarm(for: alarm)
                modelContext.delete(alarm)
            }
        }
    }
}
