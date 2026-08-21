import AlarmKit
import SwiftUI
import WidgetKit

struct AlarmLiveActivityWidget: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: AlarmAttributes<EmptyAlarmMetadata>.self) { context in
            AlarmLockScreenView(context: context)
        } dynamicIsland: { context in
            DynamicIsland {
                DynamicIslandExpandedRegion(.leading) {
                    Image(systemName: "alarm.waves.left.and.right.fill")
                        .font(.title2)
                        .foregroundStyle(context.attributes.tintColor)
                }
                DynamicIslandExpandedRegion(.trailing) {
                    AlarmPresentationText(state: context.state)
                        .font(.title3.monospacedDigit())
                }
                DynamicIslandExpandedRegion(.center) {
                    Text("Siren")
                        .font(.headline)
                }
                DynamicIslandExpandedRegion(.bottom) {
                    Text("Complete your mission to dismiss")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
            } compactLeading: {
                Image(systemName: "alarm.fill")
                    .foregroundStyle(context.attributes.tintColor)
            } compactTrailing: {
                AlarmPresentationText(state: context.state)
                    .frame(width: 44)
                    .monospacedDigit()
            } minimal: {
                Image(systemName: "alarm.fill")
                    .foregroundStyle(context.attributes.tintColor)
            }
            .keylineTint(context.attributes.tintColor)
        }
    }
}

private struct AlarmLockScreenView: View {
    let context: ActivityViewContext<AlarmAttributes<EmptyAlarmMetadata>>

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: "alarm.waves.left.and.right.fill")
                    .foregroundStyle(context.attributes.tintColor)
                Text("Siren")
                    .font(.headline)
                Spacer()
                AlarmPresentationText(state: context.state)
                    .font(.title3.monospacedDigit().bold())
            }

            switch context.state.mode {
            case .countdown(let info):
                ProgressView(
                    value: info.previouslyElapsedDuration,
                    total: info.totalCountdownDuration
                )
                .tint(context.attributes.tintColor)
            case .paused:
                Label("Paused", systemImage: "pause.fill")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            case .alert:
                Text("Complete your mission to dismiss")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            @unknown default:
                EmptyView()
            }
        }
        .padding()
    }
}

private struct AlarmPresentationText: View {
    let state: AlarmPresentationState

    var body: some View {
        switch state.mode {
        case .countdown(let info):
            Text(info.fireDate, style: .timer)
        case .paused(let info):
            let remaining = info.totalCountdownDuration - info.previouslyElapsedDuration
            Text(Duration.seconds(remaining), format: .time(pattern: .minuteSecond))
        case .alert(let info):
            Text("\(info.time.hour):\(String(format: "%02d", info.time.minute))")
        @unknown default:
            Text("--:--")
        }
    }
}
