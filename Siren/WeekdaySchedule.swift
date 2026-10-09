import AlarmKit
import Foundation

enum WeekdaySchedule {
  /// Sunday-first display order matching `Calendar` weekday values (1 = Sunday … 7 = Saturday).
  static let orderedWeekdays: [Int] = [1, 2, 3, 4, 5, 6, 7]

  static let labels: [String] = ["Su", "Mo", "Tu", "We", "Th", "Fr", "Sa"]

  static let allWeekdays: [Int] = orderedWeekdays

  static func label(for weekday: Int) -> String? {
    guard let index = orderedWeekdays.firstIndex(of: weekday) else { return nil }
    return labels[index]
  }

  static func alarmKitWeekdays(from calendarWeekdays: [Int]) -> [Locale.Weekday] {
    calendarWeekdays.compactMap(localeWeekday(from:))
  }

  static func alarmKitRecurrence(for calendarWeekdays: [Int]) -> Alarm.Schedule.Relative.Recurrence {
    let weekdays = alarmKitWeekdays(from: calendarWeekdays)
    guard !weekdays.isEmpty else { return .never }
    return .weekly(weekdays)
  }

  nonisolated private static func localeWeekday(from calendarWeekday: Int) -> Locale.Weekday? {
    switch calendarWeekday {
    case 1: .sunday
    case 2: .monday
    case 3: .tuesday
    case 4: .wednesday
    case 5: .thursday
    case 6: .friday
    case 7: .saturday
    default: nil
    }
  }
}

extension AlarmItem {
  var isRepeating: Bool {
    !repeatWeekdays.isEmpty
  }

  var repeatWeekdaySet: Set<Int> {
    get { Set(repeatWeekdays) }
    set { repeatWeekdays = newValue.sorted() }
  }

  var alarmKitRecurrence: Alarm.Schedule.Relative.Recurrence {
    WeekdaySchedule.alarmKitRecurrence(for: repeatWeekdays)
  }
}
