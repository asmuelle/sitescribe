import Foundation
import Testing
@testable import ReportKit

@Suite("Report review lifecycle and finalize gate (invariant 5)")
struct ReportTests {
    private func makeField(
        source: FieldSource = .llm,
        reviewState: ReviewState = .unreviewed
    ) -> ExtractedField {
        ExtractedField(
            sectionID: "findings",
            schemaKeyPath: "findings[0].defect",
            value: "Corrosion on heat exchanger",
            source: source,
            provenance: Provenance(captureItemID: UUID()),
            confidence: 0.5,
            reviewState: reviewState
        )
    }

    private func makeReport(fields: [ExtractedField]) -> Report {
        Report(jobID: UUID(), templateID: "home-inspection-general", templateVersion: 1, fields: fields)
    }

    @Test("Finalize is blocked while any field is unreviewed")
    func finalizeBlockedWhileUnreviewed() {
        let report = makeReport(fields: [makeField()])

        #expect(throws: ReportError.unreviewedFieldsRemain(count: 1)) {
            _ = try report.finalized()
        }
    }

    @Test("Confirming every field unlocks finalize")
    func confirmingUnlocksFinalize() throws {
        let field = makeField()
        let report = makeReport(fields: [field])

        let reviewed = try report.confirmingField(id: field.id)
        let finalized = try reviewed.finalized(at: Date(timeIntervalSince1970: 99))

        #expect(finalized.status == .finalized)
        #expect(finalized.finalizedAt == Date(timeIntervalSince1970: 99))
    }

    @Test("Editing a field marks it edited and re-sources it as manual")
    func editingMarksFieldManual() throws {
        let field = makeField()
        let report = makeReport(fields: [field])

        let edited = try report.editingField(id: field.id, newValue: "Surface rust only")

        let updated = edited.fields[0]
        #expect(updated.value == "Surface rust only")
        #expect(updated.source == .manual)
        #expect(updated.reviewState == .edited)
        // Original report untouched — immutable update.
        #expect(report.fields[0].value == "Corrosion on heat exchanger")
    }

    @Test("Transforming an unknown field fails loudly")
    func unknownFieldFailsLoudly() {
        let report = makeReport(fields: [makeField()])
        let ghost = UUID()

        #expect(throws: ReportError.fieldNotFound(ghost)) {
            _ = try report.confirmingField(id: ghost)
        }
    }

    @Test("A finalized report rejects further edits and re-finalization")
    func finalizedReportIsImmutable() throws {
        let field = makeField(reviewState: .confirmed)
        let report = makeReport(fields: [field])
        let finalized = try report.finalized()

        #expect(throws: ReportError.alreadyFinalized) {
            _ = try finalized.confirmingField(id: field.id)
        }
        #expect(throws: ReportError.alreadyFinalized) {
            _ = try finalized.finalized()
        }
    }

    @Test("Provenance and confidence ride along untouched through review")
    func provenanceSurvivesReview() throws {
        let field = makeField()
        let report = makeReport(fields: [field])

        let reviewed = try report.confirmingField(id: field.id)

        #expect(reviewed.fields[0].provenance == field.provenance)
        #expect(reviewed.fields[0].confidence == field.confidence)
    }
}
