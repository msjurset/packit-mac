import Foundation

public enum PrintLayout: String, Codable, CaseIterable, Identifiable, Sendable {
    case standard
    case compact
    case dense

    public var id: String { rawValue }

    public var displayName: String {
        switch self {
        case .standard: return "Standard"
        case .compact: return "Compact"
        case .dense: return "Dense"
        }
    }

    public var icon: String {
        switch self {
        case .standard: return "list.bullet.rectangle"
        case .compact: return "rectangle.grid.2x2"
        case .dense: return "square.grid.3x3"
        }
    }
}

public struct AppConfig: Codable, Sendable {
    public var printLayout: PrintLayout = .standard
    public var patternStyle: PatternStyle = .palmTrees
    public var fullPageStyle: FullPageStyle = .none
    public var borderStyle: BorderStyle = .none
    public var patternOpacity: Double = 0.06
    public var fullPageOpacity: Double = 0.04
    public var borderOpacity: Double = 0.10
    public var enablePattern: Bool = true
    public var enableFullPage: Bool = false
    public var enableBorder: Bool = false

    public init() {}
}

// MARK: - Pattern (repeating tile)

public enum PatternStyle: String, Codable, CaseIterable, Identifiable, Sendable {
    case none
    case palmTrees
    case mountains
    case compass
    case waves
    case suitcases
    case worldDots
    case tropicalLeaves
    case anchors

    public var id: String { rawValue }

    public var displayName: String {
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

    public var icon: String {
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

// MARK: - Full-page art (single large illustration)

public enum FullPageStyle: String, Codable, CaseIterable, Identifiable, Sendable {
    case none
    case beachScene
    case mountainLandscape
    case largeCompass
    case worldMap
    case tropicalFrame
    case nauticalChart

    public var id: String { rawValue }

    public var displayName: String {
        switch self {
        case .none: return "None"
        case .beachScene: return "Beach Scene"
        case .mountainLandscape: return "Mountain Landscape"
        case .largeCompass: return "Compass"
        case .worldMap: return "World Map"
        case .tropicalFrame: return "Tropical Frame"
        case .nauticalChart: return "Nautical Chart"
        }
    }

    public var icon: String {
        switch self {
        case .none: return "circle.dashed"
        case .beachScene: return "sun.horizon.fill"
        case .mountainLandscape: return "mountain.2.fill"
        case .largeCompass: return "safari.fill"
        case .worldMap: return "globe.americas.fill"
        case .tropicalFrame: return "leaf.fill"
        case .nauticalChart: return "helm"
        }
    }
}

// MARK: - Border (decorative frame)

public enum BorderStyle: String, Codable, CaseIterable, Identifiable, Sendable {
    case none
    case simpleLine
    case doubleLine
    case rope
    case vine
    case passportStamps
    case ticketEdge

    public var id: String { rawValue }

    public var displayName: String {
        switch self {
        case .none: return "None"
        case .simpleLine: return "Simple Line"
        case .doubleLine: return "Double Line"
        case .rope: return "Rope"
        case .vine: return "Vine & Leaves"
        case .passportStamps: return "Passport Stamps"
        case .ticketEdge: return "Ticket Edge"
        }
    }

    public var icon: String {
        switch self {
        case .none: return "circle.dashed"
        case .simpleLine: return "rectangle"
        case .doubleLine: return "rectangle.inset.filled"
        case .rope: return "lasso"
        case .vine: return "leaf.fill"
        case .passportStamps: return "stamp.fill"
        case .ticketEdge: return "ticket.fill"
        }
    }
}
