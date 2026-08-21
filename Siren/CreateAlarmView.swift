import SwiftUI
import SwiftData

struct CreateAlarmView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    @State private var time = Date()
    @State private var missions: [DismissalMission] = []
    @State private var scanningMissionKind: DismissalMission.Kind?

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    DatePicker("Time", selection: $time, displayedComponents: .hourAndMinute)
                        .datePickerStyle(.wheel)
                        .labelsHidden()
                }

                MissionSetupView(
                    missions: $missions,
                    scanningMissionKind: $scanningMissionKind
                )
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
                    .disabled(missions.isEmpty)
                }
            }
            .navigationDestination(item: $scanningMissionKind) { kind in
                switch kind {
                case .barcode:
                    BarcodeTargetScanView { code in
                        scanningMissionKind = nil
                        var transaction = Transaction()
                        transaction.disablesAnimations = true
                        withTransaction(transaction) {
                            missions.removeAll { $0.kind == .barcode }
                            missions.append(.barcode(targetCode: code))
                        }
                    }
                    .navigationTitle("Scan Target")
                    .navigationBarTitleDisplayMode(.inline)
                case .math, .shake:
                    EmptyView()
                }
            }
        }
    }

    private func saveAlarm() {
        guard !missions.isEmpty else { return }
        let newAlarm = AlarmItem(time: time, missions: missions)
        modelContext.insert(newAlarm)
        AlarmScheduler.shared.scheduleAlarm(for: newAlarm)
        dismiss()
    }
}
