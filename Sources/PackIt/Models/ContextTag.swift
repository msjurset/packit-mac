import Foundation

struct ContextTag: Codable, Identifiable, Hashable, Sendable {
    var id: UUID
    var name: String
    var color: String?

    init(id: UUID = UUID(), name: String, color: String? = nil) {
        self.id = id
        self.name = name
        self.color = color
    }
}
