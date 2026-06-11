import Foundation
import ReportKit

public enum ExtractionError: Error, Equatable, Sendable {
    case modelUnavailable(String)
    case generationFailed(String)
}

/// The on-device LLM boundary. Production uses FoundationModels behind this
/// protocol; tests and CI use `DeterministicExtractionEngine`. Nothing above
/// this protocol may know which engine is running (invariant: the MVP builds
/// and tests without any AI model present).
public protocol ExtractionEngine: Sendable {
    /// Stable identifier recorded with extraction output for provenance.
    var identifier: String { get }

    /// Extracts structured findings from one chunk of transcript/OCR text.
    /// The engine classifies and narrates — it never sees the job of
    /// producing identifiers or numbers (invariant 4).
    func extractFindings(from chunk: String, schema: FindingSchema) async throws -> [Finding]
}
