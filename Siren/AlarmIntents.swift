import AlarmKit
import AppIntents

/// Opens Siren so the user can complete the alarm's dismissal mission.
struct OpenAlarmIntent: LiveActivityIntent {
    static var title: LocalizedStringResource = "Complete mission"
    static var description = IntentDescription("Opens Siren to complete the alarm dismissal mission.")
    static var supportedModes: IntentModes { .foreground(.immediate) }

    @Parameter(title: "Alarm ID")
    var alarmID: String

    init(alarmID: String) {
        self.alarmID = alarmID
    }

    init() {
        self.alarmID = ""
    }

    func perform() async throws -> some IntentResult {
        if let id = UUID(uuidString: alarmID) {
            await AlarmScheduler.shared.handleSystemAlarmInteraction(for: id)
        }
        return .result()
    }
}
