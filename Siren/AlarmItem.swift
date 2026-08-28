import Foundation
import SwiftData

@Model
final class AlarmItem {
    @Attribute(.unique) var id: UUID
    var time: Date
    var isActive: Bool
    var missions: [DismissalMission]
    /// Calendar weekday values (1 = Sunday … 7 = Saturday). Empty = one-shot.
    var repeatWeekdays: [Int] = WeekdaySchedule.allWeekdays
    var isSkippedOnce: Bool = false
    var skippedOccurrenceDate: Date?

    init(
        id: UUID = UUID(),
        time: Date,
        isActive: Bool = true,
        missions: [DismissalMission],
        repeatWeekdays: [Int] = WeekdaySchedule.allWeekdays
    ) {
        self.id = id
        self.time = time
        self.isActive = isActive
        self.missions = missions
        self.repeatWeekdays = repeatWeekdays
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

        let repeatSet = Set(repeatWeekdays)

        for dayOffset in 0...7 {
            guard let baseDay = calendar.date(byAdding: .day, value: dayOffset, to: date) else { continue }

            var occurrenceComponents = calendar.dateComponents([.year, .month, .day], from: baseDay)
            occurrenceComponents.hour = hour
            occurrenceComponents.minute = minute
            occurrenceComponents.second = 0

            guard let occurrence = calendar.date(from: occurrenceComponents) else { continue }
            guard occurrence > date else { continue }

            if repeatSet.isEmpty {
                return occurrence
            }

            let weekday = calendar.component(.weekday, from: occurrence)
            guard repeatSet.contains(weekday) else { continue }

            return occurrence
        }

        return nil
    }

    func nextOccurrence(after date: Date, calendar: Calendar = .current) -> Date? {
        guard let searchStart = calendar.date(byAdding: .second, value: 1, to: date) else { return nil }
        return nextOccurrence(from: searchStart, calendar: calendar)
    }

    func rescheduleDateAfterSkip(from date: Date = .now, calendar: Calendar = .current) -> Date? {
        guard let skippedOccurrence = nextOccurrence(from: date, calendar: calendar) else { return nil }
        return nextOccurrence(after: skippedOccurrence, calendar: calendar)
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
