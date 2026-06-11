import Foundation
import Testing
@testable import StorageKit

@Suite("SQLite durability (invariant 6: capture is never lost)")
struct SQLiteDurabilityTests {
    @Test("Captures survive closing and reopening the database")
    func capturesSurviveReopen() async throws {
        let path = JobStoreContractTests.temporaryDatabasePath()
        let jobID = UUID()
        let capture = CaptureItem(jobID: jobID, kind: .photo, content: Data("plate photo".utf8))

        do {
            let store = try SQLiteJobStore(path: path)
            try await store.saveCapture(capture)
        } // store deallocated — connection closed, simulating process death

        let reopened = try SQLiteJobStore(path: path)
        let fetched = try await reopened.fetchCaptures(jobID: jobID)

        #expect(fetched.map(\.id) == [capture.id])
        #expect(fetched.first?.content == capture.content)
    }

    @Test("Jobs survive reopen alongside their captures")
    func jobsSurviveReopen() async throws {
        let path = JobStoreContractTests.temporaryDatabasePath()
        let job = Job(clientName: "Reopen Realty", siteAddress: "9 Cellar Way", jobType: .inspection)

        do {
            let store = try SQLiteJobStore(path: path)
            try await store.createJob(job)
        }

        let reopened = try SQLiteJobStore(path: path)
        let jobs = try await reopened.fetchJobs()

        #expect(jobs.map(\.id) == [job.id])
    }

    @Test("Opening a database at an invalid path throws a typed error")
    func invalidPathThrowsTypedError() {
        #expect(throws: StorageError.self) {
            _ = try SQLiteJobStore(path: "/nonexistent-root-dir/cannot/write/here.sqlite")
        }
    }
}
