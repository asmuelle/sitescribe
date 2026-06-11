import Foundation
import Testing
@testable import RecognitionKit

/// The comparable subset of an artifact — regions/confidence are covered by
/// unit tests; goldens pin down the extracted values themselves.
private struct GoldenArtifact: Codable, Equatable {
    let kind: ArtifactKind
    let rawValue: String
    let normalizedValue: String
    let parserID: String
}

@Suite("Golden fixtures: 10 capture photos through the deterministic pipeline")
struct GoldenFixtureTests {
    static let fixtureNames = [
        "01_furnace_plate",
        "02_water_heater_plate",
        "03_electrical_panel",
        "04_gas_meter",
        "05_receipt_hardware",
        "06_hvac_condenser",
        "07_water_meter",
        "08_receipt_paint",
        "09_furnace_lennox",
        "10_electric_meter",
    ]

    @Test("Pipeline output matches the golden artifacts", arguments: fixtureNames)
    func pipelineMatchesGolden(fixture: String) async throws {
        let captureData = try FixtureLoader.data(fixture, ext: "txt")
        let goldenData = try FixtureLoader.data("\(fixture).golden", ext: "json")
        let expected = try JSONDecoder().decode([GoldenArtifact].self, from: goldenData)

        let blocks = try await FixtureTextRecognizer().recognizeText(in: captureData)
        let artifacts = ParserPipeline.standard.artifacts(in: blocks)

        let actual = artifacts.map {
            GoldenArtifact(
                kind: $0.kind,
                rawValue: $0.rawValue,
                normalizedValue: $0.normalizedValue,
                parserID: $0.parserID
            )
        }
        #expect(actual == expected, "Fixture \(fixture) drifted from its golden output")
    }

    @Test("Every fixture yields at least one deterministic artifact", arguments: fixtureNames)
    func everyFixtureYieldsArtifacts(fixture: String) async throws {
        let captureData = try FixtureLoader.data(fixture, ext: "txt")

        let blocks = try await FixtureTextRecognizer().recognizeText(in: captureData)
        let artifacts = ParserPipeline.standard.artifacts(in: blocks)

        #expect(!artifacts.isEmpty)
    }
}

enum FixtureLoadError: Error {
    case missing(String)
}

enum FixtureLoader {
    static func data(_ name: String, ext: String) throws -> Data {
        guard let url = Bundle.module.url(
            forResource: name,
            withExtension: ext,
            subdirectory: "Fixtures"
        ) else {
            throw FixtureLoadError.missing("\(name).\(ext)")
        }
        return try Data(contentsOf: url)
    }
}
