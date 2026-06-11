import Foundation
import Testing
@testable import StorageKit

/// Both store implementations must satisfy the same contract — these tests
/// run the shared assertions against each.
@Suite("JobStore contract (SQLite + in-memory)")
struct JobStoreContractTests {
    private func makeStores() throws -> [(name: String, store: any JobStore)] {
        let path = Self.temporaryDatabasePath()
        return try [
            ("InMemoryJobStore", InMemoryJobStore()),
            ("SQLiteJobStore", SQLiteJobStore(path: path)),
        ]
    }

    static func temporaryDatabasePath() -> String {
        FileManager.default.temporaryDirectory
            .appendingPathComponent("sitescribe-test-\(UUID().uuidString).sqlite")
            .path
    }

    @Test("Created jobs come back newest first")
    func jobsComeBackNewestFirst() async throws {
        for (name, store) in try makeStores() {
            let older = Job(
                clientName: "A", siteAddress: "1 Main St", jobType: .inspection,
                createdAt: Date(timeIntervalSince1970: 1000)
            )
            let newer = Job(
                clientName: "B", siteAddress: "2 Main St", jobType: .receiptRun,
                createdAt: Date(timeIntervalSince1970: 2000)
            )

            try await store.createJob(older)
            try await store.createJob(newer)
            let jobs = try await store.fetchJobs()

            #expect(jobs.map(\.id) == [newer.id, older.id], "\(name) ordering")
        }
    }

    @Test("Captures round-trip with their payload bytes intact")
    func capturesRoundTripPayload() async throws {
        for (name, store) in try makeStores() {
            let jobID = UUID()
            let payload = Data("SERIAL NO: 4517A23456".utf8)
            let capture = CaptureItem(jobID: jobID, kind: .photo, content: payload)

            try await store.saveCapture(capture)
            let fetched = try await store.fetchCaptures(jobID: jobID)

            #expect(fetched.count == 1, "\(name) capture count")
            #expect(fetched.first?.content == payload, "\(name) payload integrity")
            #expect(fetched.first?.processingState == .persisted, "\(name) initial state")
        }
    }

    @Test("Processing state transitions are persisted")
    func processingStateTransitionsPersist() async throws {
        for (name, store) in try makeStores() {
            let capture = CaptureItem(jobID: UUID(), kind: .photo, content: Data("x".utf8))
            try await store.saveCapture(capture)

            try await store.updateCaptureState(id: capture.id, to: .recognized)
            let fetched = try await store.fetchCaptures(jobID: capture.jobID)

            #expect(fetched.first?.processingState == .recognized, "\(name) state update")
        }
    }

    @Test("Updating an unknown capture fails loudly, never silently")
    func updatingUnknownCaptureFails() async throws {
        for (_, store) in try makeStores() {
            let ghost = UUID()

            await #expect(throws: StorageError.notFound(ghost)) {
                try await store.updateCaptureState(id: ghost, to: .extracted)
            }
        }
    }
}
