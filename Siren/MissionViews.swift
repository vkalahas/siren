import SwiftUI

/// Setup UI for the selected mission. New mission kinds get a branch here.
struct MissionSetupView: View {
    @Binding var mission: DismissalMission?

    var body: some View {
        Section("Dismissal Mission") {
            switch displayedKind {
            case .barcode:
                BarcodeMissionSetupRows(mission: $mission)
            }
        }
    }

    private var displayedKind: DismissalMission.Kind {
        mission?.kind ?? .barcode
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
