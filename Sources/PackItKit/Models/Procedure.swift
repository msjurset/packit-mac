import Foundation

public enum ProcedurePhase: String, Codable, CaseIterable, Identifiable, Comparable, Sendable {
    case beforeDeparture
    case onArrival
    case beforeLeaving
    case onReturn

    public var id: String { rawValue }

    public var label: String {
        switch self {
        case .beforeDeparture: "Before Departure"
        case .onArrival: "On Arrival / Setup"
        case .beforeLeaving: "Before Leaving Site"
        case .onReturn: "On Return Home"
        }
    }

    public var icon: String {
        switch self {
        case .beforeDeparture: "arrow.right.circle"
        case .onArrival: "mappin.circle"
        case .beforeLeaving: "arrow.uturn.left.circle"
        case .onReturn: "house.circle"
        }
    }

    private var sortIndex: Int {
        switch self {
        case .beforeDeparture: 0
        case .onArrival: 1
        case .beforeLeaving: 2
        case .onReturn: 3
        }
    }

    public static func < (lhs: ProcedurePhase, rhs: ProcedurePhase) -> Bool {
        lhs.sortIndex < rhs.sortIndex
    }
}

// MARK: - Template Models

public struct ProcedureStepTemplate: Codable, Identifiable, Hashable, Sendable {
    public var id: UUID
    public var text: String
    public var notes: String?
    public var sortOrder: Int

    public init(id: UUID = UUID(), text: String, notes: String? = nil, sortOrder: Int = 0) {
        self.id = id
        self.text = text
        self.notes = notes
        self.sortOrder = sortOrder
    }
}

public struct ProcedureTemplate: Codable, Identifiable, Hashable, Sendable {
    public var id: UUID
    public var name: String
    public var phase: ProcedurePhase
    public var steps: [ProcedureStepTemplate]

    public init(id: UUID = UUID(), name: String, phase: ProcedurePhase, steps: [ProcedureStepTemplate] = []) {
        self.id = id
        self.name = name
        self.phase = phase
        self.steps = steps
    }

    public var stepCount: Int { steps.count }
}

// MARK: - Trip Instance Models

public struct ProcedureStep: Codable, Identifiable, Hashable, Sendable {
    public var id: UUID
    public var text: String
    public var notes: String?
    public var isComplete: Bool
    public var sortOrder: Int

    public init(id: UUID = UUID(), text: String, notes: String? = nil, isComplete: Bool = false, sortOrder: Int = 0) {
        self.id = id
        self.text = text
        self.notes = notes
        self.isComplete = isComplete
        self.sortOrder = sortOrder
    }

    public init(from template: ProcedureStepTemplate) {
        self.id = UUID()
        self.text = template.text
        self.notes = template.notes
        self.isComplete = false
        self.sortOrder = template.sortOrder
    }
}

public struct Procedure: Codable, Identifiable, Hashable, Sendable {
    public var id: UUID
    public var name: String
    public var phase: ProcedurePhase
    public var steps: [ProcedureStep]
    public var isCollapsed: Bool

    public init(id: UUID = UUID(), name: String, phase: ProcedurePhase, steps: [ProcedureStep] = [], isCollapsed: Bool = false) {
        self.id = id
        self.name = name
        self.phase = phase
        self.steps = steps
        self.isCollapsed = isCollapsed
    }

    public init(from template: ProcedureTemplate) {
        self.id = UUID()
        self.name = template.name
        self.phase = template.phase
        self.steps = template.steps.sorted(by: { $0.sortOrder < $1.sortOrder }).map { ProcedureStep(from: $0) }
        self.isCollapsed = false
    }

    public var completedCount: Int { steps.filter(\.isComplete).count }
    public var progress: Double {
        guard !steps.isEmpty else { return 0 }
        return Double(completedCount) / Double(steps.count)
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(UUID.self, forKey: .id)
        name = try container.decode(String.self, forKey: .name)
        phase = try container.decodeIfPresent(ProcedurePhase.self, forKey: .phase) ?? .beforeDeparture
        steps = try container.decodeIfPresent([ProcedureStep].self, forKey: .steps) ?? []
        isCollapsed = try container.decodeIfPresent(Bool.self, forKey: .isCollapsed) ?? false
    }
}
