import SwiftUI
import SwiftData

struct CreateAlarmView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    @AppStorage(AlarmSettings.barcodeWarningEnabledKey) private var barcodeWarningEnabled = true

    @State private var time = Date()
    @State private var repeatWeekdays = WeekdaySchedule.allWeekdays
    @State private var missions: [DismissalMission] = []
    @State private var scanningMissionKind: DismissalMission.Kind?
    @State private var showingBarcodeWarning = false

    private var hasBarcodeMission: Bool {
        missions.contains { $0.kind == .barcode }
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
                        attemptSave()
                    }
                    .disabled(missions.isEmpty)
                }
            }
            .alert("Skip Barcode Mission?", isPresented: $showingBarcodeWarning) {
                Button("Wait, I'll add the barcode mission") {}
                Button("I'll get up, don't worry") {
                    saveAlarm()
                }
            } message: {
                Text("Without the barcode mission, you probably won't actually get up when you need to.")
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
                case .shake:
                    EmptyView()
                }
            }
        }
    }

    private func attemptSave() {
        guard !missions.isEmpty else { return }
        if !hasBarcodeMission && barcodeWarningEnabled {
            showingBarcodeWarning = true
            return
        }
        saveAlarm()
    }

    private func saveAlarm() {
        guard !missions.isEmpty else { return }
        let newAlarm = AlarmItem(time: time, missions: missions, repeatWeekdays: repeatWeekdays)
        modelContext.insert(newAlarm)
        AlarmScheduler.shared.scheduleAlarm(for: newAlarm)
        dismiss()
    }
}
