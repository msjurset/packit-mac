import Foundation

enum PersistenceError: Error, LocalizedError {
    case notFound(String)
    case encodingFailed(String)
    case decodingFailed(String)

    var errorDescription: String? {
        switch self {
        case .notFound(let path): return "File not found: \(path)"
        case .encodingFailed(let msg): return "Encoding failed: \(msg)"
        case .decodingFailed(let msg): return "Decoding failed: \(msg)"
        }
    }
}

actor Persistence {
    static let shared = Persistence()

    let baseURL: URL
    private(set) var sharedURL: URL?
    private let encoder: JSONEncoder
    private let decoder: JSONDecoder

    private var localTemplatesDir: URL { baseURL.appendingPathComponent("templates") }
    private var localTripsDir: URL { baseURL.appendingPathComponent("trips") }
    private var localTagsFile: URL { baseURL.appendingPathComponent("tags.json") }
    private var categoriesFile: URL { baseURL.appendingPathComponent("categories.json") }

    private var sharedTemplatesDir: URL? { sharedURL?.appendingPathComponent("templates") }
    private var sharedTripsDir: URL? { sharedURL?.appendingPathComponent("trips") }
    private var sharedTagsFile: URL? { sharedURL?.appendingPathComponent("tags.json") }

    init(baseURL: URL? = nil) {
        let base = baseURL ?? FileManager.default.homeDirectoryForCurrentUser.appendingPathComponent(".packit")
        self.baseURL = base

        let enc = JSONEncoder()
        enc.dateEncodingStrategy = .iso8601
        enc.outputFormatting = [.prettyPrinted, .sortedKeys]
        self.encoder = enc

        let dec = JSONDecoder()
        dec.dateDecodingStrategy = .iso8601
        self.decoder = dec

        ensureDirectories(at: base)
    }

    func configureSharedPath(_ url: URL?) {
        self.sharedURL = url
        if let url {
            ensureDirectories(at: url)
        }
    }

    private nonisolated func ensureDirectories(at base: URL) {
        let fm = FileManager.default
        for dir in [base, base.appendingPathComponent("templates"), base.appendingPathComponent("trips")] {
            if !fm.fileExists(atPath: dir.path) {
                try? fm.createDirectory(at: dir, withIntermediateDirectories: true)
            }
        }
    }

    // MARK: - Shared IDs (track which resources live in shared)

    private var sharedTemplateIDs: Set<UUID> = []
    private var sharedTripIDs: Set<UUID> = []

    func isShared(templateID: UUID) -> Bool { sharedTemplateIDs.contains(templateID) }
    func isShared(tripID: UUID) -> Bool { sharedTripIDs.contains(tripID) }

    // MARK: - Templates

    func loadTemplates() throws -> [PackingTemplate] {
        var results: [PackingTemplate] = try loadAll(from: localTemplatesDir)
        sharedTemplateIDs.removeAll()

        if let sharedDir = sharedTemplatesDir {
            let shared: [PackingTemplate] = (try? loadAll(from: sharedDir)) ?? []
            let localIDs = Set(results.map(\.id))
            for template in shared {
                sharedTemplateIDs.insert(template.id)
                if !localIDs.contains(template.id) {
                    results.append(template)
                }
            }
        }
        return results
    }

    func saveTemplate(_ template: PackingTemplate) throws {
        if sharedTemplateIDs.contains(template.id), let dir = sharedTemplatesDir {
            try save(template, id: template.id, to: dir)
        } else {
            try save(template, id: template.id, to: localTemplatesDir)
        }
    }

    func deleteTemplate(id: UUID) throws {
        if sharedTemplateIDs.contains(id), let dir = sharedTemplatesDir {
            try deleteFile(id: id, from: dir)
            sharedTemplateIDs.remove(id)
        } else {
            try deleteFile(id: id, from: localTemplatesDir)
        }
    }

    func shareTemplate(id: UUID) throws {
        guard let sharedDir = sharedTemplatesDir else { return }
        let localFile = localTemplatesDir.appendingPathComponent("\(id.uuidString).json")
        let sharedFile = sharedDir.appendingPathComponent("\(id.uuidString).json")
        let fm = FileManager.default
        guard fm.fileExists(atPath: localFile.path) else { return }
        try fm.moveItem(at: localFile, to: sharedFile)
        sharedTemplateIDs.insert(id)
    }

    func unshareTemplate(id: UUID) throws {
        guard let sharedDir = sharedTemplatesDir else { return }
        let sharedFile = sharedDir.appendingPathComponent("\(id.uuidString).json")
        let localFile = localTemplatesDir.appendingPathComponent("\(id.uuidString).json")
        let fm = FileManager.default
        guard fm.fileExists(atPath: sharedFile.path) else { return }
        try fm.moveItem(at: sharedFile, to: localFile)
        sharedTemplateIDs.remove(id)
    }

    // MARK: - Trips

    func loadTrips() throws -> [TripInstance] {
        var results: [TripInstance] = try loadAll(from: localTripsDir)
        sharedTripIDs.removeAll()

        if let sharedDir = sharedTripsDir {
            let shared: [TripInstance] = (try? loadAll(from: sharedDir)) ?? []
            let localIDs = Set(results.map(\.id))
            for trip in shared {
                sharedTripIDs.insert(trip.id)
                if !localIDs.contains(trip.id) {
                    results.append(trip)
                }
            }
        }
        return results
    }

    func saveTrip(_ trip: TripInstance) throws {
        if sharedTripIDs.contains(trip.id), let dir = sharedTripsDir {
            try save(trip, id: trip.id, to: dir)
        } else {
            try save(trip, id: trip.id, to: localTripsDir)
        }
    }

    func deleteTrip(id: UUID) throws {
        if sharedTripIDs.contains(id), let dir = sharedTripsDir {
            try deleteFile(id: id, from: dir)
            sharedTripIDs.remove(id)
        } else {
            try deleteFile(id: id, from: localTripsDir)
        }
    }

    func shareTrip(id: UUID) throws {
        guard let sharedDir = sharedTripsDir else { return }
        let localFile = localTripsDir.appendingPathComponent("\(id.uuidString).json")
        let sharedFile = sharedDir.appendingPathComponent("\(id.uuidString).json")
        let fm = FileManager.default
        guard fm.fileExists(atPath: localFile.path) else { return }
        try fm.moveItem(at: localFile, to: sharedFile)
        sharedTripIDs.insert(id)
    }

    func unshareTrip(id: UUID) throws {
        guard let sharedDir = sharedTripsDir else { return }
        let sharedFile = sharedDir.appendingPathComponent("\(id.uuidString).json")
        let localFile = localTripsDir.appendingPathComponent("\(id.uuidString).json")
        let fm = FileManager.default
        guard fm.fileExists(atPath: sharedFile.path) else { return }
        try fm.moveItem(at: sharedFile, to: localFile)
        sharedTripIDs.remove(id)
    }

    // MARK: - Tags (merge local + shared)

    func loadTags() throws -> [ContextTag] {
        var tags = loadTagsFromFile(localTagsFile)
        if let sharedFile = sharedTagsFile {
            let sharedTags = loadTagsFromFile(sharedFile)
            let existingNames = Set(tags.map { $0.name.lowercased() })
            for tag in sharedTags where !existingNames.contains(tag.name.lowercased()) {
                tags.append(tag)
            }
        }
        return tags
    }

    func saveTags(_ tags: [ContextTag]) throws {
        let data = try encoder.encode(tags)
        try data.write(to: localTagsFile, options: .atomic)
        // Also update shared tags file if it exists
        if let sharedFile = sharedTagsFile {
            try data.write(to: sharedFile, options: .atomic)
        }
    }

    private func loadTagsFromFile(_ url: URL) -> [ContextTag] {
        guard FileManager.default.fileExists(atPath: url.path),
              let data = try? Data(contentsOf: url),
              let tags = try? decoder.decode([ContextTag].self, from: data) else { return [] }
        return tags
    }

    // MARK: - Item Categories

    func loadCategories() -> [ItemCategory] {
        guard FileManager.default.fileExists(atPath: categoriesFile.path),
              let data = try? Data(contentsOf: categoriesFile),
              let cats = try? decoder.decode([ItemCategory].self, from: data)
        else { return [] }
        return cats
    }

    func saveCategories(_ cats: [ItemCategory]) throws {
        let data = try encoder.encode(cats)
        try data.write(to: categoriesFile, options: .atomic)
    }

    // MARK: - Config

    func loadConfig() throws -> AppConfig {
        let configFile = baseURL.appendingPathComponent("config.json")
        let fm = FileManager.default
        guard fm.fileExists(atPath: configFile.path) else { return AppConfig() }
        let data = try Data(contentsOf: configFile)
        return try decoder.decode(AppConfig.self, from: data)
    }

    func saveConfig(_ config: AppConfig) throws {
        let configFile = baseURL.appendingPathComponent("config.json")
        let data = try encoder.encode(config)
        try data.write(to: configFile, options: .atomic)
    }

    // MARK: - Export / Import

    func exportTrip(_ trip: TripInstance) throws -> Data {
        try encoder.encode(trip)
    }

    func importTrip(from data: Data) throws -> TripInstance {
        try decoder.decode(TripInstance.self, from: data)
    }

    func exportTemplate(_ template: PackingTemplate) throws -> Data {
        try encoder.encode(template)
    }

    func importTemplate(from data: Data) throws -> PackingTemplate {
        try decoder.decode(PackingTemplate.self, from: data)
    }

    // MARK: - Generic Helpers

    private func loadAll<T: Decodable>(from directory: URL) throws -> [T] {
        let fm = FileManager.default
        guard let entries = try? fm.contentsOfDirectory(at: directory, includingPropertiesForKeys: nil) else {
            return []
        }
        var results: [T] = []
        for entry in entries where entry.pathExtension == "json" {
            if let data = try? Data(contentsOf: entry),
               let item = try? decoder.decode(T.self, from: data) {
                results.append(item)
            }
        }
        return results
    }

    private func save<T: Encodable>(_ item: T, id: UUID, to directory: URL) throws {
        let data = try encoder.encode(item)
        let file = directory.appendingPathComponent("\(id.uuidString).json")
        try data.write(to: file, options: .atomic)
    }

    private func deleteFile(id: UUID, from directory: URL) throws {
        let file = directory.appendingPathComponent("\(id.uuidString).json")
        let fm = FileManager.default
        guard fm.fileExists(atPath: file.path) else {
            throw PersistenceError.notFound(file.path)
        }
        try fm.removeItem(at: file)
    }
}
