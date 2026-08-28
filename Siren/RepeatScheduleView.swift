import SwiftUI

struct RepeatScheduleView: View {
    @Binding var repeatWeekdays: [Int]

    var body: some View {
        Section("Repeat Schedule") {
            HStack(spacing: 8) {
                ForEach(Array(WeekdaySchedule.orderedWeekdays.enumerated()), id: \.offset) { index, weekday in
                    WeekdayToggleButton(
                        label: WeekdaySchedule.labels[index],
                        isSelected: repeatWeekdays.contains(weekday)
                    ) {
                        toggle(weekday)
                    }
                }
            }
            .frame(maxWidth: .infinity)
            .listRowInsets(EdgeInsets(top: 12, leading: 16, bottom: 12, trailing: 16))
        }
    }

    private func toggle(_ weekday: Int) {
        var selected = Set(repeatWeekdays)
        if selected.contains(weekday) {
            selected.remove(weekday)
        } else {
            selected.insert(weekday)
        }
        repeatWeekdays = WeekdaySchedule.orderedWeekdays.filter { selected.contains($0) }
    }
}

private struct WeekdayToggleButton: View {
    let label: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(label)
                .font(.caption.weight(.semibold))
                .foregroundStyle(isSelected ? .white : .secondary)
                .frame(maxWidth: .infinity)
                .frame(height: 36)
                .background {
                    Circle()
                        .fill(isSelected ? Color.accentColor : Color.clear)
                }
                .overlay {
                    Circle()
                        .strokeBorder(isSelected ? Color.clear : Color.secondary.opacity(0.35), lineWidth: 1)
                }
        }
        .buttonStyle(.plain)
        .accessibilityLabel(label)
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }
}
