import SwiftUI

struct ShakeMissionChallengeView: View {
    let requiredShakes: Int
    let onComplete: () -> Void

    @State private var detector: ShakeMotionDetector
    @State private var shakeFeedbackTrigger = 0
    @State private var hasCompleted = false

    init(requiredShakes: Int, onComplete: @escaping () -> Void) {
        let validatedRequiredShakes = max(1, requiredShakes)
        self.requiredShakes = validatedRequiredShakes
        self.onComplete = onComplete
        _detector = State(
            initialValue: ShakeMotionDetector(requiredShakes: validatedRequiredShakes)
        )
    }

    var body: some View {
        VStack(spacing: 20) {
            switch detector.state {
            case .unavailable, .failed:
                motionUnavailableContent
            case .idle, .active, .completed:
                shakeProgressContent
            }
        }
        .padding(.horizontal, 24)
        .sensoryFeedback(.impact(weight: .heavy), trigger: shakeFeedbackTrigger)
        .onAppear {
            detector.start()
        }
        .onDisappear {
            detector.stop()
        }
        .onChange(of: detector.detectedShakeCount) { oldValue, newValue in
            guard newValue > oldValue else { return }
            shakeFeedbackTrigger += 1

            if detector.isComplete {
                completeOnce()
            }
        }
    }

    private var shakeProgressContent: some View {
        Group {
            ProgressView(
                value: Double(min(detector.detectedShakeCount, requiredShakes)),
                total: Double(requiredShakes)
            )
            .progressViewStyle(.linear)
            .tint(.red)

            Text("\(min(detector.detectedShakeCount, requiredShakes)) of \(requiredShakes)")
                .font(.title2.monospacedDigit().bold())

            Image(systemName: "iphone.radiowaves.left.and.right")
                .font(.system(size: 56, weight: .semibold))
                .symbolEffect(
                    .wiggle.byLayer,
                    options: .repeating,
                    isActive: !detector.isComplete
                )
                .foregroundStyle(.red)

            Text("Shake your phone vigorously")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
    }

    private var motionUnavailableContent: some View {
        ContentUnavailableView {
            Label("Motion Unavailable", systemImage: "iphone.slash")
        } description: {
            Text("Siren can't read motion on this device. You can retry or use the fallback dismissal.")
        } actions: {
            Button("Try Again") {
            detector.start()
        }

            Button("Dismiss Alarm", role: .destructive) {
                completeOnce()
            }
        }
    }

    private func completeOnce() {
        guard !hasCompleted else { return }
        hasCompleted = true
        detector.stop()
        onComplete()
    }
}
