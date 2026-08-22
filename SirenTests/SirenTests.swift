//
//  SirenTests.swift
//  SirenTests
//
//  Created by Vik Kalahasthi on 8/21/26.
//

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
}
