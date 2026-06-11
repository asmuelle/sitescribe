import Foundation

/// A section of a report template.
public struct TemplateSection: Codable, Hashable, Sendable {
    public let id: String
    public let title: String

    public init(id: String, title: String) {
        self.id = id
        self.title = title
    }
}

/// A report template. The JSON Schema string is the source of truth for the
/// finding structure; `Finding` and the @Generable bridge are compiled from it
/// (verified by round-trip tests, never assumed).
public struct ReportTemplate: Codable, Hashable, Sendable {
    public let id: String
    public let name: String
    public let version: Int
    public let sections: [TemplateSection]

    public init(id: String, name: String, version: Int, sections: [TemplateSection]) {
        self.id = id
        self.name = name
        self.version = version
        self.sections = sections
    }
}

public enum TemplateError: Error, Equatable, Sendable {
    case schemaResourceMissing
    case schemaUndecodable(String)
}

/// The single hardcoded M1 template: "Home Inspection — General".
public enum HomeInspectionTemplate {
    public static let template = ReportTemplate(
        id: "home-inspection-general",
        name: "Home Inspection — General",
        version: 1,
        sections: [
            TemplateSection(id: "equipment", title: "Equipment & Readings"),
            TemplateSection(id: "findings", title: "Findings"),
        ]
    )

    /// Loads and decodes the bundled JSON Schema (source of truth for `Finding`).
    public static func loadSchema() throws -> FindingSchema {
        guard let url = Bundle.module.url(
            forResource: "home_inspection_general.schema",
            withExtension: "json"
        ) else {
            throw TemplateError.schemaResourceMissing
        }
        do {
            let data = try Data(contentsOf: url)
            return try JSONDecoder().decode(FindingSchema.self, from: data)
        } catch let error as DecodingError {
            throw TemplateError.schemaUndecodable(String(describing: error))
        }
    }
}

/// Minimal JSON Schema model for the finding object — just enough structure
/// to verify that the schema and the Swift types cannot drift apart.
public struct FindingSchema: Codable, Sendable {
    public struct Property: Codable, Sendable {
        public let type: String
        public let description: String?
        public let `enum`: [String]?
    }

    public let title: String
    public let type: String
    public let required: [String]
    public let properties: [String: Property]
}
