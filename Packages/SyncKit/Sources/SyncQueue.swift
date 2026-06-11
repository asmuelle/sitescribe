import Foundation

public enum SyncState: String, Codable, Sendable {
    case queued
    case inFlight
    case done
    case failed
}

/// One queued outbound operation. M1 ships NO transport — the queue exists
/// so the data model and ordering semantics are tested before any network
/// code appears. SyncKit is the only module that will ever talk to the
/// network (invariant 2), and even then only after explicit user opt-in.
public struct SyncOperation: Codable, Hashable, Identifiable, Sendable {
    public let id: UUID
    public let entityRef: String
    public let operationKind: String
    public let payloadHash: String
    public let state: SyncState
    public let attempts: Int
    public let requiresUserOptIn: Bool

    public init(
        id: UUID = UUID(),
        entityRef: String,
        operationKind: String,
        payloadHash: String,
        state: SyncState = .queued,
        attempts: Int = 0,
        requiresUserOptIn: Bool = false
    ) {
        self.id = id
        self.entityRef = entityRef
        self.operationKind = operationKind
        self.payloadHash = payloadHash
        self.state = state
        self.attempts = attempts
        self.requiresUserOptIn = requiresUserOptIn
    }

    func with(state: SyncState, attempts: Int) -> SyncOperation {
        SyncOperation(
            id: id,
            entityRef: entityRef,
            operationKind: operationKind,
            payloadHash: payloadHash,
            state: state,
            attempts: attempts,
            requiresUserOptIn: requiresUserOptIn
        )
    }
}

/// Protocol-typed transport: tests fake it; production lands at M3+.
public protocol SyncTransport: Sendable {
    func send(_ operation: SyncOperation) async throws
}

public enum SyncError: Error, Equatable, Sendable {
    case transportFailed(String)
}

/// FIFO sync queue. Failed operations stay in the queue with their attempt
/// count incremented — nothing is dropped silently.
public actor SyncQueue {
    private var operations: [SyncOperation] = []

    public init() {}

    public var pending: [SyncOperation] {
        operations
    }

    public func enqueue(_ operation: SyncOperation) {
        operations.append(operation)
    }

    /// Drains in FIFO order. Successful operations are removed; failures
    /// are kept (state .failed, attempts+1) for the next drain.
    @discardableResult
    public func drain(using transport: any SyncTransport) async -> [SyncOperation] {
        var remaining: [SyncOperation] = []
        var completed: [SyncOperation] = []
        for operation in operations {
            do {
                try await transport.send(operation.with(state: .inFlight, attempts: operation.attempts + 1))
                completed.append(operation.with(state: .done, attempts: operation.attempts + 1))
            } catch {
                remaining.append(operation.with(state: .failed, attempts: operation.attempts + 1))
            }
        }
        operations = remaining
        return completed
    }
}
