import Foundation
import SwiftData

@Model
final class AlarmItem {
    @Attribute(.unique) var id: UUID
    var time: Date
    var isActive: Bool
    var mission: DismissalMission

    init(id: UUID = UUID(), time: Date, isActive: Bool = true, mission: DismissalMission) {
        self.id = id
        self.time = time
        self.isActive = isActive
        self.mission = mission
    }
}
