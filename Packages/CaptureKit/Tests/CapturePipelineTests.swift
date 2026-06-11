import ExtractionKit
import Foundation
import RecognitionKit
import ReportKit
import StorageKit
import Synchronization
import Testing
@testable import CaptureKit

@Suite("CapturePipeline — the M1 vertical slice")
struct CapturePipelineTests {
    private let schema: FindingSchema

    init() throws {
        schema = try HomeInspectionTemplate.loadSchema()
        // Offline suite: every test in this file runs with a URLProtocol
        // installed that fails any network request (invariant 1).
        URLProtocol.registerClass(NetworkDenyingURLProtocol.self)
    }

    private func makePipeline(
        store: any JobStore,
        recognizer: any TextRecognizing = FixtureTextRecognizer(),
        engine: any ExtractionEngine = DeterministicExtractionEngine()
    ) -> CapturePipeline {
        CapturePipeline(
            store: store,
            recognizer: recognizer,
            extraction: ExtractionPipeline(engine: engine),
            template: HomeInspectionTemplate.template,
            schema: schema
        )
    }

    private func walkthroughData() throws -> Data {
        guard let url = Bundle.module.url(
            forResource: "walkthrough_basement",
            withExtension: "txt",
            subdirectory: "Fixtures"
        ) else {
            throw FixtureError.missing
        }
        return try Data(contentsOf: url)
    }

    enum FixtureError: Error { case missing }

    @Test("Capture is persisted before any processing starts (invariant 6)")
    func capturePersistsBeforeProcessing() async throws {
        let store = EventRecordingStore()
        let pipeline = makePipeline(store: store, recognizer: FailingRecognizer())

        await #expect(throws: CapturePipelineError.self) {
            _ = try await pipeline.process(jobID: UUID(), kind: .photo, data: Data("x".utf8))
        }

        let events = await store.events
        guard case let .savedCapture(id, state)? = events.first else {
            Issue.record("First store event must be the capture save, got \(events)")
            return
        }
        #expect(state == .persisted)
        // The failed capture is still in the store, marked failed — never lost.
        let kept = await store.capture(id: id)
        #expect(kept?.processingState == .failed)
    }

    @Test("Extraction failure keeps the persisted capture and marks it failed")
    func extractionFailureKeepsCapture() async throws {
        let store = EventRecordingStore()
        let pipeline = makePipeline(store: store, engine: FailingEngine())

        await #expect(throws: CapturePipelineError.extractionFailed(
            String(describing: ExtractionError.generationFailed("simulated model failure"))
        )) {
            _ = try await pipeline.process(jobID: UUID(), kind: .photo, data: walkthroughData())
        }

        let events = await store.events
        #expect(events.contains { event in
            if case .updatedState(_, .failed) = event { return true }
            return false
        })
    }

    @Test("Full offline flow: fixture photo → draft report with both layers")
    func fullOfflineFlowProducesDraftReport() async throws {
        let store = InMemoryJobStore()
        let pipeline = makePipeline(store: store)
        let jobID = UUID()

        let result = try await pipeline.process(jobID: jobID, kind: .photo, data: walkthroughData())

        // Deterministic layer owns the identifiers — verbatim, pre-confirmed.
        let deterministic = result.report.fields.filter { $0.source == .deterministic }
        #expect(deterministic.contains { $0.value == "58STA070-12" })
        #expect(deterministic.contains { $0.value == "4517A23456" })
        #expect(deterministic.allSatisfy { $0.reviewState == .confirmed })
        #expect(deterministic.allSatisfy { $0.provenance?.captureItemID == result.capture.id })

        // LLM layer produced findings — every one starts unreviewed (invariant 5).
        let llmFields = result.report.fields.filter { $0.source == .llm }
        #expect(!llmFields.isEmpty)
        #expect(llmFields.allSatisfy { $0.reviewState == .unreviewed })

        // No network was ever attempted while the deny-protocol was active.
        #expect(NetworkDenyingURLProtocol.attemptedRequests == 0)
    }

    @Test("Stages are reported in pipeline order, never as spinners")
    func stagesReportedInOrder() async throws {
        let store = InMemoryJobStore()
        let pipeline = makePipeline(store: store)
        let collected = Mutex<[PipelineStage]>([])

        _ = try await pipeline.process(
            jobID: UUID(),
            kind: .photo,
            data: walkthroughData()
        ) { stage in
            collected.withLock { $0.append(stage) }
        }

        #expect(collected.withLock { $0 } == [.persisted, .recognized, .extracted])
    }

    @Test("Capture state in the store ends as extracted after success")
    func captureStateEndsExtracted() async throws {
        let store = InMemoryJobStore()
        let pipeline = makePipeline(store: store)
        let jobID = UUID()

        _ = try await pipeline.process(jobID: jobID, kind: .photo, data: walkthroughData())

        let captures = try await store.fetchCaptures(jobID: jobID)
        #expect(captures.map(\.processingState) == [.extracted])
    }
}
