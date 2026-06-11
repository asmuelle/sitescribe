import ExtractionKit
import Foundation
import RecognitionKit
import ReportKit
import StorageKit

/// Records every store interaction in order so tests can assert that
/// persistence happens before any processing (invariant 6).
actor EventRecordingStore: JobStore {
    enum Event: Equatable {
        case savedCapture(UUID, ProcessingState)
        case updatedState(UUID, ProcessingState)
    }

    private(set) var events: [Event] = []
    private var captures: [UUID: CaptureItem] = [:]

    func createJob(_ job: Job) async throws {}

    func fetchJobs() async throws -> [Job] {
        []
    }

    func saveCapture(_ item: CaptureItem) async throws {
        captures[item.id] = item
        events.append(.savedCapture(item.id, item.processingState))
    }

    func fetchCaptures(jobID: UUID) async throws -> [CaptureItem] {
        captures.values.filter { $0.jobID == jobID }
    }

    func updateCaptureState(id: UUID, to state: ProcessingState) async throws {
        guard let existing = captures[id] else { throw StorageError.notFound(id) }
        captures[id] = existing.withProcessingState(state)
        events.append(.updatedState(id, state))
    }

    func capture(id: UUID) -> CaptureItem? {
        captures[id]
    }
}

/// Recognizer that always fails — used to prove the capture was persisted
/// before recognition was even attempted.
struct FailingRecognizer: TextRecognizing {
    func recognizeText(in data: Data) async throws -> [OCRBlock] {
        throw RecognitionError.recognitionFailed("simulated OCR failure")
    }
}

struct FailingEngine: ExtractionEngine {
    let identifier = "failing-engine"

    func extractFindings(from chunk: String, schema: FindingSchema) async throws -> [Finding] {
        throw ExtractionError.generationFailed("simulated model failure")
    }
}

/// URLProtocol that fails every request: registered for the offline suite so
/// any accidental network use inside the core flow fails the test loudly
/// (invariant 1 — offline-complete).
final class NetworkDenyingURLProtocol: URLProtocol {
    nonisolated(unsafe) static var attemptedRequests = 0

    override static func canInit(with request: URLRequest) -> Bool {
        attemptedRequests += 1
        return true
    }

    override static func canonicalRequest(for request: URLRequest) -> URLRequest {
        request
    }

    override func startLoading() {
        client?.urlProtocol(
            self,
            didFailWithError: URLError(.notConnectedToInternet)
        )
    }

    override func stopLoading() {}
}
