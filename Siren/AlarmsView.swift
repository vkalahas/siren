import SwiftUI
import SwiftData

struct AlarmsView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \AlarmItem.time) private var alarms: [AlarmItem]
    @AppStorage(DisplaySettings.leftHandedKey) private var isLeftHanded = false

    @State private var scheduler = AlarmScheduler.shared
    @State private var showingCreateAlarm = false
    @State private var editingAlarm: AlarmItem?
    @State private var alarmPendingSkip: AlarmItem?
    @State private var alarmPendingUnskip: AlarmItem?

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
                                    .strikethrough(alarm.showsStrikethroughTime)
                                VStack(alignment: .leading, spacing: 2) {
                                    ForEach(alarm.missions, id: \.self) { mission in
                                        Text("\(mission.summary)")
                                            .font(.caption)
                                            .foregroundStyle(.secondary)
                                    }
                                }
                            }
                        }
                        .buttonStyle(.plain)

                        Spacer()

                        HStack(spacing: 12) {
                            if alarm.isActive {
                                GlassCircleButton(
                                    icon: "forward.fill",
                                    size: 36,
                                    iconSize: 14,
                                    backgroundColor: alarm.isSkippedOnce ? .red : .accentColor,
                                    action: {
                                        if alarm.isSkippedOnce {
                                            alarmPendingUnskip = alarm
                                        } else {
                                            alarmPendingSkip = alarm
                                        }
                                    }
                                )
                                .accessibilityLabel(alarm.isSkippedOnce ? "Unskip" : "Skip Once")
                            }

                            Toggle(isOn: Binding(
                                get: { alarm.isActive },
                                set: { newValue in
                                    alarm.isActive = newValue
                                    if newValue {
                                        alarm.clearSkipState()
                                        scheduler.scheduleAlarm(for: alarm)
                                    } else {
                                        scheduler.cancelAlarm(for: alarm)
                                    }
                                }
                            )) {
                                EmptyView()
                            }
                            .labelsHidden()
                        }
                        .fixedSize()
                    }
                }
                .onDelete(perform: deleteAlarms)
            }
            .contentMargins(.top, 16, for: .scrollContent)
            .safeAreaPadding(.bottom, 80)
            .navigationTitle("Alarms")
            .overlay(alignment: isLeftHanded ? .bottomLeading : .bottomTrailing) {
                FloatingActionButton {
                    showingCreateAlarm = true
                }
            }
            .sheet(isPresented: $showingCreateAlarm) {
                CreateAlarmView()
            }
            .sheet(item: $editingAlarm) { alarm in
                EditAlarmView(alarm: alarm)
            }
            .alert(
                "Skip Alarm Once?",
                isPresented: Binding(
                    get: { alarmPendingSkip != nil },
                    set: { if !$0 { alarmPendingSkip = nil } }
                )
            ) {
                Button("Skip Once") {
                    if let alarm = alarmPendingSkip {
                        scheduler.skipAlarmOnce(for: alarm)
                    }
                    alarmPendingSkip = nil
                }
                Button("Cancel", role: .cancel) {
                    alarmPendingSkip = nil
                }
            } message: {
                Text("This alarm won't ring at its next scheduled time.")
            }
            .alert(
                "Unskip Alarm?",
                isPresented: Binding(
                    get: { alarmPendingUnskip != nil },
                    set: { if !$0 { alarmPendingUnskip = nil } }
                )
            ) {
                Button("Unskip") {
                    if let alarm = alarmPendingUnskip {
                        scheduler.unskipAlarm(for: alarm)
                    }
                    alarmPendingUnskip = nil
                }
                Button("Cancel", role: .cancel) {
                    alarmPendingUnskip = nil
                }
            } message: {
                Text("This alarm will ring at its next scheduled time.")
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
