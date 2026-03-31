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
    private let templatesDir: URL
    private let tripsDir: URL
    private let tagsFile: URL

    private let encoder: JSONEncoder
    private let decoder: JSONDecoder

    init(baseURL: URL? = nil) {
        let base = baseURL ?? FileManager.default.homeDirectoryForCurrentUser.appendingPathComponent(".packit")
        self.baseURL = base
        self.templatesDir = base.appendingPathComponent("templates")
        self.tripsDir = base.appendingPathComponent("trips")
        self.tagsFile = base.appendingPathComponent("tags.json")

        let enc = JSONEncoder()
        enc.dateEncodingStrategy = .iso8601
        enc.outputFormatting = [.prettyPrinted, .sortedKeys]
        self.encoder = enc

        let dec = JSONDecoder()
        dec.dateDecodingStrategy = .iso8601
        self.decoder = dec

        let fm = FileManager.default
        for dir in [base, base.appendingPathComponent("templates"), base.appendingPathComponent("trips")] {
            if !fm.fileExists(atPath: dir.path) {
                try? fm.createDirectory(at: dir, withIntermediateDirectories: true)
            }
        }
    }

    // MARK: - Templates

    func loadTemplates() throws -> [PackingTemplate] {
        try loadAll(from: templatesDir)
    }

    func saveTemplate(_ template: PackingTemplate) throws {
        try save(template, id: template.id, to: templatesDir)
    }

    func deleteTemplate(id: UUID) throws {
        try deleteFile(id: id, from: templatesDir)
    }

    // MARK: - Trips

    func loadTrips() throws -> [TripInstance] {
        try loadAll(from: tripsDir)
    }

    func saveTrip(_ trip: TripInstance) throws {
        try save(trip, id: trip.id, to: tripsDir)
    }

    func deleteTrip(id: UUID) throws {
        try deleteFile(id: id, from: tripsDir)
    }

    // MARK: - Tags

    func loadTags() throws -> [ContextTag] {
        let fm = FileManager.default
        guard fm.fileExists(atPath: tagsFile.path) else { return [] }
        let data = try Data(contentsOf: tagsFile)
        return try decoder.decode([ContextTag].self, from: data)
    }

    func saveTags(_ tags: [ContextTag]) throws {
        let data = try encoder.encode(tags)
        try data.write(to: tagsFile, options: .atomic)
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
            let data = try Data(contentsOf: entry)
            let item = try decoder.decode(T.self, from: data)
            results.append(item)
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
