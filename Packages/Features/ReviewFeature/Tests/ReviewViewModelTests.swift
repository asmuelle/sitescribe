import Foundation
import ReportKit
import Testing
@testable import ReviewFeature

@MainActor
@Suite("ReviewViewModel — the trust gate (invariant 5)")
struct ReviewViewModelTests {
    private func llmField(_ keyPath: String) -> ExtractedField {
        ExtractedField(
            sectionID: "findings",
            schemaKeyPath: keyPath,
            value: "Corrosion on heat exchanger",
            source: .llm,
            provenance: Provenance(captureItemID: UUID()),
            confidence: 0.5,
            reviewState: .unreviewed
        )
    }

    private func makeViewModel(fields: [ExtractedField]) -> ReviewViewModel {
        ReviewViewModel(report: Report(
            jobID: UUID(),
            templateID: "home-inspection-general",
            templateVersion: 1,
            fields: fields
        ))
    }

    @Test("Finalize is refused while AI fields are unreviewed")
    func finalizeRefusedWhileUnreviewed() {
        let viewModel = makeViewModel(fields: [llmField("findings[0].defect")])

        let finalized = viewModel.finalize()

        #expect(finalized == nil)
        #expect(viewModel.canFinalize == false)
        #expect(viewModel.errorMessage?.contains("1 remaining") == true)
    }

    @Test("Confirming every field unlocks and performs finalize")
    func confirmingUnlocksFinalize() {
        let fieldA = llmField("findings[0].defect")
        let fieldB = llmField("findings[0].severity")
        let viewModel = makeViewModel(fields: [fieldA, fieldB])

        viewModel.confirm(fieldID: fieldA.id)
        viewModel.confirm(fieldID: fieldB.id)
        let finalized = viewModel.finalize()

        #expect(finalized?.status == .finalized)
        #expect(viewModel.errorMessage == nil)
    }

    @Test("Editing replaces the value and counts as review")
    func editingCountsAsReview() {
        let field = llmField("findings[0].defect")
        let viewModel = makeViewModel(fields: [field])

        viewModel.edit(fieldID: field.id, newValue: "Surface rust only")

        #expect(viewModel.report.fields[0].value == "Surface rust only")
        #expect(viewModel.canFinalize)
    }

    @Test("Editing to an empty value is rejected with a message")
    func emptyEditIsRejected() {
        let field = llmField("findings[0].defect")
        let viewModel = makeViewModel(fields: [field])

        viewModel.edit(fieldID: field.id, newValue: "   ")

        #expect(viewModel.report.fields[0].value == "Corrosion on heat exchanger")
        #expect(viewModel.errorMessage != nil)
    }

    @Test("Tone mapping renders the trust language correctly")
    func toneMappingMatchesTrustLanguage() {
        let deterministic = ExtractedField(
            sectionID: "equipment", schemaKeyPath: "equipment.serialNumber[0]",
            value: "4517A23456", source: .deterministic,
            provenance: nil, confidence: 1, reviewState: .confirmed
        )
        let unreviewed = llmField("findings[0].defect")

        #expect(fieldTone(for: deterministic) == .verbatim)
        #expect(fieldTone(for: unreviewed) == .unreviewed)
        #expect(fieldTone(for: unreviewed.confirmed()) == .confirmed)
        #expect(fieldTone(for: unreviewed.edited(newValue: "x")) == .edited)
    }
}
