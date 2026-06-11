import Foundation

/// Where a field value came from. Deterministic values are copied verbatim
/// from OCR/barcode/regex parsers (invariant 4); LLM values always start
/// life unreviewed (invariant 5); manual means the user typed or edited it.
public enum FieldSource: String, Codable, Sendable {
    case deterministic
    case llm
    case manual
}

/// Review lifecycle of a field. Only `unreviewed` blocks finalization.
public enum ReviewState: String, Codable, Sendable {
    case unreviewed
    case confirmed
    case edited
}

/// Points back at the capture that produced a value: which photo/audio item,
/// and where inside it (normalized image region or transcript span).
public struct Provenance: Codable, Hashable, Sendable {
    public let captureItemID: UUID
    /// Normalized [0,1] region in the source image, if the value came from a photo.
    public let region: NormalizedRect?
    /// Millisecond span in the source audio, if the value came from a transcript.
    public let timespanMs: ClosedRange<Int>?

    public init(captureItemID: UUID, region: NormalizedRect? = nil, timespanMs: ClosedRange<Int>? = nil) {
        self.captureItemID = captureItemID
        self.region = region
        self.timespanMs = timespanMs
    }
}

/// A normalized rectangle (all components in [0,1]) — avoids importing
/// CoreGraphics into the domain layer.
public struct NormalizedRect: Codable, Hashable, Sendable {
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

/// The unit of trust (invariant 5 lives here): every value that can end up in
/// a finalized report carries source, provenance, confidence, and review state.
public struct ExtractedField: Codable, Hashable, Identifiable, Sendable {
    public let id: UUID
    public let sectionID: String
    public let schemaKeyPath: String
    public let value: String
    public let source: FieldSource
    public let provenance: Provenance?
    public let confidence: Double
    public let reviewState: ReviewState

    public init(
        id: UUID = UUID(),
        sectionID: String,
        schemaKeyPath: String,
        value: String,
        source: FieldSource,
        provenance: Provenance?,
        confidence: Double,
        reviewState: ReviewState
    ) {
        self.id = id
        self.sectionID = sectionID
        self.schemaKeyPath = schemaKeyPath
        self.value = value
        self.source = source
        self.provenance = provenance
        self.confidence = confidence
        self.reviewState = reviewState
    }

    /// Returns a copy marked confirmed. Immutable update — never mutates in place.
    public func confirmed() -> ExtractedField {
        replacing(value: value, source: source, reviewState: .confirmed)
    }

    /// Returns a copy with a user-edited value.
    public func edited(newValue: String) -> ExtractedField {
        replacing(value: newValue, source: .manual, reviewState: .edited)
    }

    private func replacing(value: String, source: FieldSource, reviewState: ReviewState) -> ExtractedField {
        ExtractedField(
            id: id,
            sectionID: sectionID,
            schemaKeyPath: schemaKeyPath,
            value: value,
            source: source,
            provenance: provenance,
            confidence: confidence,
            reviewState: reviewState
        )
    }
}
