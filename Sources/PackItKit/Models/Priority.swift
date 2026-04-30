import Foundation

public enum Priority: String, Codable, CaseIterable, Comparable, Sendable {
    case low
    case medium
    case high
    case critical

    public var label: String {
        rawValue.capitalized
    }

    public var icon: String {
        switch self {
        case .low: return "circle"
        case .medium: return "circle.fill"
        case .high: return "exclamationmark.circle.fill"
        case .critical: return "exclamationmark.triangle.fill"
        }
    }

    public var sortOrder: Int {
        switch self {
        case .low: return 0
        case .medium: return 1
        case .high: return 2
        case .critical: return 3
        }
    }

    public static func < (lhs: Priority, rhs: Priority) -> Bool {
        lhs.sortOrder < rhs.sortOrder
    }
}
