import Foundation

enum NavigationItem: Hashable {
    case templates
    case templateDetail(UUID)
    case tripsPlanning
    case tripsActive
    case tripsCompleted
    case tripsArchived
    case tripDetail(UUID)
    case tags
    case statistics
    case search

    var sectionKey: String {
        switch self {
        case .templates, .templateDetail: "templates"
        case .tripsPlanning: "tripsPlanning"
        case .tripsActive: "tripsActive"
        case .tripsCompleted: "tripsCompleted"
        case .tripsArchived: "tripsArchived"
        case .tripDetail: "tripsPlanning"
        case .tags: "tags"
        case .statistics: "statistics"
        case .search: "search"
        }
    }

    static func from(sectionKey: String) -> NavigationItem? {
        switch sectionKey {
        case "templates": .templates
        case "tripsPlanning": .tripsPlanning
        case "tripsActive": .tripsActive
        case "tripsCompleted": .tripsCompleted
        case "tripsArchived": .tripsArchived
        case "tags": .tags
        case "statistics": .statistics
        case "search": .search
        default: nil
        }
    }
}
