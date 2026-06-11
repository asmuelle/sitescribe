import Foundation
import ReportKit

/// Chunk → extract per chunk → merge. Order-preserving and deduplicating:
/// identical findings produced by overlapping chunks collapse to one, but
/// distinct findings are never dropped (invariant 7).
public struct ExtractionPipeline: Sendable {
    public let engine: any ExtractionEngine
    public let chunker: TranscriptChunker

    public init(engine: any ExtractionEngine, chunker: TranscriptChunker = TranscriptChunker()) {
        self.engine = engine
        self.chunker = chunker
    }

    public func extract(from text: String, schema: FindingSchema) async throws -> [Finding] {
        var merged: [Finding] = []
        var seen = Set<Finding>()
        for chunk in chunker.chunk(text) {
            let findings = try await engine.extractFindings(from: chunk, schema: schema)
            for finding in findings where !seen.contains(finding) {
                seen.insert(finding)
                merged.append(finding)
            }
        }
        return merged
    }
}
