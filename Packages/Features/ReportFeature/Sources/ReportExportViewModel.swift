import Foundation
import Observation
import ReportKit

public enum ReportExportError: Error, Equatable, Sendable {
    case reportNotFinalized
    case renderFailed(String)
}

/// One produced export artifact, kept in memory for sharing/preview.
/// M1 never auto-sends anything — the inspector shares explicitly.
public struct ExportArtifact: Hashable, Sendable {
    public enum Format: String, Sendable {
        case pdf
        case csv
    }

    public let format: Format
    public let suggestedFileName: String
    public let data: Data

    public init(format: Format, suggestedFileName: String, data: Data) {
        self.format = format
        self.suggestedFileName = suggestedFileName
        self.data = data
    }
}

/// Drives export of a finalized report to PDF and CSV (invariant 8: no data
/// lock-in). Only finalized reports may export — the finalize gate
/// (invariant 5) has already guaranteed every AI field was reviewed.
@MainActor
@Observable
public final class ReportExportViewModel {
    public private(set) var report: Report
    public private(set) var pdfArtifact: ExportArtifact?
    public private(set) var csvArtifact: ExportArtifact?
    public private(set) var errorMessage: String?

    private let template: ReportTemplate

    public init(report: Report, template: ReportTemplate) {
        self.report = report
        self.template = template
    }

    public var canExport: Bool {
        report.status == .finalized
    }

    /// Renders both artifacts. Returns them on success so callers can hand
    /// off to a share sheet; never sends anything itself.
    @discardableResult
    public func exportAll() -> [ExportArtifact] {
        guard canExport else {
            errorMessage = "Finalize the report before exporting."
            return []
        }
        do {
            let pdf = try renderPDF()
            let csv = renderCSV()
            pdfArtifact = pdf
            csvArtifact = csv
            errorMessage = nil
            return [pdf, csv]
        } catch {
            errorMessage = "Export failed: \(error)"
            return []
        }
    }

    private func renderPDF() throws -> ExportArtifact {
        let data = try PDFRenderer().render(report: report, template: template)
        return ExportArtifact(
            format: .pdf,
            suggestedFileName: fileName(ext: "pdf"),
            data: data
        )
    }

    private func renderCSV() -> ExportArtifact {
        let csv = CSVExporter.export(report)
        return ExportArtifact(
            format: .csv,
            suggestedFileName: fileName(ext: "csv"),
            data: Data(csv.utf8)
        )
    }

    private func fileName(ext: String) -> String {
        "\(template.id)-\(report.id.uuidString.prefix(8)).\(ext)"
    }
}
