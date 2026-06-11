import Foundation
import Testing
@testable import ReportKit

@Suite("JSON Schema ↔ Swift type round-trip (schema is the source of truth)")
struct SchemaRoundTripTests {
    @Test("The bundled schema loads and is an object schema for Finding")
    func schemaLoads() throws {
        let schema = try HomeInspectionTemplate.loadSchema()

        #expect(schema.title == "Finding")
        #expect(schema.type == "object")
    }

    @Test("Schema required keys exactly match Finding's coding keys")
    func requiredKeysMatchFinding() throws {
        let schema = try HomeInspectionTemplate.loadSchema()
        let finding = Finding(
            defect: "d", location: "l", severity: .info, recommendedAction: "r"
        )
        let encoded = try JSONSerialization.jsonObject(
            with: JSONEncoder().encode(finding)
        ) as? [String: Any]

        let findingKeys = Set((encoded ?? [:]).keys)
        #expect(Set(schema.required) == findingKeys)
    }

    @Test("Schema severity enum exactly matches Severity.allCases")
    func severityEnumMatchesSchema() throws {
        let schema = try HomeInspectionTemplate.loadSchema()

        let schemaValues = Set(schema.properties["severity"]?.enum ?? [])
        let swiftValues = Set(Severity.allCases.map(\.rawValue))
        #expect(schemaValues == swiftValues)
        #expect(!schemaValues.isEmpty)
    }

    @Test("A Finding decoded from schema-shaped JSON round-trips losslessly")
    func findingRoundTripsThroughJSON() throws {
        let json = """
        {
          "defect": "Corrosion on heat exchanger",
          "location": "Basement",
          "severity": "safetyHazard",
          "recommendedAction": "Correct immediately."
        }
        """

        let decoded = try JSONDecoder().decode(Finding.self, from: Data(json.utf8))
        let reencoded = try JSONDecoder().decode(
            Finding.self,
            from: JSONEncoder().encode(decoded)
        )

        #expect(decoded == reencoded)
        #expect(decoded.severity == .safetyHazard)
    }

    @Test("Out-of-scale severity values fail decoding instead of being coerced")
    func invalidSeverityFailsDecoding() {
        let json = """
        {"defect": "d", "location": "l", "severity": "catastrophic", "recommendedAction": "r"}
        """

        #expect(throws: DecodingError.self) {
            _ = try JSONDecoder().decode(Finding.self, from: Data(json.utf8))
        }
    }

    @Test("Template sections cover the two M1 surfaces")
    func templateSectionsCoverM1() {
        let template = HomeInspectionTemplate.template

        #expect(template.sections.map(\.id) == ["equipment", "findings"])
        #expect(template.id == "home-inspection-general")
    }
}
