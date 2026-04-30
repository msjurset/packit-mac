import Foundation

public enum PersistenceError: Error, LocalizedError {
    case notFound(String)
    case encodingFailed(String)
    case decodingFailed(String)

    public var errorDescription: String? {
        switch self {
        case .notFound(let path): return "File not found: \(path)"
        case .encodingFailed(let msg): return "Encoding failed: \(msg)"
        case .decodingFailed(let msg): return "Decoding failed: \(msg)"
        }
    }
}

public actor Persistence {
    public static let shared = Persistence()

    public let baseURL: URL
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

    public init(baseURL: URL? = nil) {
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

    public func configureSharedPath(_ url: URL?) {
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

    public func isShared(templateID: UUID) -> Bool { sharedTemplateIDs.contains(templateID) }
    public func isShared(tripID: UUID) -> Bool { sharedTripIDs.contains(tripID) }

    // MARK: - Templates

    public func loadTemplates() throws -> [PackingTemplate] {
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

    public func saveTemplate(_ template: PackingTemplate) throws {
        if sharedTemplateIDs.contains(template.id), let dir = sharedTemplatesDir {
            try save(template, id: template.id, to: dir)
        } else {
            try save(template, id: template.id, to: localTemplatesDir)
        }
    }

    public func deleteTemplate(id: UUID) throws {
        if sharedTemplateIDs.contains(id), let dir = sharedTemplatesDir {
            try deleteFile(id: id, from: dir)
            sharedTemplateIDs.remove(id)
        } else {
            try deleteFile(id: id, from: localTemplatesDir)
        }
    }

    public func shareTemplate(id: UUID) throws {
        guard let sharedDir = sharedTemplatesDir else { return }
        let localFile = localTemplatesDir.appendingPathComponent("\(id.uuidString).json")
        let sharedFile = sharedDir.appendingPathComponent("\(id.uuidString).json")
        let fm = FileManager.default
        guard fm.fileExists(atPath: localFile.path) else { return }
        try fm.moveItem(at: localFile, to: sharedFile)
        sharedTemplateIDs.insert(id)
    }

    public func unshareTemplate(id: UUID) throws {
        guard let sharedDir = sharedTemplatesDir else { return }
        let sharedFile = sharedDir.appendingPathComponent("\(id.uuidString).json")
        let localFile = localTemplatesDir.appendingPathComponent("\(id.uuidString).json")
        let fm = FileManager.default
        guard fm.fileExists(atPath: sharedFile.path) else { return }
        try fm.moveItem(at: sharedFile, to: localFile)
        sharedTemplateIDs.remove(id)
    }

    // MARK: - Trips

    public func loadTrips() throws -> [TripInstance] {
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

    public func saveTrip(_ trip: TripInstance) throws {
        if sharedTripIDs.contains(trip.id), let dir = sharedTripsDir {
            try save(trip, id: trip.id, to: dir)
        } else {
            try save(trip, id: trip.id, to: localTripsDir)
        }
    }

    public func deleteTrip(id: UUID) throws {
        if sharedTripIDs.contains(id), let dir = sharedTripsDir {
            try deleteFile(id: id, from: dir)
            sharedTripIDs.remove(id)
        } else {
            try deleteFile(id: id, from: localTripsDir)
        }
    }

    public func shareTrip(id: UUID) throws {
        guard let sharedDir = sharedTripsDir else { return }
        let localFile = localTripsDir.appendingPathComponent("\(id.uuidString).json")
        let sharedFile = sharedDir.appendingPathComponent("\(id.uuidString).json")
        let fm = FileManager.default
        guard fm.fileExists(atPath: localFile.path) else { return }
        try fm.moveItem(at: localFile, to: sharedFile)
        sharedTripIDs.insert(id)
    }

    public func unshareTrip(id: UUID) throws {
        guard let sharedDir = sharedTripsDir else { return }
        let sharedFile = sharedDir.appendingPathComponent("\(id.uuidString).json")
        let localFile = localTripsDir.appendingPathComponent("\(id.uuidString).json")
        let fm = FileManager.default
        guard fm.fileExists(atPath: sharedFile.path) else { return }
        try fm.moveItem(at: sharedFile, to: localFile)
        sharedTripIDs.remove(id)
    }

    // MARK: - Tags (merge local + shared)

    public func loadTags() throws -> [ContextTag] {
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

    public func saveTags(_ tags: [ContextTag]) throws {
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

    public func loadCategories() -> [ItemCategory] {
        guard FileManager.default.fileExists(atPath: categoriesFile.path),
              let data = try? Data(contentsOf: categoriesFile),
              let cats = try? decoder.decode([ItemCategory].self, from: data)
        else { return [] }
        return cats
    }

    public func saveCategories(_ cats: [ItemCategory]) throws {
        let data = try encoder.encode(cats)
        try data.write(to: categoriesFile, options: .atomic)
    }

    // MARK: - Config

    public func loadConfig() throws -> AppConfig {
        let configFile = baseURL.appendingPathComponent("config.json")
        let fm = FileManager.default
        guard fm.fileExists(atPath: configFile.path) else { return AppConfig() }
        let data = try Data(contentsOf: configFile)
        return try decoder.decode(AppConfig.self, from: data)
    }

    public func saveConfig(_ config: AppConfig) throws {
        let configFile = baseURL.appendingPathComponent("config.json")
        let data = try encoder.encode(config)
        try data.write(to: configFile, options: .atomic)
    }

    // MARK: - Export / Import

    public func exportTrip(_ trip: TripInstance) throws -> Data {
        try encoder.encode(trip)
    }

    public func importTrip(from data: Data) throws -> TripInstance {
        try decoder.decode(TripInstance.self, from: data)
    }

    public func exportTemplate(_ template: PackingTemplate) throws -> Data {
        try encoder.encode(template)
    }

    public func importTemplate(from data: Data) throws -> PackingTemplate {
        try decoder.decode(PackingTemplate.self, from: data)
    }

    // MARK: - Backup & Restore

    public static let backupSchemaVersion = 1
    private static let backupEntries = ["templates", "trips", "tags.json", "categories.json", "config.json"]

    public struct BackupManifest: Codable {
        let schemaVersion: Int
        let appVersion: String
        let createdAt: Date
        let contents: [String]
    }

    public var backupsDir: URL { baseURL.appendingPathComponent("backups") }

    private static func currentAppVersion() -> String {
        Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "0.0.0"
    }

    private static func backupTimestamp(from date: Date = .now) -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.timeZone = TimeZone.current
        formatter.dateFormat = "yyyy-MM-dd'T'HHmmss"
        return formatter.string(from: date)
    }

    private func availableBackupURL(timestamp: String, suffix: String?) -> URL {
        let fm = FileManager.default
        let basename = suffix.map { "packit-\(timestamp)-\($0)" } ?? "packit-\(timestamp)"
        var candidate = backupsDir.appendingPathComponent("\(basename).zip")
        var counter = 2
        while fm.fileExists(atPath: candidate.path) {
            candidate = backupsDir.appendingPathComponent("\(basename)-\(counter).zip")
            counter += 1
        }
        return candidate
    }

    @discardableResult
    public func backup(suffix: String? = nil) throws -> URL {
        let fm = FileManager.default
        if !fm.fileExists(atPath: backupsDir.path) {
            try fm.createDirectory(at: backupsDir, withIntermediateDirectories: true)
        }

        let base = baseURL
        let included = Self.backupEntries.filter {
            FileManager.default.fileExists(atPath: base.appendingPathComponent($0).path)
        }

        let manifest = BackupManifest(
            schemaVersion: Self.backupSchemaVersion,
            appVersion: Self.currentAppVersion(),
            createdAt: .now,
            contents: included
        )
        let manifestData = try encoder.encode(manifest)

        let staging = fm.temporaryDirectory.appendingPathComponent("packit-backup-\(UUID().uuidString)")
        try fm.createDirectory(at: staging, withIntermediateDirectories: true)
        defer { try? fm.removeItem(at: staging) }
        let stagedManifest = staging.appendingPathComponent("manifest.json")
        try manifestData.write(to: stagedManifest, options: .atomic)

        let finalURL = availableBackupURL(timestamp: Self.backupTimestamp(), suffix: suffix)
        let partialURL = finalURL.deletingPathExtension().appendingPathExtension("zip.partial")
        if fm.fileExists(atPath: partialURL.path) {
            try fm.removeItem(at: partialURL)
        }

        if !included.isEmpty {
            try runZip(arguments: ["-r", "-q", partialURL.path] + included, currentDirectory: baseURL, partial: partialURL)
        }
        try runZip(arguments: ["-j", "-q", partialURL.path, stagedManifest.path], currentDirectory: nil, partial: partialURL)

        try fm.moveItem(at: partialURL, to: finalURL)
        return finalURL
    }

    private func runZip(arguments: [String], currentDirectory: URL?, partial: URL) throws {
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/bin/zip")
        if let currentDirectory {
            process.currentDirectoryURL = currentDirectory
        }
        process.arguments = arguments
        let pipe = Pipe()
        process.standardOutput = pipe
        process.standardError = pipe
        try process.run()
        process.waitUntilExit()
        guard process.terminationStatus == 0 else {
            try? FileManager.default.removeItem(at: partial)
            throw PersistenceError.encodingFailed("Backup zip failed (status \(process.terminationStatus))")
        }
    }

    public func restore(from zipURL: URL) throws {
        let fm = FileManager.default

        let tempDir = fm.temporaryDirectory.appendingPathComponent("packit-restore-\(UUID().uuidString)")
        try fm.createDirectory(at: tempDir, withIntermediateDirectories: true)

        let unzip = Process()
        unzip.executableURL = URL(fileURLWithPath: "/usr/bin/unzip")
        unzip.arguments = ["-o", "-q", zipURL.path, "-d", tempDir.path]
        let pipe = Pipe()
        unzip.standardOutput = pipe
        unzip.standardError = pipe
        try unzip.run()
        unzip.waitUntilExit()

        guard unzip.terminationStatus == 0 else {
            try? fm.removeItem(at: tempDir)
            throw PersistenceError.decodingFailed("Restore failed: corrupt zip")
        }

        let manifestFile = tempDir.appendingPathComponent("manifest.json")
        guard fm.fileExists(atPath: manifestFile.path) else {
            try? fm.removeItem(at: tempDir)
            throw PersistenceError.decodingFailed("Restore failed: missing manifest")
        }
        let manifestData = try Data(contentsOf: manifestFile)
        let manifest: BackupManifest
        do {
            manifest = try decoder.decode(BackupManifest.self, from: manifestData)
        } catch {
            try? fm.removeItem(at: tempDir)
            throw PersistenceError.decodingFailed("Restore failed: invalid manifest")
        }
        guard manifest.schemaVersion <= Self.backupSchemaVersion else {
            try? fm.removeItem(at: tempDir)
            throw PersistenceError.decodingFailed("Restore failed: backup uses schema v\(manifest.schemaVersion); this app supports up to v\(Self.backupSchemaVersion)")
        }

        let hasAnyData = Self.backupEntries.contains { entry in
            fm.fileExists(atPath: tempDir.appendingPathComponent(entry).path)
        }
        guard hasAnyData else {
            try? fm.removeItem(at: tempDir)
            throw PersistenceError.decodingFailed("Restore failed: backup contains no data")
        }

        do {
            try backup(suffix: "pre-restore")
        } catch {
            try? fm.removeItem(at: tempDir)
            throw PersistenceError.encodingFailed("Pre-restore safety snapshot failed: \(error.localizedDescription)")
        }

        let safetyDir = fm.temporaryDirectory.appendingPathComponent("packit-safety-\(UUID().uuidString)")
        try fm.createDirectory(at: safetyDir, withIntermediateDirectories: true)

        do {
            for entry in Self.backupEntries {
                let src = baseURL.appendingPathComponent(entry)
                if fm.fileExists(atPath: src.path) {
                    try fm.moveItem(at: src, to: safetyDir.appendingPathComponent(entry))
                }
            }
            let extracted = try fm.contentsOfDirectory(at: tempDir, includingPropertiesForKeys: nil)
            for item in extracted where item.lastPathComponent != "manifest.json" {
                let dest = baseURL.appendingPathComponent(item.lastPathComponent)
                try fm.moveItem(at: item, to: dest)
            }
        } catch {
            let safetyContents = (try? fm.contentsOfDirectory(at: safetyDir, includingPropertiesForKeys: nil)) ?? []
            for item in safetyContents {
                let dest = baseURL.appendingPathComponent(item.lastPathComponent)
                try? fm.removeItem(at: dest)
                try? fm.moveItem(at: item, to: dest)
            }
            try? fm.removeItem(at: tempDir)
            try? fm.removeItem(at: safetyDir)
            throw error
        }

        try? fm.removeItem(at: tempDir)
        try? fm.removeItem(at: safetyDir)

        ensureDirectories(at: baseURL)
    }

    public func listBackups() throws -> [URL] {
        let fm = FileManager.default
        guard fm.fileExists(atPath: backupsDir.path) else { return [] }
        let contents = try fm.contentsOfDirectory(at: backupsDir, includingPropertiesForKeys: nil)
        return contents
            .filter { $0.pathExtension == "zip" }
            .sorted { $0.lastPathComponent > $1.lastPathComponent }
    }

    public func pruneBackups(keep: Int) throws {
        guard keep > 0 else { return }
        let fm = FileManager.default
        let all = try listBackups()
        guard all.count > keep else { return }
        for url in all.dropFirst(keep) {
            try fm.removeItem(at: url)
        }
    }

    public func deleteBackup(at url: URL) throws {
        let fm = FileManager.default
        guard url.deletingLastPathComponent().standardizedFileURL == backupsDir.standardizedFileURL else {
            throw PersistenceError.notFound(url.path)
        }
        try fm.removeItem(at: url)
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
