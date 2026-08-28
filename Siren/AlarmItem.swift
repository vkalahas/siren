import Foundation
import SwiftData

@Model
final class AlarmItem {
    @Attribute(.unique) var id: UUID
    var time: Date
    var isActive: Bool
    var missions: [DismissalMission]
    var isSkippedOnce: Bool = false
    var skippedOccurrenceDate: Date?

    init(id: UUID = UUID(), time: Date, isActive: Bool = true, missions: [DismissalMission]) {
        self.id = id
        self.time = time
        self.isActive = isActive
        self.missions = missions
    }

    var showsStrikethroughTime: Bool {
        !isActive || isSkippedOnce
    }

    func clearSkipState() {
        isSkippedOnce = false
        skippedOccurrenceDate = nil
    }

    func nextOccurrence(from date: Date = .now, calendar: Calendar = .current) -> Date? {
        let timeComponents = calendar.dateComponents([.hour, .minute], from: time)
        guard let hour = timeComponents.hour, let minute = timeComponents.minute else { return nil }

        var occurrenceComponents = calendar.dateComponents([.year, .month, .day], from: date)
        occurrenceComponents.hour = hour
        occurrenceComponents.minute = minute
        occurrenceComponents.second = 0

        guard let todayOccurrence = calendar.date(from: occurrenceComponents) else { return nil }

        if todayOccurrence > date {
            return todayOccurrence
        }

        return calendar.date(byAdding: .day, value: 1, to: todayOccurrence)
    }

    func rescheduleDateAfterSkip(from date: Date = .now, calendar: Calendar = .current) -> Date? {
        guard let nextOccurrence = nextOccurrence(from: date, calendar: calendar) else { return nil }
        return calendar.date(byAdding: .day, value: 1, to: nextOccurrence)
    }
}

extension Array where Element == DismissalMission {
    var summary: String {
        map(\.summary).joined(separator: " → ")
    }

    func selectionOrder(for kind: DismissalMission.Kind) -> Int? {
        guard let index = firstIndex(where: { $0.kind == kind }) else { return nil }
        return index + 1
    }
}
