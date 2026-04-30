import Foundation

public struct Conflict: Identifiable {
    public let id = UUID()
    public let entityID: UUID
    public let entityName: String
    public let entityType: EntityType
    public let version: Int
    public let modifiedBy: String

    public enum EntityType {
        case template
        case trip
    }

    public init(entityID: UUID, entityName: String, entityType: EntityType, version: Int, modifiedBy: String) {
        self.entityID = entityID
        self.entityName = entityName
        self.entityType = entityType
        self.version = version
        self.modifiedBy = modifiedBy
    }
}
