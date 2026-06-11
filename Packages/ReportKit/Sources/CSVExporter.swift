import Foundation

/// CSV export — half of invariant 8 (no data lock-in): every report is
/// exportable as PDF *and* CSV.
public enum CSVExporter {
    public static let header = "section,schemaKeyPath,value,source,confidence,reviewState"

    public static func export(_ report: Report) -> String {
        let rows = report.fields.map { field in
            [
                field.sectionID,
                field.schemaKeyPath,
                field.value,
                field.source.rawValue,
                String(format: "%.2f", field.confidence),
                field.reviewState.rawValue,
            ]
            .map(escape)
            .joined(separator: ",")
        }
        return ([header] + rows).joined(separator: "\n") + "\n"
    }

    /// RFC 4180 escaping: quote when the value contains comma, quote, or newline.
    static func escape(_ value: String) -> String {
        guard value.contains(",") || value.contains("\"") || value.contains("\n") else {
            return value
        }
        return "\"" + value.replacingOccurrences(of: "\"", with: "\"\"") + "\""
    }
}
