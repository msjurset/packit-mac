import Foundation
import SwiftUI

enum AppAppearance: String, Codable, CaseIterable, Sendable {
    case system
    case dark
    case light

    var label: String {
        switch self {
        case .system: "System"
        case .dark: "Dark"
        case .light: "Light"
        }
    }
}

enum AppFontSize: String, Codable, CaseIterable, Sendable {
    case small
    case medium
    case large
    case xLarge = "xlarge"
    case xxLarge = "xxlarge"

    var label: String {
        switch self {
        case .small: "Smaller"
        case .medium: "Default"
        case .large: "Larger"
        case .xLarge: "Extra Large"
        case .xxLarge: "Largest"
        }
    }

    var dynamicTypeSize: DynamicTypeSize {
        switch self {
        case .small: .small
        case .medium: .large            // SwiftUI's default
        case .large: .xxxLarge
        case .xLarge: .accessibility2
        case .xxLarge: .accessibility4
        }
    }
}

enum LaunchView: String, Codable, CaseIterable, Sendable {
    case templates
    case lastUsed

    var label: String {
        switch self {
        case .templates: "Templates"
        case .lastUsed: "Last Used"
        }
    }
}

enum WeatherProvider: String, Codable, CaseIterable, Sendable {
    case openMeteo
    case weatherApi
    case visualCrossing

    var label: String {
        switch self {
        case .openMeteo: "Open-Meteo"
        case .weatherApi: "WeatherAPI.com"
        case .visualCrossing: "Visual Crossing"
        }
    }

    var requiresKey: Bool {
        switch self {
        case .openMeteo: false
        case .weatherApi, .visualCrossing: true
        }
    }

    var forecastDays: String {
        switch self {
        case .openMeteo: "16 days (free, no key)"
        case .weatherApi: "14 days (paid, $9/mo)"
        case .visualCrossing: "15 days (free key, 1000 calls/day)"
        }
    }

    var icon: String {
        switch self {
        case .openMeteo: "cloud.sun"
        case .weatherApi: "cloud.bolt"
        case .visualCrossing: "eye"
        }
    }
}

struct LocalConfig: Codable, Equatable, Sendable {
    var appearance: AppAppearance = .system
    var fontSize: AppFontSize?
    var launchView: LaunchView = .templates
    var lastNavigationKey: String = "templates"
    var userName: String = ""
    var sharedDataPath: String = ""
    var weatherProvider: WeatherProvider = .openMeteo
    var weatherApiKey: String = ""
    var visualCrossingApiKey: String = ""
    var lastSeenSharedAt: Date?
    var lastSelectedTripByStatus: [TripStatus: UUID]?

    var hasSharedPath: Bool {
        !sharedDataPath.isEmpty
    }

    var resolvedSharedURL: URL? {
        guard hasSharedPath else { return nil }
        return URL(fileURLWithPath: (sharedDataPath as NSString).expandingTildeInPath)
    }

    static let configURL: URL = {
        let appSupport = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
        let dir = appSupport.appendingPathComponent("PackIt")
        try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        return dir.appendingPathComponent("local-config.json")
    }()

    static func load() -> LocalConfig {
        guard FileManager.default.fileExists(atPath: configURL.path),
              let data = try? Data(contentsOf: configURL),
              let config = try? JSONDecoder().decode(LocalConfig.self, from: data) else {
            return LocalConfig()
        }
        return config
    }

    func save() {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        guard let data = try? encoder.encode(self) else { return }
        try? data.write(to: Self.configURL, options: .atomic)
    }
}
