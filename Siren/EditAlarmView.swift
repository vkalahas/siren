import SwiftUI
import SwiftData

struct EditAlarmView: View {
    @Bindable var alarm: AlarmItem
    @Environment(\.dismiss) private var dismiss

    @State private var time: Date
    @State private var repeatWeekdays: [Int]

    init(alarm: AlarmItem) {
        self.alarm = alarm
        _time = State(initialValue: alarm.time)
        _repeatWeekdays = State(initialValue: alarm.repeatWeekdays)
    }

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    DatePicker("Time", selection: $time, displayedComponents: .hourAndMinute)
                        .datePickerStyle(.wheel)
                        .labelsHidden()
                }

                RepeatScheduleView(repeatWeekdays: $repeatWeekdays)

                Section("Dismissal Missions") {
                    Text(alarm.missions.summary)
                        .foregroundStyle(.secondary)
                }
            }
            .navigationTitle("Edit Alarm")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        saveChanges()
                    }
                }
            }
        }
    }

    private func saveChanges() {
        let wasActive = alarm.isActive

        if wasActive {
            AlarmScheduler.shared.cancelAlarm(for: alarm)
        }

        alarm.clearSkipState()
        alarm.time = time
        alarm.repeatWeekdays = repeatWeekdays

        if wasActive {
            AlarmScheduler.shared.scheduleAlarm(for: alarm)
        }

        dismiss()
    }
}
