import Foundation
import Testing
@testable import SyncKit

private actor RecordingTransport: SyncTransport {
    private(set) var sent: [SyncOperation] = []
    private let failingRefs: Set<String>

    init(failingRefs: Set<String> = []) {
        self.failingRefs = failingRefs
    }

    func send(_ operation: SyncOperation) async throws {
        sent.append(operation)
        if failingRefs.contains(operation.entityRef) {
            throw SyncError.transportFailed(operation.entityRef)
        }
    }
}

@Suite("SyncQueue — ordering and no-silent-loss semantics")
struct SyncQueueTests {
    private func operation(_ ref: String) -> SyncOperation {
        SyncOperation(entityRef: ref, operationKind: "upsert", payloadHash: "hash-\(ref)")
    }

    @Test("Drains in FIFO order")
    func drainsInFIFOOrder() async {
        let queue = SyncQueue()
        let transport = RecordingTransport()
        await queue.enqueue(operation("report/1"))
        await queue.enqueue(operation("report/2"))
        await queue.enqueue(operation("report/3"))

        await queue.drain(using: transport)

        let refs = await transport.sent.map(\.entityRef)
        #expect(refs == ["report/1", "report/2", "report/3"])
        #expect(await queue.pending.isEmpty)
    }

    @Test("Failed operations stay queued with attempts incremented")
    func failuresStayQueued() async {
        let queue = SyncQueue()
        let transport = RecordingTransport(failingRefs: ["report/2"])
        await queue.enqueue(operation("report/1"))
        await queue.enqueue(operation("report/2"))

        let completed = await queue.drain(using: transport)

        #expect(completed.map(\.entityRef) == ["report/1"])
        let pending = await queue.pending
        #expect(pending.map(\.entityRef) == ["report/2"])
        #expect(pending.first?.state == .failed)
        #expect(pending.first?.attempts == 1)
    }

    @Test("Retried operations keep counting attempts")
    func retriesKeepCounting() async {
        let queue = SyncQueue()
        let transport = RecordingTransport(failingRefs: ["report/1"])
        await queue.enqueue(operation("report/1"))

        await queue.drain(using: transport)
        await queue.drain(using: transport)

        #expect(await queue.pending.first?.attempts == 2)
    }

    @Test("Cloud-polish operations carry the opt-in flag (invariant 2)")
    func optInFlagIsCarried() {
        let polish = SyncOperation(
            entityRef: "report/9",
            operationKind: "cloudPolish",
            payloadHash: "h",
            requiresUserOptIn: true
        )

        #expect(polish.requiresUserOptIn)
        #expect(polish.state == .queued)
    }
}
