import SwiftUI

struct RingingView: View {
    var alarm: AlarmItem

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

            Text(alarm.mission.kind.challengePrompt)
                .font(.headline)
                .multilineTextAlignment(.center)

            MissionChallengeView(mission: alarm.mission) {
                AlarmScheduler.shared.completeMission(for: alarm)
            }
            .padding(.horizontal)

            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.black.ignoresSafeArea())
        .foregroundStyle(.white)
        .interactiveDismissDisabled(true)
    }
}
