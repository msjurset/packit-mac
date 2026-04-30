import Foundation
import PackItKit

@main
struct PackItBackupCLI {
    static func main() async {
        let args = CommandLine.arguments
        let command = args.count > 1 ? args[1] : "backup"
        let persistence = Persistence.shared

        switch command {
        case "backup":
            await runBackup(persistence)
        case "restore":
            guard args.count > 2 else {
                printError("Usage: packit-backup restore <path-to-zip>")
                exit(2)
            }
            await runRestore(persistence, path: args[2])
        case "list":
            await runList(persistence)
        case "prune":
            let keep = args.count > 2 ? Int(args[2]) ?? 10 : 10
            await runPrune(persistence, keep: keep)
        case "-h", "--help", "help":
            printUsage()
        default:
            printError("Unknown command: \(command)")
            printUsage()
            exit(2)
        }
    }

    static func runBackup(_ p: Persistence) async {
        do {
            let url = try await p.backup()
            print("Backup created: \(url.path)")
        } catch {
            printError("Backup failed: \(error.localizedDescription)")
            exit(1)
        }
    }

    static func runRestore(_ p: Persistence, path: String) async {
        let url = URL(fileURLWithPath: path)
        guard FileManager.default.fileExists(atPath: url.path) else {
            printError("File not found: \(path)")
            exit(1)
        }
        do {
            try await p.restore(from: url)
            print("Restored from: \(url.path)")
        } catch {
            printError("Restore failed: \(error.localizedDescription)")
            exit(1)
        }
    }

    static func runList(_ p: Persistence) async {
        do {
            let backups = try await p.listBackups()
            if backups.isEmpty {
                print("No backups found")
                return
            }
            for url in backups {
                let attrs = try? FileManager.default.attributesOfItem(atPath: url.path)
                let size = (attrs?[.size] as? Int64) ?? 0
                let sizeStr = ByteCountFormatter.string(fromByteCount: size, countStyle: .file)
                print("\(url.lastPathComponent)  (\(sizeStr))")
            }
        } catch {
            printError("List failed: \(error.localizedDescription)")
            exit(1)
        }
    }

    static func runPrune(_ p: Persistence, keep: Int) async {
        do {
            let before = try await p.listBackups().count
            try await p.pruneBackups(keep: keep)
            let after = try await p.listBackups().count
            print("Pruned \(before - after) backup(s); \(after) remaining")
        } catch {
            printError("Prune failed: \(error.localizedDescription)")
            exit(1)
        }
    }

    static func printUsage() {
        print("""
        Usage: packit-backup <command> [args]

        Commands:
          backup           Create a new backup zip in ~/.packit/backups/
                           (default if no command is given)
          restore <zip>    Restore from a backup zip; current state is auto-saved
                           as a pre-restore snapshot first
          list             List backups newest-first
          prune [N]        Keep only the N newest backups (default 10)
          help             Show this message

        Exit codes: 0 success, 1 runtime error, 2 usage error.
        """)
    }

    static func printError(_ msg: String) {
        FileHandle.standardError.write(Data((msg + "\n").utf8))
    }
}
