import Foundation
import Observation
import ReportKit

/// Drives the trust gate: every AI field must be confirmed or edited before
/// finalize unlocks (invariant 5). All report transitions are immutable —
/// the view model swaps whole snapshots.
@MainActor
@Observable
public final class ReviewViewModel {
    public private(set) var report: Report
    public private(set) var errorMessage: String?

    public init(report: Report) {
        self.report = report
    }

    public var canFinalize: Bool {
        report.status != .finalized && report.unreviewedFields.isEmpty
    }

    public var unreviewedCount: Int {
        report.unreviewedFields.count
    }

    public func fields(inSection sectionID: String) -> [ExtractedField] {
        report.fields(inSection: sectionID)
    }

    public func confirm(fieldID: UUID) {
        apply { try $0.confirmingField(id: fieldID) }
    }

    public func edit(fieldID: UUID, newValue: String) {
        let trimmed = newValue.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty else {
            errorMessage = "A field cannot be edited to an empty value."
            return
        }
        apply { try $0.editingField(id: fieldID, newValue: trimmed) }
    }

    /// Returns the finalized report, or nil (with a user-facing message)
    /// while unreviewed fields remain.
    public func finalize() -> Report? {
        do {
            let finalized = try report.finalized()
            report = finalized
            errorMessage = nil
            return finalized
        } catch let error as ReportError {
            errorMessage = Self.message(for: error)
            return nil
        } catch {
            errorMessage = "Could not finalize the report."
            return nil
        }
    }

    private func apply(_ transform: (Report) throws -> Report) {
        do {
            report = try transform(report)
            errorMessage = nil
        } catch let error as ReportError {
            errorMessage = Self.message(for: error)
        } catch {
            errorMessage = "Could not update the field."
        }
    }

    private static func message(for error: ReportError) -> String {
        switch error {
        case let .unreviewedFieldsRemain(count):
            "Review \(count) remaining AI field\(count == 1 ? "" : "s") before finalizing."
        case .alreadyFinalized:
            "This report is finalized and can no longer be edited."
        case .fieldNotFound:
            "That field no longer exists in this report."
        }
    }
}
