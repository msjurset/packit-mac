import Foundation

public struct TripActivity: Codable, Identifiable, Hashable, Sendable {
    public var id: UUID
    public var text: String
    public var sortOrder: Int

    public init(id: UUID = UUID(), text: String, sortOrder: Int = 0) {
        self.id = id
        self.text = text
        self.sortOrder = sortOrder
    }
}
