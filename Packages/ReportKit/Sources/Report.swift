import Foundation

public enum ReportStatus: String, Codable, Sendable {
    case draft
    case inReview
    case finalized
}

public enum ReportError: Error, Equatable, Sendable {
    case unreviewedFieldsRemain(count: Int)
    case alreadyFinalized
    case fieldNotFound(UUID)
}

/// An immutable report value. Every transition returns a new copy;
/// the finalize gate (invariant 5) is enforced here and tested.
public struct Report: Codable, Hashable, Identifiable, Sendable {
    public let id: UUID
    public let jobID: UUID
    public let templateID: String
    public let templateVersion: Int
    public let status: ReportStatus
    public let fields: [ExtractedField]
    public let createdAt: Date
    public let finalizedAt: Date?

    public init(
        id: UUID = UUID(),
        jobID: UUID,
        templateID: String,
        templateVersion: Int,
        status: ReportStatus = .draft,
        fields: [ExtractedField],
        createdAt: Date = Date(),
        finalizedAt: Date? = nil
    ) {
        self.id = id
        self.jobID = jobID
        self.templateID = templateID
        self.templateVersion = templateVersion
        self.status = status
        self.fields = fields
        self.createdAt = createdAt
        self.finalizedAt = finalizedAt
    }

    public var unreviewedFields: [ExtractedField] {
        fields.filter { $0.reviewState == .unreviewed }
    }

    public func fields(inSection sectionID: String) -> [ExtractedField] {
        fields.filter { $0.sectionID == sectionID }
    }

    /// Returns a copy with the given field confirmed.
    public func confirmingField(id fieldID: UUID) throws -> Report {
        try transformingField(id: fieldID) { $0.confirmed() }
    }

    /// Returns a copy with the given field edited by the user.
    public func editingField(id fieldID: UUID, newValue: String) throws -> Report {
        try transformingField(id: fieldID) { $0.edited(newValue: newValue) }
    }

    /// Finalize gate — invariant 5: no AI-derived value enters a finalized
    /// report while any field is still unreviewed.
    public func finalized(at date: Date = Date()) throws -> Report {
        guard status != .finalized else { throw ReportError.alreadyFinalized }
        let unreviewed = unreviewedFields.count
        guard unreviewed == 0 else {
            throw ReportError.unreviewedFieldsRemain(count: unreviewed)
        }
        return replacing(status: .finalized, fields: fields, finalizedAt: date)
    }

    private func transformingField(
        id fieldID: UUID,
        _ transform: (ExtractedField) -> ExtractedField
    ) throws -> Report {
        guard status != .finalized else { throw ReportError.alreadyFinalized }
        guard fields.contains(where: { $0.id == fieldID }) else {
            throw ReportError.fieldNotFound(fieldID)
        }
        let updated = fields.map { $0.id == fieldID ? transform($0) : $0 }
        return replacing(status: .inReview, fields: updated, finalizedAt: finalizedAt)
    }

    private func replacing(status: ReportStatus, fields: [ExtractedField], finalizedAt: Date?) -> Report {
        Report(
            id: id,
            jobID: jobID,
            templateID: templateID,
            templateVersion: templateVersion,
            status: status,
            fields: fields,
            createdAt: createdAt,
            finalizedAt: finalizedAt
        )
    }
}
