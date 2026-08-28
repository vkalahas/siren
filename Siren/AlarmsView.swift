import SwiftUI
import SwiftData

struct AlarmsView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \AlarmItem.time) private var alarms: [AlarmItem]

    @State private var scheduler = AlarmScheduler.shared
    @State private var showingCreateAlarm = false
    @State private var editingAlarm: AlarmItem?

    var body: some View {
        NavigationStack {
            List {
                ForEach(alarms) { alarm in
                    HStack {
                        Button {
                            editingAlarm = alarm
                        } label: {
                            VStack(alignment: .leading) {
                                Text(alarm.time, format: .dateTime.hour().minute())
                                    .font(.title)
                                    .foregroundStyle(.primary)
                                Text(alarm.missions.summary)
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                        }
                        .buttonStyle(.plain)

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
            .contentMargins(.top, 16, for: .scrollContent)
            .navigationTitle("Alarms")
            .safeAreaInset(edge: .bottom, spacing: 0) {
                Button("Add New Alarm") {
                    showingCreateAlarm = true
                }
                .buttonStyle(.glassProminent)
                .buttonSizing(.flexible)
                .controlSize(.extraLarge)
                .tint(.blue)
                .padding(.top, 12)
                .padding(.horizontal, 20)
                .padding(.bottom, 28)
            }
            .sheet(isPresented: $showingCreateAlarm) {
                CreateAlarmView()
            }
            .sheet(item: $editingAlarm) { alarm in
                EditAlarmView(alarm: alarm)
            }
        }
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
