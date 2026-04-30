import SwiftUI
import PackItKit
import UniformTypeIdentifiers
import AppKit

struct BackupSettingsView: View {
    @Environment(PackItStore.self) private var store

    @State private var backups: [URL] = []
    @State private var backupsDir: URL?
    @State private var isWorking = false
    @State private var errorMessage: String?
    @State private var pendingRestoreURL: URL?
    @State private var showRestoreConfirm = false
    @State private var pendingDeleteURL: URL?
    @State private var showDeleteConfirm = false
    @State private var showImporter = false
    @State private var keepCount: Int = 10
    @State private var cliInstallStatus: String?

    var body: some View {
        Form {
            actionsSection
            backupsSection
            retentionSection
            cliSection
        }
        .formStyle(.grouped)
        .task { await refresh() }
        .confirmationDialog(
            "Restore from backup?",
            isPresented: $showRestoreConfirm,
            presenting: pendingRestoreURL
        ) { url in
            Button("Restore", role: .destructive) {
                Task { await runRestore(url) }
            }
            Button("Cancel", role: .cancel) { pendingRestoreURL = nil }
        } message: { _ in
            Text("This replaces all current PackIt data with the backup. A safety snapshot of your current state will be saved first.")
        }
        .confirmationDialog(
            "Delete this backup?",
            isPresented: $showDeleteConfirm,
            presenting: pendingDeleteURL
        ) { url in
            Button("Delete", role: .destructive) {
                Task { await runDelete(url) }
            }
            Button("Cancel", role: .cancel) { pendingDeleteURL = nil }
        } message: { url in
            Text(url.lastPathComponent)
        }
        .fileImporter(
            isPresented: $showImporter,
            allowedContentTypes: [.zip],
            allowsMultipleSelection: false
        ) { result in
            if case .success(let urls) = result, let url = urls.first {
                pendingRestoreURL = url
                showRestoreConfirm = true
            }
        }
    }

    @ViewBuilder
    private var actionsSection: some View {
        Section {
            HStack {
                Button {
                    Task { await runBackup() }
                } label: {
                    Label("Create Backup", systemImage: "square.and.arrow.down.on.square")
                }
                .disabled(isWorking)

                Button {
                    showImporter = true
                } label: {
                    Label("Restore from File…", systemImage: "tray.and.arrow.up")
                }
                .disabled(isWorking)

                Spacer()

                if let backupsDir {
                    Button {
                        NSWorkspace.shared.activateFileViewerSelecting([backupsDir])
                    } label: {
                        Label("Reveal in Finder", systemImage: "folder")
                    }
                    .buttonStyle(.borderless)
                }

                ContextualHelpButton(topic: .backup)
            }

            if isWorking {
                HStack(spacing: 6) {
                    ProgressView().controlSize(.small)
                    Text("Working…").font(.caption).foregroundStyle(.secondary)
                }
            }

            if let errorMessage {
                Text(errorMessage)
                    .font(.caption)
                    .foregroundStyle(.red)
            }
        }
    }

    @ViewBuilder
    private var backupsSection: some View {
        Section("Backups") {
            if backups.isEmpty {
                Text("No backups yet. Click Create Backup to make one, or schedule daily backups via goback.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            } else {
                ForEach(backups, id: \.self) { url in
                    backupRow(url)
                }
            }
        }
    }

    @ViewBuilder
    private var retentionSection: some View {
        Section("Retention") {
            HStack {
                Stepper(value: $keepCount, in: 1...50) {
                    Text("Keep \(keepCount) most recent")
                }
                Spacer()
                Button("Prune Now") {
                    Task { await runPrune() }
                }
                .disabled(isWorking || backups.count <= keepCount)
            }
            Text("Goback copies daily backups to your archive vault, then sweeps this staging area. This setting only matters if goback is paused or you make many manual backups.")
                .font(.caption)
                .foregroundStyle(.tertiary)
        }
    }

    @ViewBuilder
    private var cliSection: some View {
        Section("Command-Line Tool") {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text("packit-backup")
                        .font(.system(.body, design: .monospaced))
                    Text("Headless CLI for backup schedulers like goback.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                Spacer()
                Button(cliInstalled ? "Reinstall" : "Install…") {
                    installCLI()
                }
            }
            if let cliInstallStatus {
                Text(cliInstallStatus)
                    .font(.caption)
                    .foregroundColor(cliInstallStatus.hasPrefix("Installed") ? .secondary : .red)
            }
        }
    }

    @ViewBuilder
    private func backupRow(_ url: URL) -> some View {
        let isPreRestore = url.lastPathComponent.contains("pre-restore")
        HStack(spacing: 8) {
            Image(systemName: isPreRestore ? "clock.arrow.circlepath" : "shippingbox")
                .foregroundStyle(isPreRestore ? .orange : .secondary)
                .frame(width: 18)
            VStack(alignment: .leading, spacing: 2) {
                Text(url.lastPathComponent)
                    .font(.system(.body, design: .monospaced))
                    .lineLimit(1)
                    .truncationMode(.middle)
                if let size = fileSize(url) {
                    Text(size).font(.caption).foregroundStyle(.tertiary)
                }
            }
            Spacer()
            Button("Restore") {
                pendingRestoreURL = url
                showRestoreConfirm = true
            }
            .buttonStyle(.borderless)
            .disabled(isWorking)
            Button {
                pendingDeleteURL = url
                showDeleteConfirm = true
            } label: {
                Image(systemName: "trash")
            }
            .buttonStyle(.borderless)
            .disabled(isWorking)
            .help("Delete this backup")
        }
    }

    private func fileSize(_ url: URL) -> String? {
        guard let attrs = try? FileManager.default.attributesOfItem(atPath: url.path),
              let bytes = attrs[.size] as? Int64 else { return nil }
        return ByteCountFormatter.string(fromByteCount: bytes, countStyle: .file)
    }

    private func refresh() async {
        backupsDir = await store.backupsDirectory
        do {
            backups = try await store.listBackups()
        } catch {
            errorMessage = "Could not list backups: \(error.localizedDescription)"
        }
    }

    private func runBackup() async {
        isWorking = true
        errorMessage = nil
        defer { isWorking = false }
        do {
            _ = try await store.createBackup()
            await refresh()
        } catch {
            errorMessage = "Backup failed: \(error.localizedDescription)"
        }
    }

    private func runRestore(_ url: URL) async {
        isWorking = true
        errorMessage = nil
        defer { isWorking = false }
        do {
            try await store.restoreBackup(from: url)
            pendingRestoreURL = nil
            await refresh()
        } catch {
            errorMessage = "Restore failed: \(error.localizedDescription)"
        }
    }

    private func runDelete(_ url: URL) async {
        isWorking = true
        errorMessage = nil
        defer { isWorking = false }
        do {
            try await store.deleteBackup(at: url)
            pendingDeleteURL = nil
            await refresh()
        } catch {
            errorMessage = "Delete failed: \(error.localizedDescription)"
        }
    }

    private func runPrune() async {
        isWorking = true
        errorMessage = nil
        defer { isWorking = false }
        do {
            try await store.pruneBackups(keep: keepCount)
            await refresh()
        } catch {
            errorMessage = "Prune failed: \(error.localizedDescription)"
        }
    }

    // MARK: - CLI Installation

    private var bundledCLIURL: URL? {
        Bundle.main.executableURL?.deletingLastPathComponent().appendingPathComponent("packit-backup")
    }

    private var cliSymlinkURL: URL {
        FileManager.default.homeDirectoryForCurrentUser
            .appendingPathComponent(".local/bin/packit-backup")
    }

    private var cliInstalled: Bool {
        guard let bundled = bundledCLIURL else { return false }
        let target = cliSymlinkURL
        guard FileManager.default.fileExists(atPath: target.path) else { return false }
        if let resolved = try? FileManager.default.destinationOfSymbolicLink(atPath: target.path) {
            return resolved == bundled.path
        }
        return false
    }

    private func installCLI() {
        cliInstallStatus = nil
        guard let bundled = bundledCLIURL,
              FileManager.default.fileExists(atPath: bundled.path) else {
            cliInstallStatus = "CLI not bundled in this build. Use `make install-cli` from source."
            return
        }
        let dest = cliSymlinkURL
        let fm = FileManager.default
        do {
            try fm.createDirectory(at: dest.deletingLastPathComponent(), withIntermediateDirectories: true)
            if fm.fileExists(atPath: dest.path) {
                try fm.removeItem(at: dest)
            }
            try fm.createSymbolicLink(at: dest, withDestinationURL: bundled)
            cliInstallStatus = "Installed at \(dest.path). Make sure ~/.local/bin is on your PATH."
        } catch {
            cliInstallStatus = "Install failed: \(error.localizedDescription)"
        }
    }
}
