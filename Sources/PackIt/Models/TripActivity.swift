import Foundation

struct TripActivity: Codable, Identifiable, Hashable, Sendable {
    var id: UUID
    var text: String
    var sortOrder: Int

    init(id: UUID = UUID(), text: String, sortOrder: Int = 0) {
        self.id = id
        self.text = text
        self.sortOrder = sortOrder
    }
}
