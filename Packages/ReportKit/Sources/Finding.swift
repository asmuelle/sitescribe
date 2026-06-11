import Foundation

/// Severity scale for inspection findings. The raw values are the JSON Schema
/// enum values in `home_inspection_general.schema.json` — the schema is the
/// source of truth and the round-trip is covered by tests.
public enum Severity: String, Codable, CaseIterable, Sendable {
    case info
    case minor
    case moderate
    case major
    case safetyHazard

    public var displayName: String {
        switch self {
        case .info: "Informational"
        case .minor: "Minor"
        case .moderate: "Moderate"
        case .major: "Major"
        case .safetyHazard: "Safety Hazard"
        }
    }
}

/// One structured inspection finding, the unit the extraction layer produces.
/// Mirrors the template's JSON Schema; on AFM-capable devices ExtractionKit
/// bridges this to an `@Generable` struct, but the domain type stays plain.
public struct Finding: Codable, Hashable, Sendable {
    public let defect: String
    public let location: String
    public let severity: Severity
    public let recommendedAction: String

    public init(defect: String, location: String, severity: Severity, recommendedAction: String) {
        self.defect = defect
        self.location = location
        self.severity = severity
        self.recommendedAction = recommendedAction
    }
}
