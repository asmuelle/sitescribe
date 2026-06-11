import Foundation
import Observation
import StorageKit

/// Jobs list state. All mutations flow through the store; the view model
/// only holds the latest immutable snapshot.
@MainActor
@Observable
public final class JobsViewModel {
    public private(set) var jobs: [Job] = []
    public private(set) var errorMessage: String?

    private let store: any JobStore

    public init(store: any JobStore) {
        self.store = store
    }

    public func load() async {
        do {
            jobs = try await store.fetchJobs()
            errorMessage = nil
        } catch {
            errorMessage = "Could not load jobs. Pull to retry."
        }
    }

    @discardableResult
    public func createJob(clientName: String, siteAddress: String, jobType: JobType) async -> Job? {
        let trimmedClient = clientName.trimmingCharacters(in: .whitespaces)
        let trimmedAddress = siteAddress.trimmingCharacters(in: .whitespaces)
        guard !trimmedClient.isEmpty, !trimmedAddress.isEmpty else {
            errorMessage = "Client name and site address are required."
            return nil
        }
        let job = Job(clientName: trimmedClient, siteAddress: trimmedAddress, jobType: jobType)
        do {
            try await store.createJob(job)
            await load()
            return job
        } catch {
            errorMessage = "Could not save the job. Try again."
            return nil
        }
    }
}
