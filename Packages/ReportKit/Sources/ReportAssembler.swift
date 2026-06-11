import Foundation

/// A value produced by the deterministic layer (OCR/barcode/regex), already
/// normalized, to be copied into the report **verbatim** (invariant 4).
/// Kept dependency-free so ReportKit does not import RecognitionKit.
public struct DeterministicValue: Codable, Hashable, Sendable {
    public let schemaKeyPath: String
    public let value: String
    public let confidence: Double
    public let provenance: Provenance

    public init(schemaKeyPath: String, value: String, confidence: Double, provenance: Provenance) {
        self.schemaKeyPath = schemaKeyPath
        self.value = value
        self.confidence = confidence
        self.provenance = provenance
    }
}

/// A finding paired with where it came from.
public struct AttributedFinding: Hashable, Sendable {
    public let finding: Finding
    public let provenance: Provenance
    public let confidence: Double

    public init(finding: Finding, provenance: Provenance, confidence: Double) {
        self.finding = finding
        self.provenance = provenance
        self.confidence = confidence
    }
}

/// Assembles a draft report from deterministic values and LLM findings.
///
/// Invariants enforced here (and covered by tests):
/// - 4: deterministic values are copied verbatim and arrive pre-confirmed
///   with full provenance; the LLM never touches them.
/// - 5: every LLM-derived field enters as `.unreviewed`.
public enum ReportAssembler {
    public static let equipmentSectionID = "equipment"
    public static let findingsSectionID = "findings"

    public static func draftReport(
        jobID: UUID,
        template: ReportTemplate,
        deterministicValues: [DeterministicValue],
        findings: [AttributedFinding]
    ) -> Report {
        let deterministicFields = deterministicValues.map(deterministicField(from:))
        let findingFields = findings.enumerated().flatMap { index, attributed in
            fields(for: attributed, at: index)
        }
        return Report(
            jobID: jobID,
            templateID: template.id,
            templateVersion: template.version,
            status: .draft,
            fields: deterministicFields + findingFields
        )
    }

    private static func deterministicField(from value: DeterministicValue) -> ExtractedField {
        ExtractedField(
            sectionID: equipmentSectionID,
            schemaKeyPath: value.schemaKeyPath,
            value: value.value,
            source: .deterministic,
            provenance: value.provenance,
            confidence: value.confidence,
            reviewState: .confirmed
        )
    }

    private static func fields(for attributed: AttributedFinding, at index: Int) -> [ExtractedField] {
        let prefix = "findings[\(index)]"
        let finding = attributed.finding
        let parts: [(String, String)] = [
            ("defect", finding.defect),
            ("location", finding.location),
            ("severity", finding.severity.rawValue),
            ("recommendedAction", finding.recommendedAction),
        ]
        return parts.map { keyPath, value in
            ExtractedField(
                sectionID: findingsSectionID,
                schemaKeyPath: "\(prefix).\(keyPath)",
                value: value,
                source: .llm,
                provenance: attributed.provenance,
                confidence: attributed.confidence,
                reviewState: .unreviewed
            )
        }
    }
}
