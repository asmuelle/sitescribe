import Foundation
import ReportKit
import Testing
@testable import ExtractionKit

/// Engine spy that records the chunks it was handed and replays canned
/// findings — lets the pipeline be tested independent of any rules.
private actor ChunkRecorder {
    private(set) var chunks: [String] = []

    func record(_ chunk: String) {
        chunks.append(chunk)
    }
}

private struct SpyEngine: ExtractionEngine {
    let identifier = "spy"
    let recorder: ChunkRecorder
    let findingsPerChunk: [Finding]

    func extractFindings(from chunk: String, schema: FindingSchema) async throws -> [Finding] {
        await recorder.record(chunk)
        return findingsPerChunk
    }
}

@Suite("ExtractionPipeline")
struct ExtractionPipelineTests {
    private let schema: FindingSchema

    init() throws {
        schema = try HomeInspectionTemplate.loadSchema()
    }

    private func sampleFinding(_ defect: String) -> Finding {
        Finding(defect: defect, location: "Basement", severity: .moderate, recommendedAction: "Evaluate.")
    }

    @Test("Feeds every chunk to the engine — nothing is skipped")
    func feedsEveryChunk() async throws {
        let recorder = ChunkRecorder()
        let engine = SpyEngine(recorder: recorder, findingsPerChunk: [])
        let pipeline = ExtractionPipeline(engine: engine, chunker: TranscriptChunker(maxChunkLength: 10))
        let text = "0123456789ABCDEFGHIJ0123"

        _ = try await pipeline.extract(from: text, schema: schema)

        let chunks = await recorder.chunks
        #expect(chunks.joined() == text)
        #expect(chunks.count == 3)
    }

    @Test("Identical findings from overlapping chunks are merged once")
    func mergesDuplicateFindings() async throws {
        let recorder = ChunkRecorder()
        let duplicate = sampleFinding("Corrosion on heat exchanger")
        let engine = SpyEngine(recorder: recorder, findingsPerChunk: [duplicate])
        let pipeline = ExtractionPipeline(engine: engine, chunker: TranscriptChunker(maxChunkLength: 5))

        let findings = try await pipeline.extract(from: "aaaaabbbbb", schema: schema)

        #expect(findings == [duplicate])
    }

    @Test("Engine failures propagate as errors, never as silent drops")
    func engineFailuresPropagate() async {
        struct FailingEngine: ExtractionEngine {
            let identifier = "failing"
            func extractFindings(from chunk: String, schema: FindingSchema) async throws -> [Finding] {
                throw ExtractionError.generationFailed("boom")
            }
        }
        let pipeline = ExtractionPipeline(engine: FailingEngine())

        await #expect(throws: ExtractionError.generationFailed("boom")) {
            _ = try await pipeline.extract(from: "some notes", schema: schema)
        }
    }
}
