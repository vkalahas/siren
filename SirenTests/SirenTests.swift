//
//  SirenTests.swift
//  SirenTests
//
//  Created by Vik Kalahasthi on 8/21/26.
//

import AlarmKit
import Foundation
import Testing
@testable import Siren

struct SirenTests {
    @Test
    func shakeDetectionRequiresThresholdMagnitude() {
        var detector = ShakeDetectionAlgorithm(threshold: 2, debounceInterval: 0.35)
        let now = Date()

        let belowThreshold = detector.detectsShake(magnitude: 1.99, at: now)
        let atThreshold = detector.detectsShake(magnitude: 2, at: now)

        #expect(!belowThreshold)
        #expect(atThreshold)
    }

    @Test
    func shakeDetectionDebouncesCloselySpacedImpacts() {
        var detector = ShakeDetectionAlgorithm(threshold: 2, debounceInterval: 0.35)
        let start = Date()

        let firstImpact = detector.detectsShake(magnitude: 2.5, at: start)
        let debouncedImpact = detector.detectsShake(
            magnitude: 3,
            at: start.addingTimeInterval(0.2)
        )
        let nextShake = detector.detectsShake(
            magnitude: 2.5,
            at: start.addingTimeInterval(0.35)
        )

        #expect(firstImpact)
        #expect(!debouncedImpact)
        #expect(nextShake)
    }

    @Test
    @MainActor
    func shakeDetectorClampsInvalidRequiredCount() {
        let detector = ShakeMotionDetector(requiredShakes: 0)

        #expect(detector.requiredShakes == 1)
        #expect(!detector.isComplete)
    }

    @Test
    func shakeMissionSummaryClampsInvalidRequiredCount() {
        let mission = DismissalMission.shake(requiredShakes: -5)

        #expect(mission.summary == "Shake: 1 shake")
    }

    @Test
    func lostBarcodeFallbackRequiresFiveHundredShakes() {
        #expect(BarcodeMissionDefaults.lostBarcodeFallbackShakes == 500)
    }

    @Test
    func stackAlarmIDIsStableAndDistinctPerIndex() {
        let parent = UUID(uuidString: "A1B2C3D4-E5F6-7890-ABCD-EF1234567890")!
        let first = AlarmEnforcement.stackAlarmID(parent: parent, index: 0)
        let second = AlarmEnforcement.stackAlarmID(parent: parent, index: 1)
        let firstAgain = AlarmEnforcement.stackAlarmID(parent: parent, index: 0)

        #expect(first == firstAgain)
        #expect(first != second)
    }

    @Test
    func parentAlarmIDRoundTripsForStackIndices() {
        let parent = UUID(uuidString: "12345678-1234-5678-1234-567812345678")!

        for index in 0..<AlarmEnforcement.stackAlarmCount {
            let stackID = AlarmEnforcement.stackAlarmID(parent: parent, index: index)
            let resolved = AlarmEnforcement.parentAlarmID(fromStackID: stackID, knownParents: [parent])

            #expect(resolved == parent)
        }
    }

    @Test
    func parentAlarmIDReturnsNilForUnknownStackID() {
        let unknown = UUID(uuidString: "00000000-0000-4000-8000-000000000001")!
        let parent = UUID(uuidString: "12345678-1234-5678-1234-567812345678")!

        #expect(AlarmEnforcement.parentAlarmID(fromStackID: unknown, knownParents: [parent]) == nil)
    }

    @Test
    func nextOccurrenceReturnsTodayWhenTimeIsLaterToday() {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: "UTC")!

        let reference = calendar.date(from: DateComponents(year: 2026, month: 8, day: 28, hour: 6, minute: 0))!
        let alarmTime = calendar.date(from: DateComponents(year: 2020, month: 1, day: 1, hour: 7, minute: 30))!
        let alarm = AlarmItem(time: alarmTime, missions: [.shake(requiredShakes: 3)])

        let next = alarm.nextOccurrence(from: reference, calendar: calendar)
        let expected = calendar.date(from: DateComponents(year: 2026, month: 8, day: 28, hour: 7, minute: 30))!

        #expect(next == expected)
    }

    @Test
    func nextOccurrenceReturnsTomorrowWhenTimeAlreadyPassedToday() {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: "UTC")!

        let reference = calendar.date(from: DateComponents(year: 2026, month: 8, day: 28, hour: 8, minute: 0))!
        let alarmTime = calendar.date(from: DateComponents(year: 2020, month: 1, day: 1, hour: 7, minute: 30))!
        let alarm = AlarmItem(time: alarmTime, missions: [.shake(requiredShakes: 3)])

        let next = alarm.nextOccurrence(from: reference, calendar: calendar)
        let expected = calendar.date(from: DateComponents(year: 2026, month: 8, day: 29, hour: 7, minute: 30))!

        #expect(next == expected)
    }

    @Test
    func rescheduleDateAfterSkipIsOneDayAfterNextOccurrence() {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: "UTC")!

        let reference = calendar.date(from: DateComponents(year: 2026, month: 8, day: 28, hour: 6, minute: 0))!
        let alarmTime = calendar.date(from: DateComponents(year: 2020, month: 1, day: 1, hour: 7, minute: 30))!
        let alarm = AlarmItem(time: alarmTime, missions: [.shake(requiredShakes: 3)])

        let reschedule = alarm.rescheduleDateAfterSkip(from: reference, calendar: calendar)
        let expected = calendar.date(from: DateComponents(year: 2026, month: 8, day: 29, hour: 7, minute: 30))!

        #expect(reschedule == expected)
    }

    @Test
    func nextOccurrenceRespectsPartialWeekdays() {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: "UTC")!

        let reference = calendar.date(from: DateComponents(year: 2026, month: 8, day: 25, hour: 6, minute: 0))!
        let alarmTime = calendar.date(from: DateComponents(year: 2020, month: 1, day: 1, hour: 7, minute: 30))!
        let alarm = AlarmItem(
            time: alarmTime,
            missions: [.shake(requiredShakes: 3)],
            repeatWeekdays: [4, 6]
        )

        let next = alarm.nextOccurrence(from: reference, calendar: calendar)
        let expected = calendar.date(from: DateComponents(year: 2026, month: 8, day: 26, hour: 7, minute: 30))!

        #expect(next == expected)
    }

    @Test
    func nextOccurrenceAfterSkipJumpsToNextRepeatDay() {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: "UTC")!

        let reference = calendar.date(from: DateComponents(year: 2026, month: 8, day: 24, hour: 6, minute: 0))!
        let alarmTime = calendar.date(from: DateComponents(year: 2020, month: 1, day: 1, hour: 7, minute: 30))!
        let alarm = AlarmItem(
            time: alarmTime,
            missions: [.shake(requiredShakes: 3)],
            repeatWeekdays: [2, 4, 6]
        )

        let reschedule = alarm.rescheduleDateAfterSkip(from: reference, calendar: calendar)
        let expected = calendar.date(from: DateComponents(year: 2026, month: 8, day: 26, hour: 7, minute: 30))!

        #expect(reschedule == expected)
    }

    @Test
    func oneShotAlarmHasNoRepeatDays() {
        let alarm = AlarmItem(time: .now, missions: [.shake(requiredShakes: 1)], repeatWeekdays: [])
        #expect(!alarm.isRepeating)
    }

    @Test
    func alarmKitRecurrenceMapsWeekdays() {
        let recurrence = WeekdaySchedule.alarmKitRecurrence(for: [2, 4, 6])
        if case .weekly(let weekdays) = recurrence {
            #expect(weekdays == [.monday, .wednesday, .friday])
        } else {
            Issue.record("Expected weekly recurrence")
        }

        let oneShot = WeekdaySchedule.alarmKitRecurrence(for: [])
        if case .never = oneShot {
            #expect(Bool(true))
        } else {
            Issue.record("Expected never recurrence")
        }
    }

    @Test
    func showsStrikethroughTimeWhenInactiveOrSkipped() {
        let inactiveAlarm = AlarmItem(time: .now, isActive: false, missions: [.shake(requiredShakes: 1)])
        #expect(inactiveAlarm.showsStrikethroughTime)

        let activeAlarm = AlarmItem(time: .now, isActive: true, missions: [.shake(requiredShakes: 1)])
        #expect(!activeAlarm.showsStrikethroughTime)

        activeAlarm.isSkippedOnce = true
        #expect(activeAlarm.showsStrikethroughTime)
    }
}
