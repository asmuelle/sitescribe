import ReportKit

/// The visual trust language: deterministic values render verbatim in
/// monospace, AI fields are amber until reviewed, reviewed fields go green.
/// This mapping is the testable core of the review screen's semantics.
public enum FieldTone: Equatable, Sendable {
    /// Deterministic capture — monospaced, sourced, already trustworthy.
    case verbatim
    /// AI-derived and not yet reviewed — amber, blocks finalize.
    case unreviewed
    /// Confirmed by the inspector — green.
    case confirmed
    /// Edited by the inspector — green, sourced as manual.
    case edited
}

public func fieldTone(for field: ExtractedField) -> FieldTone {
    switch field.source {
    case .deterministic:
        .verbatim
    case .manual:
        .edited
    case .llm:
        switch field.reviewState {
        case .unreviewed: .unreviewed
        case .confirmed: .confirmed
        case .edited: .edited
        }
    }
}
