import Foundation

public struct NewSharedItem: Identifiable, Hashable, Sendable {
    public enum Kind: String, Sendable { case template, trip }

    public let id: UUID
    public let name: String
    public let kind: Kind
    public let author: String

    public init(id: UUID, name: String, kind: Kind, author: String) {
        self.id = id
        self.name = name
        self.kind = kind
        self.author = author
    }
}
