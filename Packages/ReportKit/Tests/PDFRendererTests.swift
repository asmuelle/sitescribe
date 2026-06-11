import Foundation
import Testing
@testable import ReportKit

@Suite("PDF rendering (offline export half of invariant 8)")
struct PDFRendererTests {
    private func makeReport(fieldCount: Int) -> Report {
        let fields = (0 ..< fieldCount).map { index in
            ExtractedField(
                sectionID: index.isMultiple(of: 2) ? "equipment" : "findings",
                schemaKeyPath: "findings[\(index)].defect",
                value: "Value \(index)",
                source: index.isMultiple(of: 2) ? .deterministic : .llm,
                provenance: nil,
                confidence: 0.9,
                reviewState: .confirmed
            )
        }
        return Report(jobID: UUID(), templateID: "t", templateVersion: 1, fields: fields)
    }

    @Test("Renders valid PDF bytes for a populated report")
    func rendersValidPDFBytes() throws {
        let data = try PDFRenderer().render(
            report: makeReport(fieldCount: 6),
            template: HomeInspectionTemplate.template
        )

        let magic = String(decoding: data.prefix(5), as: UTF8.self)
        #expect(magic == "%PDF-")
        #expect(data.count > 500)
    }

    @Test("Refuses to render an empty report")
    func refusesEmptyReport() {
        #expect(throws: PDFRenderError.emptyReport) {
            _ = try PDFRenderer().render(
                report: makeReport(fieldCount: 0),
                template: HomeInspectionTemplate.template
            )
        }
    }

    @Test("Long reports paginate instead of truncating")
    func longReportsPaginate() throws {
        let short = try PDFRenderer().render(
            report: makeReport(fieldCount: 4),
            template: HomeInspectionTemplate.template
        )
        let long = try PDFRenderer().render(
            report: makeReport(fieldCount: 120),
            template: HomeInspectionTemplate.template
        )

        #expect(long.count > short.count)
        // Multiple /Page objects indicate real pagination.
        let pageMarkerCount = countOccurrences(of: "/Type /Page", in: long)
        #expect(pageMarkerCount > 1)
    }

    private func countOccurrences(of needle: String, in data: Data) -> Int {
        guard let text = String(data: data, encoding: .isoLatin1) else { return 0 }
        return text.components(separatedBy: needle).count - 1
    }
}
