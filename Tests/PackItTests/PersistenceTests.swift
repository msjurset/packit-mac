import Testing
import PackItKit
import Foundation
@testable import PackIt

@Suite("Persistence")
struct PersistenceTests {
    private func makeTempPersistence() async -> (Persistence, URL) {
        let tempDir = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        let persistence = Persistence(baseURL: tempDir)
        return (persistence, tempDir)
    }

    private func cleanup(_ url: URL) {
        try? FileManager.default.removeItem(at: url)
    }

    @Test("save and load template")
    func templateRoundTrip() async throws {
        let (persistence, tempDir) = await makeTempPersistence()
        defer { cleanup(tempDir) }

        let template = PackingTemplate(
            name: "Beach Trip",
            items: [TemplateItem(name: "Sunscreen", category: "Toiletries", priority: .high)],
            contextTags: ["beach", "summer"]
        )

        try await persistence.saveTemplate(template)
        let loaded = try await persistence.loadTemplates()

        #expect(loaded.count == 1)
        #expect(loaded.first?.name == "Beach Trip")
        #expect(loaded.first?.items.count == 1)
        #expect(loaded.first?.contextTags == ["beach", "summer"])
    }

    @Test("delete template")
    func templateDelete() async throws {
        let (persistence, tempDir) = await makeTempPersistence()
        defer { cleanup(tempDir) }

        let template = PackingTemplate(name: "Delete Me")
        try await persistence.saveTemplate(template)

        var loaded = try await persistence.loadTemplates()
        #expect(loaded.count == 1)

        try await persistence.deleteTemplate(id: template.id)
        loaded = try await persistence.loadTemplates()
        #expect(loaded.count == 0)
    }

    @Test("delete nonexistent template throws")
    func deleteNonexistent() async throws {
        let (persistence, tempDir) = await makeTempPersistence()
        defer { cleanup(tempDir) }

        await #expect(throws: PersistenceError.self) {
            try await persistence.deleteTemplate(id: UUID())
        }
    }

    @Test("save and load trip")
    func tripRoundTrip() async throws {
        let (persistence, tempDir) = await makeTempPersistence()
        defer { cleanup(tempDir) }

        let trip = TripInstance(
            name: "Hawaii 2026",
            departureDate: Date.now,
            items: [TripItem(name: "Swimsuit", priority: .high)],
            todos: [TripTodo(text: "Book hotel")],
            scratchNotes: "Pack light",
            status: .planning
        )

        try await persistence.saveTrip(trip)
        let loaded = try await persistence.loadTrips()

        #expect(loaded.count == 1)
        #expect(loaded.first?.name == "Hawaii 2026")
        #expect(loaded.first?.items.count == 1)
        #expect(loaded.first?.todos.count == 1)
        #expect(loaded.first?.scratchNotes == "Pack light")
    }

    @Test("save and load tags")
    func tagsRoundTrip() async throws {
        let (persistence, tempDir) = await makeTempPersistence()
        defer { cleanup(tempDir) }

        let tags = [
            ContextTag(name: "beach", color: "#00AAFF"),
            ContextTag(name: "winter"),
        ]

        try await persistence.saveTags(tags)
        let loaded = try await persistence.loadTags()

        #expect(loaded.count == 2)
        #expect(loaded.contains { $0.name == "beach" })
        #expect(loaded.contains { $0.name == "winter" })
    }

    @Test("load tags from empty file returns empty array")
    func emptyTags() async throws {
        let (persistence, tempDir) = await makeTempPersistence()
        defer { cleanup(tempDir) }

        let loaded = try await persistence.loadTags()
        #expect(loaded.isEmpty)
    }

    @Test("export and import trip")
    func exportImport() async throws {
        let (persistence, tempDir) = await makeTempPersistence()
        defer { cleanup(tempDir) }

        let trip = TripInstance(
            name: "Export Test",
            items: [TripItem(name: "Test Item")],
            status: .active
        )

        let data = try await persistence.exportTrip(trip)
        let imported = try await persistence.importTrip(from: data)

        #expect(imported.name == "Export Test")
        #expect(imported.items.count == 1)
        #expect(imported.status == .active)
    }

    @Test("multiple templates stored independently")
    func multipleTemplates() async throws {
        let (persistence, tempDir) = await makeTempPersistence()
        defer { cleanup(tempDir) }

        let t1 = PackingTemplate(name: "Template A", items: [TemplateItem(name: "Item A")])
        let t2 = PackingTemplate(name: "Template B", items: [TemplateItem(name: "Item B1"), TemplateItem(name: "Item B2")])

        try await persistence.saveTemplate(t1)
        try await persistence.saveTemplate(t2)

        let loaded = try await persistence.loadTemplates()
        #expect(loaded.count == 2)

        let names = Set(loaded.map(\.name))
        #expect(names.contains("Template A"))
        #expect(names.contains("Template B"))
    }

    @Test("update overwrites existing file")
    func updateTemplate() async throws {
        let (persistence, tempDir) = await makeTempPersistence()
        defer { cleanup(tempDir) }

        var template = PackingTemplate(name: "Original")
        try await persistence.saveTemplate(template)

        template.name = "Updated"
        try await persistence.saveTemplate(template)

        let loaded = try await persistence.loadTemplates()
        #expect(loaded.count == 1)
        #expect(loaded.first?.name == "Updated")
    }

    // MARK: - Backup & Restore

    @Test("backup creates timestamped zip with manifest")
    func backupCreatesZip() async throws {
        let (persistence, tempDir) = await makeTempPersistence()
        defer { cleanup(tempDir) }

        try await persistence.saveTemplate(PackingTemplate(name: "Sample"))

        let zipURL = try await persistence.backup()
        #expect(FileManager.default.fileExists(atPath: zipURL.path))
        #expect(zipURL.pathExtension == "zip")
        #expect(zipURL.lastPathComponent.hasPrefix("packit-"))

        let listing = try unzipListing(zipURL)
        #expect(listing.contains("manifest.json"))
        #expect(listing.contains { $0.hasPrefix("templates/") })
    }

    @Test("backup with no data still produces a valid zip")
    func backupEmpty() async throws {
        let (persistence, tempDir) = await makeTempPersistence()
        defer { cleanup(tempDir) }

        let zipURL = try await persistence.backup()
        #expect(FileManager.default.fileExists(atPath: zipURL.path))

        let listing = try unzipListing(zipURL)
        #expect(listing.contains("manifest.json"))
    }

    @Test("backup round trip — wipe and restore")
    func backupRoundTrip() async throws {
        let (persistence, tempDir) = await makeTempPersistence()
        defer { cleanup(tempDir) }

        let template = PackingTemplate(name: "BeforeBackup", items: [TemplateItem(name: "Sock")])
        let trip = TripInstance(name: "TripBefore", items: [TripItem(name: "Toothbrush")])
        let tags = [ContextTag(name: "test", color: "#FF0000")]

        try await persistence.saveTemplate(template)
        try await persistence.saveTrip(trip)
        try await persistence.saveTags(tags)

        let zipURL = try await persistence.backup()

        try await persistence.deleteTemplate(id: template.id)
        try await persistence.deleteTrip(id: trip.id)
        try await persistence.saveTags([])

        #expect(try await persistence.loadTemplates().isEmpty)
        #expect(try await persistence.loadTrips().isEmpty)

        try await persistence.restore(from: zipURL)

        let loadedTemplates = try await persistence.loadTemplates()
        #expect(loadedTemplates.count == 1)
        #expect(loadedTemplates.first?.name == "BeforeBackup")

        let loadedTrips = try await persistence.loadTrips()
        #expect(loadedTrips.count == 1)
        #expect(loadedTrips.first?.name == "TripBefore")

        let loadedTags = try await persistence.loadTags()
        #expect(loadedTags.contains { $0.name == "test" })
    }

    @Test("restore creates pre-restore safety snapshot")
    func restoreSafetySnapshot() async throws {
        let (persistence, tempDir) = await makeTempPersistence()
        defer { cleanup(tempDir) }

        try await persistence.saveTemplate(PackingTemplate(name: "Original"))
        let firstBackup = try await persistence.backup()

        let replacement = PackingTemplate(name: "AfterBackup")
        try await persistence.saveTemplate(replacement)

        try await persistence.restore(from: firstBackup)

        let backups = try await persistence.listBackups()
        #expect(backups.count == 2)
        #expect(backups.contains { $0.lastPathComponent.contains("pre-restore") })
    }

    @Test("restore rejects corrupt zip")
    func restoreCorruptZip() async throws {
        let (persistence, tempDir) = await makeTempPersistence()
        defer { cleanup(tempDir) }

        let bogus = tempDir.appendingPathComponent("bogus.zip")
        try Data("not a zip".utf8).write(to: bogus)

        await #expect(throws: PersistenceError.self) {
            try await persistence.restore(from: bogus)
        }
    }

    @Test("restore rejects backup with newer schema version")
    func restoreFutureSchema() async throws {
        let (persistence, tempDir) = await makeTempPersistence()
        defer { cleanup(tempDir) }

        let staging = tempDir.appendingPathComponent("staging-future")
        try FileManager.default.createDirectory(at: staging, withIntermediateDirectories: true)
        try FileManager.default.createDirectory(at: staging.appendingPathComponent("templates"), withIntermediateDirectories: true)
        let manifestJSON = #"{"schemaVersion":99,"appVersion":"9.9.9","createdAt":"2030-01-01T00:00:00Z","contents":["templates"]}"#
        try Data(manifestJSON.utf8).write(to: staging.appendingPathComponent("manifest.json"))

        let zipURL = tempDir.appendingPathComponent("future.zip")
        let p = Process()
        p.executableURL = URL(fileURLWithPath: "/usr/bin/zip")
        p.currentDirectoryURL = staging
        p.arguments = ["-r", "-q", zipURL.path, "manifest.json", "templates"]
        try p.run()
        p.waitUntilExit()

        await #expect(throws: PersistenceError.self) {
            try await persistence.restore(from: zipURL)
        }
    }

    @Test("restore rejects backup with no manifest")
    func restoreMissingManifest() async throws {
        let (persistence, tempDir) = await makeTempPersistence()
        defer { cleanup(tempDir) }

        let staging = tempDir.appendingPathComponent("staging-noman")
        try FileManager.default.createDirectory(at: staging.appendingPathComponent("templates"), withIntermediateDirectories: true)

        let zipURL = tempDir.appendingPathComponent("nomanifest.zip")
        let p = Process()
        p.executableURL = URL(fileURLWithPath: "/usr/bin/zip")
        p.currentDirectoryURL = staging
        p.arguments = ["-r", "-q", zipURL.path, "templates"]
        try p.run()
        p.waitUntilExit()

        await #expect(throws: PersistenceError.self) {
            try await persistence.restore(from: zipURL)
        }
    }

    @Test("listBackups newest first, empty when none")
    func listBackupsOrder() async throws {
        let (persistence, tempDir) = await makeTempPersistence()
        defer { cleanup(tempDir) }

        #expect(try await persistence.listBackups().isEmpty)

        let backupsDir = tempDir.appendingPathComponent("backups")
        try FileManager.default.createDirectory(at: backupsDir, withIntermediateDirectories: true)
        for ts in ["2026-04-01T120000", "2026-04-03T120000", "2026-04-02T120000"] {
            try Data().write(to: backupsDir.appendingPathComponent("packit-\(ts).zip"))
        }

        let listed = try await persistence.listBackups()
        #expect(listed.count == 3)
        #expect(listed.first?.lastPathComponent == "packit-2026-04-03T120000.zip")
        #expect(listed.last?.lastPathComponent == "packit-2026-04-01T120000.zip")
    }

    @Test("pruneBackups keeps newest N")
    func pruneKeepsNewest() async throws {
        let (persistence, tempDir) = await makeTempPersistence()
        defer { cleanup(tempDir) }

        let backupsDir = tempDir.appendingPathComponent("backups")
        try FileManager.default.createDirectory(at: backupsDir, withIntermediateDirectories: true)
        let names = [
            "packit-2026-04-01T120000.zip",
            "packit-2026-04-02T120000.zip",
            "packit-2026-04-03T120000.zip",
            "packit-2026-04-04T120000.zip",
        ]
        for name in names {
            try Data().write(to: backupsDir.appendingPathComponent(name))
        }

        try await persistence.pruneBackups(keep: 2)
        let remaining = try await persistence.listBackups().map(\.lastPathComponent)
        #expect(remaining == ["packit-2026-04-04T120000.zip", "packit-2026-04-03T120000.zip"])
    }

    @Test("backup filename collision falls through to suffixed name")
    func backupFilenameCollision() async throws {
        let (persistence, tempDir) = await makeTempPersistence()
        defer { cleanup(tempDir) }

        let first = try await persistence.backup()
        let second = try await persistence.backup()
        #expect(first.lastPathComponent != second.lastPathComponent)
    }

    // MARK: helpers

    private func unzipListing(_ zipURL: URL) throws -> [String] {
        let p = Process()
        p.executableURL = URL(fileURLWithPath: "/usr/bin/unzip")
        p.arguments = ["-l", zipURL.path]
        let pipe = Pipe()
        p.standardOutput = pipe
        try p.run()
        p.waitUntilExit()
        let data = pipe.fileHandleForReading.readDataToEndOfFile()
        let text = String(data: data, encoding: .utf8) ?? ""
        var entries: [String] = []
        for line in text.split(separator: "\n") {
            let parts = line.split(separator: " ", omittingEmptySubsequences: true)
            if parts.count >= 4, let _ = Int(parts[0]) {
                entries.append(String(parts.suffix(from: 3).joined(separator: " ")))
            }
        }
        return entries
    }
}
