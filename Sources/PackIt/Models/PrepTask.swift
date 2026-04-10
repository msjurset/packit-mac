import Foundation

struct PrepTask: Codable, Identifiable, Hashable, Sendable {
    var id: UUID
    var name: String
    var category: String?
    var timing: PrepTaskTiming
    var dueDate: Date
    var isComplete: Bool
    var notes: String?
    var isAdHoc: Bool
    var sourceTemplateTaskID: UUID?

    init(id: UUID = UUID(), name: String, category: String? = nil, timing: PrepTaskTiming = .daysBefore, dueDate: Date = .now, isComplete: Bool = false, notes: String? = nil, isAdHoc: Bool = false, sourceTemplateTaskID: UUID? = nil) {
        self.id = id
        self.name = name
        self.category = category
        self.timing = timing
        self.dueDate = dueDate
        self.isComplete = isComplete
        self.notes = notes
        self.isAdHoc = isAdHoc
        self.sourceTemplateTaskID = sourceTemplateTaskID
    }

    init(from template: PrepTaskTemplate, departureDate: Date, returnDate: Date?) {
        self.id = UUID()
        self.name = template.name
        self.category = template.category
        self.timing = template.timing
        self.dueDate = template.timing.dueDate(departure: departureDate, returnDate: returnDate)
        self.isComplete = false
        self.notes = template.notes
        self.isAdHoc = false
        self.sourceTemplateTaskID = template.id
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(UUID.self, forKey: .id)
        name = try container.decode(String.self, forKey: .name)
        category = try container.decodeIfPresent(String.self, forKey: .category)
        timing = try container.decodeIfPresent(PrepTaskTiming.self, forKey: .timing) ?? .daysBefore
        dueDate = try container.decodeIfPresent(Date.self, forKey: .dueDate) ?? .now
        isComplete = try container.decodeIfPresent(Bool.self, forKey: .isComplete) ?? false
        notes = try container.decodeIfPresent(String.self, forKey: .notes)
        isAdHoc = try container.decodeIfPresent(Bool.self, forKey: .isAdHoc) ?? false
        sourceTemplateTaskID = try container.decodeIfPresent(UUID.self, forKey: .sourceTemplateTaskID)
    }

    var isOverdue: Bool {
        guard !isComplete else { return false }
        return dueDate < .now
    }
}
