import Foundation
import ReportFeature
import ReportKit
import Testing

@MainActor
@Suite("ReportExportViewModel")
struct ReportExportViewModelTests {
    private static func makeReport(reviewState: ReviewState) -> Report {
        Report(
            jobID: UUID(),
            templateID: HomeInspectionTemplate.template.id,
            templateVersion: HomeInspectionTemplate.template.version,
            fields: [
                ExtractedField(
                    sectionID: "equipment",
                    schemaKeyPath: "equipment.serialNumber",
                    value: "SN-4451-A92",
                    source: .deterministic,
                    provenance: Provenance(captureItemID: UUID()),
                    confidence: 0.98,
                    reviewState: .confirmed
                ),
                ExtractedField(
                    sectionID: "findings",
                    schemaKeyPath: "finding.defect",
                    value: "Corroded heat exchanger",
                    source: .llm,
                    provenance: Provenance(captureItemID: UUID()),
                    confidence: 0.72,
                    reviewState: reviewState
                ),
            ]
        )
    }

    @Test("finalized report exports both PDF and CSV artifacts")
    func finalizedReportExportsBothArtifacts() throws {
        // Arrange
        let finalized = try Self.makeReport(reviewState: .confirmed).finalized()
        let viewModel = ReportExportViewModel(
            report: finalized,
            template: HomeInspectionTemplate.template
        )

        // Act
        let artifacts = viewModel.exportAll()

        // Assert
        #expect(artifacts.count == 2)
        #expect(viewModel.pdfArtifact?.format == .pdf)
        #expect(viewModel.csvArtifact?.format == .csv)
        #expect(viewModel.errorMessage == nil)
        let pdfData = try #require(viewModel.pdfArtifact?.data)
        #expect(pdfData.prefix(5) == Data("%PDF-".utf8))
        let csvText = try #require(viewModel.csvArtifact.map { String(decoding: $0.data, as: UTF8.self) })
        #expect(csvText.contains("SN-4451-A92"))
        #expect(csvText.hasPrefix(CSVExporter.header))
    }

    @Test("draft report refuses to export and surfaces a recovery message")
    func draftReportRefusesToExport() {
        // Arrange — report still has an unreviewed AI field, so it is a draft.
        let viewModel = ReportExportViewModel(
            report: Self.makeReport(reviewState: .unreviewed),
            template: HomeInspectionTemplate.template
        )

        // Act
        let artifacts = viewModel.exportAll()

        // Assert
        #expect(!viewModel.canExport)
        #expect(artifacts.isEmpty)
        #expect(viewModel.pdfArtifact == nil)
        #expect(viewModel.csvArtifact == nil)
        #expect(viewModel.errorMessage != nil)
    }

    @Test("export file names share the template id and report id prefix")
    func exportFileNamesAreStable() throws {
        // Arrange
        let finalized = try Self.makeReport(reviewState: .confirmed).finalized()
        let viewModel = ReportExportViewModel(
            report: finalized,
            template: HomeInspectionTemplate.template
        )

        // Act
        viewModel.exportAll()

        // Assert
        let prefix = "\(HomeInspectionTemplate.template.id)-\(finalized.id.uuidString.prefix(8))"
        #expect(viewModel.pdfArtifact?.suggestedFileName == "\(prefix).pdf")
        #expect(viewModel.csvArtifact?.suggestedFileName == "\(prefix).csv")
    }
}
