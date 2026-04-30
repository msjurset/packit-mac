import Foundation

public struct ReferenceLink: Codable, Identifiable, Hashable, Sendable {
    public var id: UUID
    public var label: String
    public var url: String
    public var category: String?

    public init(id: UUID = UUID(), label: String, url: String, category: String? = nil) {
        self.id = id
        self.label = label
        self.url = url
        self.category = category
    }

    public var validURL: URL? {
        URL(string: url)
    }
}
