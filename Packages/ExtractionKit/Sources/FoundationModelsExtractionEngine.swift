// Real on-device LLM engine, compiled only where FoundationModels exists and
// gated to OS 26+. CI and `swift test` never execute this path — the
// deterministic engine stands in (see AGENTS.md testing policy). No feature
// may hard-require this engine (invariant 3).
#if canImport(FoundationModels)
    import Foundation
    import FoundationModels
    import ReportKit

    @available(iOS 26.0, macOS 26.0, *)
    public struct FoundationModelsExtractionEngine: ExtractionEngine {
        public let identifier = "afm3-generable-v1"

        public init() {}

        public func extractFindings(from chunk: String, schema: FindingSchema) async throws -> [Finding] {
            let model = SystemLanguageModel.default
            guard case .available = model.availability else {
                throw ExtractionError.modelUnavailable(String(describing: model.availability))
            }
            let session = LanguageModelSession(instructions: Self.instructions(for: schema))
            do {
                let response = try await session.respond(to: chunk, generating: GenerableFindingList.self)
                return response.content.findings.compactMap(\.domainFinding)
            } catch {
                throw ExtractionError.generationFailed(String(describing: error))
            }
        }

        /// The prompt is derived from the JSON Schema (source of truth) and
        /// forbids the model from inventing identifiers or numbers (invariant 4).
        static func instructions(for schema: FindingSchema) -> String {
            let fieldList = schema.required.joined(separator: ", ")
            return """
            You extract structured home-inspection findings from an inspector's notes.
            Fill only these fields: \(fieldList).
            Use only information stated in the notes. Never invent, correct, or guess
            serial numbers, model numbers, meter values, dates, or prices — those are
            captured separately. If the notes contain no findings, return an empty list.
            """
        }
    }

    @available(iOS 26.0, macOS 26.0, *)
    @Generable
    struct GenerableFindingList {
        @Guide(description: "Structured findings extracted from the inspector's notes.")
        var findings: [GenerableFinding]
    }

    @available(iOS 26.0, macOS 26.0, *)
    @Generable
    struct GenerableFinding {
        @Guide(description: "What is wrong, stated factually.")
        var defect: String

        @Guide(description: "Where in the property the defect was observed.")
        var location: String

        @Guide(description: "Exactly one of: info, minor, moderate, major, safetyHazard.")
        var severity: String

        @Guide(description: "What the inspector recommends (evaluate, repair, replace, monitor).")
        var recommendedAction: String

        /// Schema conformance is not correctness: values that do not map onto
        /// the fixed severity scale are rejected, never coerced.
        var domainFinding: Finding? {
            guard let mapped = Severity(rawValue: severity) else { return nil }
            return Finding(
                defect: defect,
                location: location,
                severity: mapped,
                recommendedAction: recommendedAction
            )
        }
    }
#endif
