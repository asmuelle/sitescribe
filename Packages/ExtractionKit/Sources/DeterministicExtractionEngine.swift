import Foundation
import ReportKit

/// Rule-based extraction engine: the deterministic fake required by the
/// testing policy (FoundationModels is unavailable on CI) and the engine the
/// sample flow ships with. Same input, same output, every time — which is
/// exactly what golden tests need.
public struct DeterministicExtractionEngine: ExtractionEngine {
    public let identifier = "deterministic-rules-v1"

    private struct SeverityRule {
        let keywords: [String]
        let severity: Severity
    }

    /// Ordered by precedence: the first rule whose keyword appears wins.
    private static let rules: [SeverityRule] = [
        SeverityRule(
            keywords: ["hazard", "exposed wiring", "gas leak", "carbon monoxide", "immediately", "scald"],
            severity: .safetyHazard
        ),
        SeverityRule(
            keywords: ["replace", "failed", "active leak", "leaking", "inoperative", "not functional"],
            severity: .major
        ),
        // Explicit downgrade cues ("recommend monitor", "hairline", "cosmetic")
        // are deliberate inspector language and outrank generic condition words
        // like "crack" — but never outrank hazard/major cues above.
        SeverityRule(
            keywords: ["monitor", "hairline", "cosmetic", "minor"],
            severity: .minor
        ),
        SeverityRule(
            keywords: ["corrosion", "corroded", "rust", "damaged", "deteriorated", "worn", "crack"],
            severity: .moderate
        ),
    ]

    /// Longest names first so "furnace room" wins over "roof"-style overlaps.
    private static let locations = [
        "water heater closet", "furnace room", "utility room", "living room", "crawlspace",
        "basement", "exterior", "bathroom", "kitchen", "garage", "attic", "panel", "roof",
    ]

    private static let actions: [Severity: String] = [
        .safetyHazard: "Correct immediately — safety hazard.",
        .major: "Repair or replace; obtain a qualified contractor.",
        .moderate: "Evaluate and repair as needed.",
        .minor: "Monitor at the next scheduled visit.",
        .info: "No action required.",
    ]

    public init() {}

    public func extractFindings(from chunk: String, schema: FindingSchema) async throws -> [Finding] {
        sentences(in: chunk).compactMap(finding(from:))
    }

    private func sentences(in chunk: String) -> [String] {
        chunk
            .replacingOccurrences(of: ". ", with: "\n")
            .split(separator: "\n", omittingEmptySubsequences: true)
            .map { $0.trimmingCharacters(in: .whitespaces) }
            .filter { !$0.isEmpty }
    }

    private func finding(from sentence: String) -> Finding? {
        let lowered = sentence.lowercased()
        guard let severity = matchedSeverity(in: lowered) else { return nil }
        let defect = sentence
            .trimmingCharacters(in: CharacterSet(charactersIn: ". "))
        return Finding(
            defect: defect,
            location: matchedLocation(in: lowered),
            severity: severity,
            recommendedAction: Self.actions[severity] ?? "No action required."
        )
    }

    private func matchedSeverity(in lowered: String) -> Severity? {
        for rule in Self.rules where rule.keywords.contains(where: lowered.contains) {
            return rule.severity
        }
        return nil
    }

    private func matchedLocation(in lowered: String) -> String {
        guard let match = Self.locations.first(where: lowered.contains) else {
            return "Unspecified"
        }
        return match.capitalized
    }
}
