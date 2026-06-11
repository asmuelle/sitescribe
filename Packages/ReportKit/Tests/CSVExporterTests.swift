import Foundation
import Testing
@testable import ReportKit

@Suite("CSV export (invariant 8: no data lock-in)")
struct CSVExporterTests {
    private func makeReport() -> Report {
        let field = ExtractedField(
            sectionID: "equipment",
            schemaKeyPath: "equipment.serialNumber[0]",
            value: "4517A23456",
            source: .deterministic,
            provenance: Provenance(captureItemID: UUID()),
            confidence: 0.97,
            reviewState: .confirmed
        )
        return Report(jobID: UUID(), templateID: "t", templateVersion: 1, fields: [field])
    }

    @Test("Exports a header plus one row per field")
    func exportsHeaderAndRows() {
        let csv = CSVExporter.export(makeReport())

        let lines = csv.split(separator: "\n").map(String.init)
        #expect(lines.first == CSVExporter.header)
        #expect(lines.count == 2)
        #expect(lines[1] == "equipment,equipment.serialNumber[0],4517A23456,deterministic,0.97,confirmed")
    }

    @Test("Escapes commas, quotes, and newlines per RFC 4180")
    func escapesSpecialCharacters() {
        #expect(CSVExporter.escape("plain") == "plain")
        #expect(CSVExporter.escape("a,b") == "\"a,b\"")
        #expect(CSVExporter.escape("say \"hi\"") == "\"say \"\"hi\"\"\"")
        #expect(CSVExporter.escape("line\nbreak") == "\"line\nbreak\"")
    }

    @Test("A field value containing commas survives a CSV round trip intact")
    func commaValueSurvivesExport() {
        let field = ExtractedField(
            sectionID: "findings",
            schemaKeyPath: "findings[0].defect",
            value: "Corrosion, pitting, and scale",
            source: .llm,
            provenance: nil,
            confidence: 0.5,
            reviewState: .unreviewed
        )
        let report = Report(jobID: UUID(), templateID: "t", templateVersion: 1, fields: [field])

        let csv = CSVExporter.export(report)

        #expect(csv.contains("\"Corrosion, pitting, and scale\""))
    }
}
