import Foundation

public enum JobType: String, Codable, CaseIterable, Sendable {
    case inspection
    case adjustment
    case service
    case receiptRun
}

public struct Job: Codable, Hashable, Identifiable, Sendable {
    public let id: UUID
    public let clientName: String
    public let siteAddress: String
    public let jobType: JobType
    public let createdAt: Date

    public init(
        id: UUID = UUID(),
        clientName: String,
        siteAddress: String,
        jobType: JobType,
        createdAt: Date = Date()
    ) {
        self.id = id
        self.clientName = clientName
        self.siteAddress = siteAddress
        self.jobType = jobType
        self.createdAt = createdAt
    }
}

public enum CaptureKind: String, Codable, Sendable {
    case photo
    case audio
    case documentScan
}

/// Lifecycle of a capture through the pipeline. `persisted` is written
/// BEFORE any processing starts — invariant 6 (capture is never lost).
public enum ProcessingState: String, Codable, Sendable {
    case persisted
    case recognized
    case extracted
    case failed
}

public struct CaptureItem: Codable, Hashable, Identifiable, Sendable {
    public let id: UUID
    public let jobID: UUID
    public let kind: CaptureKind
    /// M1 stores the capture payload inline (photo bytes / scan text);
    /// file-based storage with URLs arrives with real camera capture.
    public let content: Data
    public let capturedAt: Date
    public let processingState: ProcessingState

    public init(
        id: UUID = UUID(),
        jobID: UUID,
        kind: CaptureKind,
        content: Data,
        capturedAt: Date = Date(),
        processingState: ProcessingState = .persisted
    ) {
        self.id = id
        self.jobID = jobID
        self.kind = kind
        self.content = content
        self.capturedAt = capturedAt
        self.processingState = processingState
    }

    /// Immutable update — returns a copy in the new state.
    public func withProcessingState(_ state: ProcessingState) -> CaptureItem {
        CaptureItem(
            id: id,
            jobID: jobID,
            kind: kind,
            content: content,
            capturedAt: capturedAt,
            processingState: state
        )
    }
}

public enum StorageError: Error, Equatable, Sendable {
    case openFailed(String)
    case migrationFailed(String)
    case executionFailed(String)
    case notFound(UUID)
    case corruptRow(String)
}
