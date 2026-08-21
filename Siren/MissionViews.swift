import SwiftUI

/// Ordered mission chain picker. Tapping a card adds or removes missions from the chain.
struct MissionSetupView: View {
    @Binding var missions: [DismissalMission]
    @Binding var scanningMissionKind: DismissalMission.Kind?

    private let columns = [
        GridItem(.flexible(), spacing: 12),
        GridItem(.flexible(), spacing: 12),
    ]

    var body: some View {
        Section("Dismissal Missions") {
            LazyVGrid(columns: columns, spacing: 12) {
                ForEach(DismissalMission.Kind.allCases) { kind in
                    MissionKindCard(
                        kind: kind,
                        selectionOrder: missions.selectionOrder(for: kind)
                    ) {
                        toggle(kind)
                    }
                }
            }
            .listRowInsets(EdgeInsets(top: 12, leading: 16, bottom: 12, trailing: 16))
            .listRowBackground(Color.clear)
        }
    }

    private func toggle(_ kind: DismissalMission.Kind) {
        guard kind.isAvailable else { return }

        if missions.contains(where: { $0.kind == kind }) {
            missions.removeAll { $0.kind == kind }
            return
        }

        switch kind {
        case .barcode:
            scanningMissionKind = .barcode
        case .math, .shake:
            break
        }
    }
}

struct MissionKindCard: View {
    let kind: DismissalMission.Kind
    let selectionOrder: Int?
    let action: () -> Void

    private var isSelected: Bool { selectionOrder != nil }

    var body: some View {
        Button(action: action) {
            ZStack(alignment: .topTrailing) {
                VStack(spacing: 10) {
                    Image(systemName: kind.systemImage)
                        .font(.system(size: 30, weight: .semibold))
                        .symbolRenderingMode(.hierarchical)
                        .foregroundStyle(isSelected ? Color.accentColor : .primary)

                    Text(kind.title)
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(.primary)

                    Text(kind.subtitle)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                        .lineLimit(2)
                        .minimumScaleFactor(0.85)
                }
                .frame(maxWidth: .infinity, minHeight: 118)
                .padding(.horizontal, 12)
                .padding(.vertical, 16)

                if let selectionOrder {
                    MissionSelectionBadge(order: selectionOrder)
                        .padding(10)
                }
            }
            .background {
                RoundedRectangle(cornerRadius: 24, style: .continuous)
                    .fill(cardFill)
            }
            .overlay {
                RoundedRectangle(cornerRadius: 24, style: .continuous)
                    .strokeBorder(cardStroke, lineWidth: isSelected ? 2 : 1)
            }
        }
        .buttonStyle(.plain)
        .disabled(!kind.isAvailable)
        .opacity(kind.isAvailable ? 1 : 0.45)
        .accessibilityLabel(kind.title)
        .accessibilityValue(isSelected ? "Selected, step \(selectionOrder ?? 0)" : "Not selected")
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }

    private var cardFill: Color {
        if isSelected {
            Color.accentColor.opacity(0.12)
        } else {
            Color(.secondarySystemGroupedBackground)
        }
    }

    private var cardStroke: Color {
        if isSelected {
            Color.accentColor
        } else {
            Color(.separator).opacity(0.35)
        }
    }
}

private struct MissionSelectionBadge: View {
    let order: Int

    var body: some View {
        HStack(spacing: 3) {
            Image(systemName: "checkmark")
            Text("\(order)")
        }
        .font(.caption2.weight(.bold))
        .foregroundStyle(.white)
        .padding(.horizontal, 8)
        .padding(.vertical, 5)
        .background {
            Capsule(style: .continuous)
                .fill(Color.accentColor)
        }
    }
}

/// In-alarm challenge UI. Completing the mission must be the only path to `onComplete`.
struct MissionChallengeView: View {
    let mission: DismissalMission
    let onComplete: () -> Void

    var body: some View {
        switch mission {
        case .barcode(let targetCode):
            BarcodeMissionChallengeView(targetCode: targetCode, onComplete: onComplete)
        }
    }
}
