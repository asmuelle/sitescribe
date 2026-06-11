import Foundation

/// Durable SQLite-backed store. WAL journaling so a crash/kill between
/// capture and processing never loses a persisted capture (invariant 6 —
/// covered by the reopen test).
public actor SQLiteJobStore: JobStore {
    private let connection: SQLiteConnection

    public init(path: String) throws {
        let connection = try SQLiteConnection(path: path)
        try Self.migrate(connection)
        self.connection = connection
    }

    private static func migrate(_ connection: SQLiteConnection) throws(StorageError) {
        try connection.execute("PRAGMA journal_mode=WAL;")
        try connection.execute("""
        CREATE TABLE IF NOT EXISTS jobs (
            id TEXT PRIMARY KEY,
            client_name TEXT NOT NULL,
            site_address TEXT NOT NULL,
            job_type TEXT NOT NULL,
            created_at REAL NOT NULL
        );
        CREATE TABLE IF NOT EXISTS captures (
            id TEXT PRIMARY KEY,
            job_id TEXT NOT NULL,
            kind TEXT NOT NULL,
            content BLOB NOT NULL,
            captured_at REAL NOT NULL,
            processing_state TEXT NOT NULL
        );
        CREATE INDEX IF NOT EXISTS idx_captures_job ON captures(job_id);
        """)
    }

    public func createJob(_ job: Job) async throws {
        let statement = try connection.prepare("""
        INSERT OR REPLACE INTO jobs (id, client_name, site_address, job_type, created_at)
        VALUES (?, ?, ?, ?, ?);
        """)
        statement.bind(text: job.id.uuidString, at: 1)
        statement.bind(text: job.clientName, at: 2)
        statement.bind(text: job.siteAddress, at: 3)
        statement.bind(text: job.jobType.rawValue, at: 4)
        statement.bind(double: job.createdAt.timeIntervalSince1970, at: 5)
        _ = try statement.step()
    }

    public func fetchJobs() async throws -> [Job] {
        let statement = try connection.prepare("""
        SELECT id, client_name, site_address, job_type, created_at
        FROM jobs ORDER BY created_at DESC;
        """)
        var jobs: [Job] = []
        while try statement.step() {
            try jobs.append(Self.job(from: statement))
        }
        return jobs
    }

    public func saveCapture(_ item: CaptureItem) async throws {
        let statement = try connection.prepare("""
        INSERT OR REPLACE INTO captures (id, job_id, kind, content, captured_at, processing_state)
        VALUES (?, ?, ?, ?, ?, ?);
        """)
        statement.bind(text: item.id.uuidString, at: 1)
        statement.bind(text: item.jobID.uuidString, at: 2)
        statement.bind(text: item.kind.rawValue, at: 3)
        statement.bind(blob: item.content, at: 4)
        statement.bind(double: item.capturedAt.timeIntervalSince1970, at: 5)
        statement.bind(text: item.processingState.rawValue, at: 6)
        _ = try statement.step()
    }

    public func fetchCaptures(jobID: UUID) async throws -> [CaptureItem] {
        let statement = try connection.prepare("""
        SELECT id, job_id, kind, content, captured_at, processing_state
        FROM captures WHERE job_id = ? ORDER BY captured_at ASC;
        """)
        statement.bind(text: jobID.uuidString, at: 1)
        var items: [CaptureItem] = []
        while try statement.step() {
            try items.append(Self.capture(from: statement))
        }
        return items
    }

    public func updateCaptureState(id: UUID, to state: ProcessingState) async throws {
        let statement = try connection.prepare(
            "UPDATE captures SET processing_state = ? WHERE id = ?;"
        )
        statement.bind(text: state.rawValue, at: 1)
        statement.bind(text: id.uuidString, at: 2)
        _ = try statement.step()
        guard connection.changeCount() > 0 else {
            throw StorageError.notFound(id)
        }
    }

    // MARK: - Row mapping

    private static func job(from statement: SQLiteStatement) throws(StorageError) -> Job {
        guard let idText = statement.columnText(0), let id = UUID(uuidString: idText),
              let clientName = statement.columnText(1),
              let siteAddress = statement.columnText(2),
              let typeText = statement.columnText(3), let jobType = JobType(rawValue: typeText)
        else {
            throw StorageError.corruptRow("jobs")
        }
        return Job(
            id: id,
            clientName: clientName,
            siteAddress: siteAddress,
            jobType: jobType,
            createdAt: Date(timeIntervalSince1970: statement.columnDouble(4))
        )
    }

    private static func capture(from statement: SQLiteStatement) throws(StorageError) -> CaptureItem {
        guard let idText = statement.columnText(0), let id = UUID(uuidString: idText),
              let jobText = statement.columnText(1), let jobID = UUID(uuidString: jobText),
              let kindText = statement.columnText(2), let kind = CaptureKind(rawValue: kindText),
              let stateText = statement.columnText(5),
              let state = ProcessingState(rawValue: stateText)
        else {
            throw StorageError.corruptRow("captures")
        }
        return CaptureItem(
            id: id,
            jobID: jobID,
            kind: kind,
            content: statement.columnBlob(3),
            capturedAt: Date(timeIntervalSince1970: statement.columnDouble(4)),
            processingState: state
        )
    }
}
