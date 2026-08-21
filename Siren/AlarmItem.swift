import Foundation
import SwiftData

@Model
final class AlarmItem {
    @Attribute(.unique) var id: UUID
    var time: Date
    var isActive: Bool
    var missions: [DismissalMission]

    init(id: UUID = UUID(), time: Date, isActive: Bool = true, missions: [DismissalMission]) {
        self.id = id
        self.time = time
        self.isActive = isActive
        self.missions = missions
    }
}

extension Array where Element == DismissalMission {
    var summary: String {
        map(\.summary).joined(separator: " → ")
    }

    func selectionOrder(for kind: DismissalMission.Kind) -> Int? {
        guard let index = firstIndex(where: { $0.kind == kind }) else { return nil }
        return index + 1
    }
}
