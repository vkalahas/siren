import SwiftUI
import SwiftData

struct CreateAlarmView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    @State private var time = Date()
    @State private var mission: DismissalMission?

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    DatePicker("Time", selection: $time, displayedComponents: .hourAndMinute)
                        .datePickerStyle(.wheel)
                        .labelsHidden()
                }

                MissionSetupView(mission: $mission)
            }
            .navigationTitle("New Alarm")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        saveAlarm()
                    }
                    .disabled(mission == nil)
                }
            }
        }
    }

    private func saveAlarm() {
        guard let mission else { return }
        let newAlarm = AlarmItem(time: time, mission: mission)
        modelContext.insert(newAlarm)
        AlarmScheduler.shared.scheduleAlarm(for: newAlarm)
        dismiss()
    }
}
