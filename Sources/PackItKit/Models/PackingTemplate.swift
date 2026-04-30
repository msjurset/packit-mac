import Foundation

public struct PackingTemplate: Codable, Identifiable, Hashable, Sendable {
    public var id: UUID
    public var name: String
    public var items: [TemplateItem]
    public var prepTasks: [PrepTaskTemplate]
    public var procedures: [ProcedureTemplate]
    public var referenceLinks: [ReferenceLink]
    public var linkedTemplateIDs: [UUID]
    public var contextTags: [String]
    public var version: Int
    public var lastModifiedBy: String?
    public var createdBy: String?
    public var createdAt: Date
    public var updatedAt: Date

    public init(id: UUID = UUID(), name: String, items: [TemplateItem] = [], prepTasks: [PrepTaskTemplate] = [], procedures: [ProcedureTemplate] = [], referenceLinks: [ReferenceLink] = [], linkedTemplateIDs: [UUID] = [], contextTags: [String] = [], version: Int = 1, lastModifiedBy: String? = nil, createdBy: String? = nil, createdAt: Date = .now, updatedAt: Date = .now) {
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
        self.createdBy = createdBy
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }

    public init(from decoder: Decoder) throws {
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
        createdBy = try container.decodeIfPresent(String.self, forKey: .createdBy)
        createdAt = try container.decodeIfPresent(Date.self, forKey: .createdAt) ?? .now
        updatedAt = try container.decodeIfPresent(Date.self, forKey: .updatedAt) ?? .now
    }

    public var isComposite: Bool { !linkedTemplateIDs.isEmpty }
    public var itemCount: Int { items.count }
    public var prepTaskCount: Int { prepTasks.count }

    public var categories: [String] {
        Array(Set(items.compactMap(\.category))).sorted()
    }

    public mutating func touch(by userName: String? = nil) {
        updatedAt = .now
        version += 1
        if let userName { lastModifiedBy = userName }
    }
}
