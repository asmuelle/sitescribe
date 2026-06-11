import Foundation
import Testing
@testable import ReportKit

@Suite("ReportAssembler (invariants 4 + 5 at the assembly boundary)")
struct ReportAssemblerTests {
    private let captureID = UUID()

    private func deterministicSerial() -> DeterministicValue {
        DeterministicValue(
            schemaKeyPath: "equipment.serialNumber[0]",
            value: "4517A23456",
            confidence: 0.97,
            provenance: Provenance(
                captureItemID: captureID,
                region: NormalizedRect(x: 0, y: 0.4, width: 1, height: 0.2)
            )
        )
    }

    private func llmFinding() -> AttributedFinding {
        AttributedFinding(
            finding: Finding(
                defect: "Corrosion on heat exchanger",
                location: "Basement",
                severity: .moderate,
                recommendedAction: "Evaluate and repair as needed."
            ),
            provenance: Provenance(captureItemID: captureID),
            confidence: 0.5
        )
    }

    @Test("Deterministic values are copied verbatim and arrive confirmed")
    func deterministicValuesArriveConfirmedVerbatim() {
        let report = ReportAssembler.draftReport(
            jobID: UUID(),
            template: HomeInspectionTemplate.template,
            deterministicValues: [deterministicSerial()],
            findings: []
        )

        let field = report.fields[0]
        #expect(field.value == "4517A23456")
        #expect(field.source == .deterministic)
        #expect(field.reviewState == .confirmed)
        #expect(field.provenance?.captureItemID == captureID)
        #expect(field.provenance?.region != nil)
    }

    @Test("Every LLM-derived field enters the report unreviewed")
    func llmFieldsEnterUnreviewed() {
        let report = ReportAssembler.draftReport(
            jobID: UUID(),
            template: HomeInspectionTemplate.template,
            deterministicValues: [],
            findings: [llmFinding()]
        )

        let llmFields = report.fields.filter { $0.source == .llm }
        #expect(llmFields.count == 4) // defect, location, severity, recommendedAction
        #expect(llmFields.allSatisfy { $0.reviewState == .unreviewed })
        #expect(llmFields.allSatisfy { $0.provenance?.captureItemID == captureID })
    }

    @Test("Findings are expanded with stable indexed key paths")
    func findingsGetIndexedKeyPaths() {
        let report = ReportAssembler.draftReport(
            jobID: UUID(),
            template: HomeInspectionTemplate.template,
            deterministicValues: [],
            findings: [llmFinding(), llmFinding()]
        )

        let keyPaths = report.fields.map(\.schemaKeyPath)
        #expect(keyPaths.contains("findings[0].defect"))
        #expect(keyPaths.contains("findings[1].severity"))
    }

    @Test("A fresh draft with LLM findings can never be finalized directly")
    func freshDraftCannotFinalize() {
        let report = ReportAssembler.draftReport(
            jobID: UUID(),
            template: HomeInspectionTemplate.template,
            deterministicValues: [deterministicSerial()],
            findings: [llmFinding()]
        )

        #expect(throws: ReportError.unreviewedFieldsRemain(count: 4)) {
            _ = try report.finalized()
        }
    }
}
