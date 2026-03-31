import Foundation

struct AppConfig: Codable {
    var watermarkStyle: WatermarkStyle = .palmTrees
    var printWithWatermark: Bool = true
}

enum WatermarkStyle: String, Codable, CaseIterable, Identifiable {
    case none
    case palmTrees
    case mountains
    case compass
    case waves
    case suitcases
    case worldDots
    case tropicalLeaves
    case anchors

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .none: return "None"
        case .palmTrees: return "Palm Trees"
        case .mountains: return "Mountains"
        case .compass: return "Compass Rose"
        case .waves: return "Ocean Waves"
        case .suitcases: return "Suitcases"
        case .worldDots: return "World Dots"
        case .tropicalLeaves: return "Tropical Leaves"
        case .anchors: return "Anchors"
        }
    }

    var icon: String {
        switch self {
        case .none: return "circle.dashed"
        case .palmTrees: return "tree.fill"
        case .mountains: return "mountain.2.fill"
        case .compass: return "safari.fill"
        case .waves: return "water.waves"
        case .suitcases: return "suitcase.fill"
        case .worldDots: return "globe"
        case .tropicalLeaves: return "leaf.fill"
        case .anchors: return "anchor"
        }
    }
}
