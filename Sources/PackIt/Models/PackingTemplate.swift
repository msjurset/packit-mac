import Foundation

struct PackingTemplate: Codable, Identifiable, Hashable, Sendable {
    var id: UUID
    var name: String
    var items: [TemplateItem]
    var prepTasks: [PrepTaskTemplate]
    var procedures: [ProcedureTemplate]
    var referenceLinks: [ReferenceLink]
    var linkedTemplateIDs: [UUID]
    var contextTags: [String]
    var version: Int
    var lastModifiedBy: String?
    var createdAt: Date
    var updatedAt: Date

    init(id: UUID = UUID(), name: String, items: [TemplateItem] = [], prepTasks: [PrepTaskTemplate] = [], procedures: [ProcedureTemplate] = [], referenceLinks: [ReferenceLink] = [], linkedTemplateIDs: [UUID] = [], contextTags: [String] = [], version: Int = 1, lastModifiedBy: String? = nil, createdAt: Date = .now, updatedAt: Date = .now) {
        self.id = id
        self.name = name
        self.items = items
        self.prepTasks = prepTasks
        self.procedures = procedures
        self.referenceLinks = referenceLinks
        self.linkedTemplateIDs = linkedTemplateIDs
        self.contextTags = contextTags
        self.version = version
        self.lastModifiedBy = lastModifiedBy
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(UUID.self, forKey: .id)
        name = try container.decode(String.self, forKey: .name)
        items = try container.decodeIfPresent([TemplateItem].self, forKey: .items) ?? []
        prepTasks = try container.decodeIfPresent([PrepTaskTemplate].self, forKey: .prepTasks) ?? []
        procedures = try container.decodeIfPresent([ProcedureTemplate].self, forKey: .procedures) ?? []
        referenceLinks = try container.decodeIfPresent([ReferenceLink].self, forKey: .referenceLinks) ?? []
        linkedTemplateIDs = try container.decodeIfPresent([UUID].self, forKey: .linkedTemplateIDs) ?? []
        contextTags = try container.decodeIfPresent([String].self, forKey: .contextTags) ?? []
        version = try container.decodeIfPresent(Int.self, forKey: .version) ?? 1
        lastModifiedBy = try container.decodeIfPresent(String.self, forKey: .lastModifiedBy)
        createdAt = try container.decodeIfPresent(Date.self, forKey: .createdAt) ?? .now
        updatedAt = try container.decodeIfPresent(Date.self, forKey: .updatedAt) ?? .now
    }

    var isComposite: Bool { !linkedTemplateIDs.isEmpty }
    var itemCount: Int { items.count }
    var prepTaskCount: Int { prepTasks.count }

    var categories: [String] {
        Array(Set(items.compactMap(\.category))).sorted()
    }

    mutating func touch(by userName: String? = nil) {
        updatedAt = .now
        version += 1
        if let userName { lastModifiedBy = userName }
    }
}
