import Foundation
import ReportKit
import Testing
@testable import ExtractionKit

@Suite("DeterministicExtractionEngine — the CI stand-in for FoundationModels")
struct DeterministicExtractionEngineTests {
    private let engine = DeterministicExtractionEngine()
    private let schema: FindingSchema

    init() throws {
        schema = try HomeInspectionTemplate.loadSchema()
    }

    @Test("Classifies severity by keyword precedence")
    func classifiesSeverityByPrecedence() async throws {
        let notes = """
        Exposed wiring near the panel must be corrected immediately - safety hazard.
        Heavy corrosion on the heat exchanger in the basement.
        Recommend monitor hairline crack in garage slab.
        """

        let findings = try await engine.extractFindings(from: notes, schema: schema)

        #expect(findings.map(\.severity) == [.safetyHazard, .moderate, .minor])
    }

    @Test("Pulls the location from a known-location lexicon")
    func extractsKnownLocations() async throws {
        let notes = "Heavy corrosion on the heat exchanger in the basement."

        let findings = try await engine.extractFindings(from: notes, schema: schema)

        #expect(findings.first?.location == "Basement")
    }

    @Test("Falls back to Unspecified instead of inventing a location")
    func unknownLocationFallsBack() async throws {
        let notes = "Active leak at the supply line."

        let findings = try await engine.extractFindings(from: notes, schema: schema)

        #expect(findings.first?.location == "Unspecified")
    }

    @Test("Ignores plate text with no finding cue — identifiers are not findings")
    func ignoresPlateText() async throws {
        let notes = """
        MODEL: 58STA070-12
        SERIAL NO: 4517A23456
        """

        let findings = try await engine.extractFindings(from: notes, schema: schema)

        #expect(findings.isEmpty)
    }

    @Test("Same input always yields the same output")
    func isDeterministic() async throws {
        let notes = "Rust on the water heater closet flue. Replace damaged shingles on the roof."

        let first = try await engine.extractFindings(from: notes, schema: schema)
        let second = try await engine.extractFindings(from: notes, schema: schema)

        #expect(first == second)
        #expect(!first.isEmpty)
    }
}
