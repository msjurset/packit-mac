import Foundation

struct NewSharedItem: Identifiable, Hashable, Sendable {
    enum Kind: String, Sendable { case template, trip }

    let id: UUID
    let name: String
    let kind: Kind
    let author: String
}
