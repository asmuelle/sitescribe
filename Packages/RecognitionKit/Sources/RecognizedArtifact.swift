import Foundation

/// What a deterministic parser recognized. These kinds map 1:1 to the data
/// model in DESIGN.md; identifiers and numbers are ONLY ever produced here
/// (invariant 4 — deterministic before LLM).
public enum ArtifactKind: String, Codable, CaseIterable, Sendable {
    case serialNumber
    case modelNumber
    case meterValue
    case price
    case date
    case barcode
}

/// A normalized rectangle in [0,1] image coordinates. RecognitionKit keeps
/// its own region type so it stays dependency-free.
public struct TextRegion: Codable, Hashable, Sendable {
    public let x: Double
    public let y: Double
    public let width: Double
    public let height: Double

    public init(x: Double, y: Double, width: Double, height: Double) {
        self.x = x
        self.y = y
        self.width = width
        self.height = height
    }
}

/// One value the deterministic layer extracted from a capture.
/// `rawValue` is the exact matched text; `normalizedValue` is a canonical
/// form produced by a pure function — never by a model.
public struct RecognizedArtifact: Codable, Hashable, Sendable {
    public let kind: ArtifactKind
    public let rawValue: String
    public let normalizedValue: String
    public let parserID: String
    public let confidence: Double
    public let region: TextRegion?

    public init(
        kind: ArtifactKind,
        rawValue: String,
        normalizedValue: String,
        parserID: String,
        confidence: Double,
        region: TextRegion? = nil
    ) {
        self.kind = kind
        self.rawValue = rawValue
        self.normalizedValue = normalizedValue
        self.parserID = parserID
        self.confidence = confidence
        self.region = region
    }
}
