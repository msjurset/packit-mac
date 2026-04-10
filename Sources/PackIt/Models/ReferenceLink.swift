import Foundation

struct ReferenceLink: Codable, Identifiable, Hashable, Sendable {
    var id: UUID
    var label: String
    var url: String
    var category: String?

    init(id: UUID = UUID(), label: String, url: String, category: String? = nil) {
        self.id = id
        self.label = label
        self.url = url
        self.category = category
    }

    var validURL: URL? {
        URL(string: url)
    }
}
