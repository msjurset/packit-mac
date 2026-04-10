import Foundation

struct Conflict: Identifiable {
    let id = UUID()
    let entityID: UUID
    let entityName: String
    let entityType: EntityType
    let version: Int
    let modifiedBy: String

    enum EntityType {
        case template
        case trip
    }
}
