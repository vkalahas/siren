import SwiftUI

struct RingingView: View {
    var alarm: AlarmItem

    @State private var completedMissionCount = 0

    private var currentMission: DismissalMission? {
        guard completedMissionCount < alarm.missions.count else { return nil }
        return alarm.missions[completedMissionCount]
    }

    var body: some View {
        VStack(spacing: 16) {
            Spacer()

            TimelineView(.periodic(from: .now, by: 1)) { context in
                Text(context.date, format: .dateTime.hour().minute())
                    .font(.system(size: 80, weight: .bold))
                    .monospacedDigit()
            }

            Text("WAKE UP!")
                .font(.largeTitle.bold())
                .foregroundStyle(.red)

            if alarm.missions.count > 1 {
                Text("Mission \(completedMissionCount + 1) of \(alarm.missions.count)")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }

            if let currentMission {
                Text(currentMission.kind.challengePrompt)
                    .font(.headline)
                    .multilineTextAlignment(.center)

                MissionChallengeView(mission: currentMission) {
                    advanceMissionChain()
                }
                .padding(.horizontal)
            }

            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.black.ignoresSafeArea())
        .foregroundStyle(.white)
        .interactiveDismissDisabled(true)
    }

    private func advanceMissionChain() {
        let nextCount = completedMissionCount + 1
        if nextCount >= alarm.missions.count {
            AlarmScheduler.shared.completeMission(for: alarm)
        } else {
            completedMissionCount = nextCount
        }
    }
}
