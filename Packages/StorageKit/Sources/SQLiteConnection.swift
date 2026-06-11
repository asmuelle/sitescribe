import Foundation
import SQLite3

/// SQLITE_TRANSIENT — tells SQLite to copy bound buffers immediately.
private let sqliteTransient = unsafeBitCast(-1, to: sqlite3_destructor_type.self)

/// Minimal, explicit wrapper around the system SQLite3 C API. Confined to
/// the `SQLiteJobStore` actor — this class is intentionally not Sendable.
/// GRDB remains the planned upgrade path; the schema is GRDB-compatible.
final class SQLiteConnection {
    private(set) var handle: OpaquePointer?

    init(path: String) throws(StorageError) {
        let flags = SQLITE_OPEN_READWRITE | SQLITE_OPEN_CREATE | SQLITE_OPEN_FULLMUTEX
        guard sqlite3_open_v2(path, &handle, flags, nil) == SQLITE_OK else {
            let message = handle.map { String(cString: sqlite3_errmsg($0)) } ?? "unknown"
            sqlite3_close(handle)
            throw StorageError.openFailed(message)
        }
    }

    deinit {
        sqlite3_close(handle)
    }

    func execute(_ sql: String) throws(StorageError) {
        var errorPointer: UnsafeMutablePointer<CChar>?
        guard sqlite3_exec(handle, sql, nil, nil, &errorPointer) == SQLITE_OK else {
            let message = errorPointer.map { String(cString: $0) } ?? "unknown"
            sqlite3_free(errorPointer)
            throw StorageError.executionFailed(message)
        }
    }

    func prepare(_ sql: String) throws(StorageError) -> SQLiteStatement {
        var statement: OpaquePointer?
        guard sqlite3_prepare_v2(handle, sql, -1, &statement, nil) == SQLITE_OK,
              let statement
        else {
            throw StorageError.executionFailed(lastErrorMessage())
        }
        return SQLiteStatement(statement: statement, connection: self)
    }

    func changeCount() -> Int {
        Int(sqlite3_changes(handle))
    }

    func lastErrorMessage() -> String {
        handle.map { String(cString: sqlite3_errmsg($0)) } ?? "unknown"
    }
}

/// One prepared statement; finalized deterministically in `deinit`.
final class SQLiteStatement {
    private let statement: OpaquePointer
    private unowned let connection: SQLiteConnection

    init(statement: OpaquePointer, connection: SQLiteConnection) {
        self.statement = statement
        self.connection = connection
    }

    deinit {
        sqlite3_finalize(statement)
    }

    func bind(text: String, at index: Int32) {
        sqlite3_bind_text(statement, index, text, -1, sqliteTransient)
    }

    func bind(double: Double, at index: Int32) {
        sqlite3_bind_double(statement, index, double)
    }

    func bind(blob: Data, at index: Int32) {
        blob.withUnsafeBytes { buffer in
            _ = sqlite3_bind_blob(statement, index, buffer.baseAddress, Int32(buffer.count), sqliteTransient)
        }
    }

    /// Advances one row. Returns true while rows remain.
    func step() throws(StorageError) -> Bool {
        switch sqlite3_step(statement) {
        case SQLITE_ROW: return true
        case SQLITE_DONE: return false
        default: throw StorageError.executionFailed(connection.lastErrorMessage())
        }
    }

    func columnText(_ index: Int32) -> String? {
        sqlite3_column_text(statement, index).map { String(cString: $0) }
    }

    func columnDouble(_ index: Int32) -> Double {
        sqlite3_column_double(statement, index)
    }

    func columnBlob(_ index: Int32) -> Data {
        guard let pointer = sqlite3_column_blob(statement, index) else { return Data() }
        let count = Int(sqlite3_column_bytes(statement, index))
        return Data(bytes: pointer, count: count)
    }
}
