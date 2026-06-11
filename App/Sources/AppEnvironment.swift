import CaptureKit
import ExtractionKit
import Foundation
import os
import RecognitionKit
import ReportKit
import StorageKit

/// Composition root. Everything on-device: SQLite store, deterministic
/// recognizer over the bundled sample captures, and the deterministic
/// extraction engine (the M1 stand-in behind the ExtractionEngine protocol —
/// FoundationModels wiring is progressive enhancement, M2).
@MainActor
@Observable
final class AppEnvironment {
    private static let logger = Logger(subsystem: "com.sitescribe.app", category: "boot")

    let store: any JobStore
    let pipeline: CapturePipeline
    let template: ReportTemplate
    /// Non-nil when boot degraded (e.g. SQLite unavailable → in-memory store).
    let bootNote: String?

    init() throws {
        template = HomeInspectionTemplate.template
        let schema = try HomeInspectionTemplate.loadSchema()

        let (store, note) = Self.makeStore()
        self.store = store
        bootNote = note

        pipeline = CapturePipeline(
            store: store,
            recognizer: FixtureTextRecognizer(),
            extraction: ExtractionPipeline(engine: DeterministicExtractionEngine()),
            template: template,
            schema: schema
        )
    }

    /// Durable SQLite store; if opening it fails the app still works for the
    /// session on an in-memory store and says so instead of crashing.
    private static func makeStore() -> (any JobStore, String?) {
        do {
            let directory = try FileManager.default.url(
                for: .applicationSupportDirectory,
                in: .userDomainMask,
                appropriateFor: nil,
                create: true
            )
            let path = directory.appendingPathComponent("sitescribe.sqlite").path
            return try (SQLiteJobStore(path: path), nil)
        } catch {
            logger.error("SQLite store unavailable, using in-memory: \(String(describing: error))")
            return (InMemoryJobStore(), "Storage degraded — data will not survive relaunch.")
        }
    }
}
