import Foundation
import Testing
@testable import PairHop

@Suite struct LegacyMigrationTests {
    private func makeBase() throws -> URL {
        let base = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        try FileManager.default.createDirectory(at: base, withIntermediateDirectories: true)
        return base
    }

    @Test func movesTheOldFolderToTheNewName() throws {
        let base = try makeBase()
        defer { try? FileManager.default.removeItem(at: base) }
        let old = base.appendingPathComponent("PeriHop")
        try FileManager.default.createDirectory(at: old, withIntermediateDirectories: true)
        try Data("{}".utf8).write(to: old.appendingPathComponent("config.json"))

        #expect(LegacyMigration.moveSupportDirectory(in: base))
        #expect(!FileManager.default.fileExists(atPath: old.path))
        #expect(FileManager.default.fileExists(atPath: base.appendingPathComponent("PairHop/config.json").path))
    }

    @Test func leavesNewerSettingsAlone() throws {
        let base = try makeBase()
        defer { try? FileManager.default.removeItem(at: base) }
        for name in ["PeriHop", "PairHop"] {
            try FileManager.default.createDirectory(
                at: base.appendingPathComponent(name), withIntermediateDirectories: true)
        }
        #expect(!LegacyMigration.moveSupportDirectory(in: base))
        #expect(FileManager.default.fileExists(atPath: base.appendingPathComponent("PeriHop").path))
    }

    @Test func doesNothingWhenThereIsNoOldFolder() throws {
        let base = try makeBase()
        defer { try? FileManager.default.removeItem(at: base) }
        #expect(!LegacyMigration.moveSupportDirectory(in: base))
    }
}
