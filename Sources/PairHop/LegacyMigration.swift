import Foundation

/// PeriHop was renamed PairHop. Brings the saved devices, the log and the pairing code across
/// from the old names the first time the new app starts.
enum LegacyMigration {
    static func run() {
        let base = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
        if moveSupportDirectory(in: base) {
            AppLog.config.info("Moved the PeriHop settings folder to PairHop")
        }
        KeychainStore.adoptLegacyCode()
    }

    /// Renames `PeriHop` to `PairHop` inside `base`. Does nothing if `PairHop` already exists,
    /// so a Mac that ran both never loses the newer settings.
    @discardableResult
    static func moveSupportDirectory(in base: URL, fileManager: FileManager = .default) -> Bool {
        let old = base.appendingPathComponent("PeriHop", isDirectory: true)
        let new = base.appendingPathComponent("PairHop", isDirectory: true)
        guard fileManager.fileExists(atPath: old.path), !fileManager.fileExists(atPath: new.path) else {
            return false
        }
        do {
            try fileManager.moveItem(at: old, to: new)
            return true
        } catch {
            AppLog.config.error("Could not move the PeriHop settings folder: \(error)")
            return false
        }
    }
}
