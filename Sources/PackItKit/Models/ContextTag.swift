import Foundation

public struct ContextTag: Codable, Identifiable, Hashable, Sendable {
    public var id: UUID
    public var name: String
    public var color: String?

    public init(id: UUID = UUID(), name: String, color: String? = nil) {
        self.id = id
        self.name = name
        self.color = color
    }
}
