import Foundation
import StorageKit
import Testing
@testable import JobsFeature

@Suite("JobsViewModel")
@MainActor
struct JobsViewModelTests {
    @Test("Creating a job adds it to the list")
    func createJobAddsToList() async {
        let viewModel = JobsViewModel(store: InMemoryJobStore())

        let job = await viewModel.createJob(
            clientName: "Hartmann Realty",
            siteAddress: "12 Cellar Way",
            jobType: .inspection
        )

        #expect(job != nil)
        #expect(viewModel.jobs.map(\.id) == [job?.id])
        #expect(viewModel.errorMessage == nil)
    }

    @Test("Blank client or address is rejected with a user-facing message")
    func blankInputIsRejected() async {
        let viewModel = JobsViewModel(store: InMemoryJobStore())

        let job = await viewModel.createJob(clientName: "  ", siteAddress: "", jobType: .service)

        #expect(job == nil)
        #expect(viewModel.jobs.isEmpty)
        #expect(viewModel.errorMessage != nil)
    }

    @Test("Load reflects jobs created elsewhere, newest first")
    func loadReflectsStoreOrdering() async throws {
        let store = InMemoryJobStore()
        let older = Job(
            clientName: "A", siteAddress: "1", jobType: .inspection,
            createdAt: Date(timeIntervalSince1970: 100)
        )
        let newer = Job(
            clientName: "B", siteAddress: "2", jobType: .receiptRun,
            createdAt: Date(timeIntervalSince1970: 200)
        )
        try await store.createJob(older)
        try await store.createJob(newer)
        let viewModel = JobsViewModel(store: store)

        await viewModel.load()

        #expect(viewModel.jobs.map(\.id) == [newer.id, older.id])
    }
}
