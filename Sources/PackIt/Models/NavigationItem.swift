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
    case search
}
