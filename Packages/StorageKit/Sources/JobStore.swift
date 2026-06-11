import Foundation

/// The offline-first store boundary. SQLite-backed in the app, in-memory in
/// fast tests. No implementation of this protocol may touch the network
/// (invariant 2 — only SyncKit talks to the outside world).
public protocol JobStore: Sendable {
    func createJob(_ job: Job) async throws
    func fetchJobs() async throws -> [Job]
    func saveCapture(_ item: CaptureItem) async throws
    func fetchCaptures(jobID: UUID) async throws -> [CaptureItem]
    func updateCaptureState(id: UUID, to state: ProcessingState) async throws
}

/// In-memory store for tests and previews. Same semantics as the SQLite
/// store, including newest-first job ordering and not-found errors.
public actor InMemoryJobStore: JobStore {
    private var jobs: [UUID: Job] = [:]
    private var captures: [UUID: CaptureItem] = [:]

    public init() {}

    public func createJob(_ job: Job) async throws {
        jobs[job.id] = job
    }

    public func fetchJobs() async throws -> [Job] {
        jobs.values.sorted { $0.createdAt > $1.createdAt }
    }

    public func saveCapture(_ item: CaptureItem) async throws {
        captures[item.id] = item
    }

    public func fetchCaptures(jobID: UUID) async throws -> [CaptureItem] {
        captures.values
            .filter { $0.jobID == jobID }
            .sorted { $0.capturedAt < $1.capturedAt }
    }

    public func updateCaptureState(id: UUID, to state: ProcessingState) async throws {
        guard let existing = captures[id] else {
            throw StorageError.notFound(id)
        }
        captures[id] = existing.withProcessingState(state)
    }
}
