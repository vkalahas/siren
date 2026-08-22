import CoreMotion
import Foundation
import Observation

enum ShakeMotionState: Equatable {
    case idle
    case active
    case completed
    case unavailable
    case failed
}

nonisolated struct ShakeDetectionAlgorithm {
    let threshold: Double
    let debounceInterval: TimeInterval

    private(set) var lastShakeDate: Date?

    init(threshold: Double = 2, debounceInterval: TimeInterval = 0.35) {
        self.threshold = threshold
        self.debounceInterval = debounceInterval
    }

    mutating func detectsShake(magnitude: Double, at date: Date) -> Bool {
        guard magnitude >= threshold else { return false }

        if let lastShakeDate,
           date.timeIntervalSince(lastShakeDate) < debounceInterval {
            return false
        }

        lastShakeDate = date
        return true
    }
}

/// Owns the app's single Core Motion manager, as recommended by Apple.
@MainActor
final class DeviceMotionService {
    static let shared = DeviceMotionService()

    private let motionManager = CMMotionManager()
    private var activeToken: UUID?

    private init() {}

    var isAvailable: Bool {
        motionManager.isDeviceMotionAvailable
    }

    func start(
        handler: @escaping @MainActor (Result<CMDeviceMotion, Error>) -> Void
    ) -> UUID? {
        stopCurrentUpdates()

        guard motionManager.isDeviceMotionAvailable else { return nil }

        let token = UUID()
        activeToken = token

        motionManager.deviceMotionUpdateInterval = 1.0 / 60.0
        motionManager.startDeviceMotionUpdates(to: .main) { [weak self] motion, error in
            Task { @MainActor in
                guard self?.activeToken == token else { return }

                if let error {
                    handler(.failure(error))
                } else if let motion {
                    handler(.success(motion))
                }
            }
        }

        return token
    }

    func stop(token: UUID) {
        guard activeToken == token else { return }
        stopCurrentUpdates()
    }

    private func stopCurrentUpdates() {
        motionManager.stopDeviceMotionUpdates()
        activeToken = nil
    }
}

/// Counts shake gestures using fused device motion (`userAcceleration`) from Core Motion.
@Observable
@MainActor
final class ShakeMotionDetector {
    private let motionService: DeviceMotionService
    private var updateToken: UUID?
    private var algorithm = ShakeDetectionAlgorithm()

    let requiredShakes: Int
    var detectedShakeCount = 0
    private(set) var state: ShakeMotionState = .idle

    init(requiredShakes: Int) {
        self.requiredShakes = max(1, requiredShakes)
        self.motionService = .shared
    }

    init(requiredShakes: Int, motionService: DeviceMotionService) {
        self.requiredShakes = max(1, requiredShakes)
        self.motionService = motionService
    }

    var isComplete: Bool {
        detectedShakeCount >= requiredShakes
    }

    func start() {
        guard state != .active, state != .completed else { return }
        guard motionService.isAvailable else {
            state = .unavailable
            return
        }

        state = .active
        guard let token = motionService.start(handler: { [weak self] result in
            guard let self else { return }

            switch result {
            case .success(let motion):
                process(motion)
            case .failure(let error):
                handle(error)
            }
        }) else {
            state = .unavailable
            return
        }
        updateToken = token
    }

    func stop() {
        if let updateToken {
            motionService.stop(token: updateToken)
            self.updateToken = nil
        }

        if state == .active {
            state = .idle
        }
    }

    private func process(_ motion: CMDeviceMotion) {
        let userAcceleration = motion.userAcceleration
        let magnitude = sqrt(
            userAcceleration.x * userAcceleration.x
                + userAcceleration.y * userAcceleration.y
                + userAcceleration.z * userAcceleration.z
        )

        guard algorithm.detectsShake(magnitude: magnitude, at: Date()) else { return }
        detectedShakeCount += 1

        if isComplete {
            if let updateToken {
                motionService.stop(token: updateToken)
                self.updateToken = nil
            }
            state = .completed
        }
    }

    private func handle(_: Error) {
        if let updateToken {
            motionService.stop(token: updateToken)
            self.updateToken = nil
        }

        state = .failed
    }
}
