import Foundation
import Testing

/// Static no-egress audit (invariant 2): only SyncKit may ever import a
/// networking client, and in M1 not even SyncKit does. This walks every
/// committed Swift source under Packages/ and App/ and fails on any
/// networking import or URLSession use outside SyncKit.
@Suite("No-egress static audit (invariant 2)")
struct EgressAuditTests {
    private static let forbiddenMarkers = [
        "import Network",
        "URLSession",
        "import CFNetwork",
    ]

    private static func repositoryRoot() -> URL {
        // …/Packages/SyncKit/Tests/EgressAuditTests.swift → repo root
        URL(fileURLWithPath: #filePath)
            .deletingLastPathComponent() // Tests
            .deletingLastPathComponent() // SyncKit
            .deletingLastPathComponent() // Packages
            .deletingLastPathComponent() // repo root
    }

    private static func sourceFiles(under directory: URL) -> [URL] {
        guard let enumerator = FileManager.default.enumerator(
            at: directory,
            includingPropertiesForKeys: nil
        ) else { return [] }
        return enumerator.compactMap { element in
            guard let url = element as? URL, url.pathExtension == "swift" else { return nil }
            return url
        }
    }

    @Test("No networking imports or URLSession use outside SyncKit sources")
    func noNetworkingOutsideSyncKit() throws {
        let root = Self.repositoryRoot()
        let scanRoots = [
            root.appendingPathComponent("Packages"),
            root.appendingPathComponent("App"),
        ]
        var violations: [String] = []
        for scanRoot in scanRoots {
            for file in Self.sourceFiles(under: scanRoot) {
                let path = file.path
                guard !path.contains("/SyncKit/Sources/") else { continue }
                guard !path.contains("/Tests/") else { continue } // test doubles may reference URLProtocol
                let contents = try String(contentsOf: file, encoding: .utf8)
                for marker in Self.forbiddenMarkers where contents.contains(marker) {
                    violations.append("\(file.lastPathComponent): \(marker)")
                }
            }
        }
        #expect(violations.isEmpty, "Egress audit violations: \(violations)")
    }

    @Test("The audit actually scans sources (sanity check, not vacuously green)")
    func auditScansSources() {
        let packages = Self.repositoryRoot().appendingPathComponent("Packages")

        let files = Self.sourceFiles(under: packages)

        #expect(files.count > 10, "Expected to scan the package tree, found \(files.count) files")
    }
}
