import Foundation

/// A deterministic field parser: regex in, artifacts out. No model anywhere
/// near this code path (invariant 4).
public protocol FieldParser: Sendable {
    var id: String { get }
    var kind: ArtifactKind { get }
    func parse(block: OCRBlock) -> [RecognizedArtifact]
}

/// Serial numbers behind explicit labels (S/N, SN, SERIAL NO, METER ID).
public struct SerialNumberParser: FieldParser {
    public let id = "serial-v1"
    public let kind = ArtifactKind.serialNumber
    /// Computed because `Regex` is not Sendable; a literal is cheap to build.
    private static var pattern: Regex<(Substring, Substring)> {
        /(?i)\b(?:S\/N|SN|SERIAL(?:\s*(?:NO\.?|NUMBER|#))?|METER ID)[:#.\s]*([A-Z0-9][A-Z0-9\-]{4,})/
    }

    public init() {}

    public func parse(block: OCRBlock) -> [RecognizedArtifact] {
        block.text.matches(of: Self.pattern).map { match in
            RecognizedArtifact(
                kind: kind,
                rawValue: String(match.1),
                normalizedValue: String(match.1).uppercased(),
                parserID: id,
                confidence: block.confidence,
                region: block.region
            )
        }
    }
}

/// Model numbers behind explicit labels (MODEL, MOD, M/N).
public struct ModelNumberParser: FieldParser {
    public let id = "model-v1"
    public let kind = ArtifactKind.modelNumber
    private static var pattern: Regex<(Substring, Substring)> {
        /(?i)\b(?:MODEL|MOD|M\/N)(?:\s*(?:NO\.?|NUMBER|#))?[:#.\s]*([A-Z0-9][A-Z0-9\-\/]{2,})/
    }

    public init() {}

    public func parse(block: OCRBlock) -> [RecognizedArtifact] {
        block.text.matches(of: Self.pattern).map { match in
            RecognizedArtifact(
                kind: kind,
                rawValue: String(match.1),
                normalizedValue: String(match.1).uppercased(),
                parserID: id,
                confidence: block.confidence,
                region: block.region
            )
        }
    }
}

/// Meter readings: digits followed by a known consumption unit.
public struct MeterReadingParser: FieldParser {
    public let id = "meter-v1"
    public let kind = ArtifactKind.meterValue
    private static var pattern: Regex<(Substring, Substring, Substring)> {
        /(?i)\b(\d[\d,]*(?:\.\d+)?)\s*(kWh|m3|m³|CCF|gal|psi)\b/
    }

    private static let canonicalUnits: [String: String] = [
        "kwh": "kWh", "m3": "m³", "m³": "m³", "ccf": "CCF", "gal": "gal", "psi": "psi",
    ]

    public init() {}

    public func parse(block: OCRBlock) -> [RecognizedArtifact] {
        block.text.matches(of: Self.pattern).compactMap { match in
            guard let unit = Self.canonicalUnits[String(match.2).lowercased()] else { return nil }
            let digits = String(match.1).replacingOccurrences(of: ",", with: "")
            return RecognizedArtifact(
                kind: kind,
                rawValue: String(match.0),
                normalizedValue: "\(digits) \(unit)",
                parserID: id,
                confidence: block.confidence,
                region: block.region
            )
        }
    }
}

/// Prices with an explicit dollar sign (receipt line items and totals).
public struct PriceParser: FieldParser {
    public let id = "price-v1"
    public let kind = ArtifactKind.price
    private static var pattern: Regex<(Substring, Substring)> {
        /\$\s*(\d[\d,]*\.\d{2})\b/
    }

    public init() {}

    public func parse(block: OCRBlock) -> [RecognizedArtifact] {
        block.text.matches(of: Self.pattern).map { match in
            let amount = String(match.1).replacingOccurrences(of: ",", with: "")
            return RecognizedArtifact(
                kind: kind,
                rawValue: String(match.0),
                normalizedValue: "\(amount) USD",
                parserID: id,
                confidence: block.confidence,
                region: block.region
            )
        }
    }
}

/// ISO (YYYY-MM-DD) and US (MM/DD/YYYY) dates, normalized to ISO-8601.
/// Out-of-range months/days are rejected rather than guessed.
public struct DateParser: FieldParser {
    public let id = "date-v1"
    public let kind = ArtifactKind.date
    private static var isoPattern: Regex<(Substring, Substring, Substring, Substring)> {
        /\b(\d{4})-(\d{2})-(\d{2})\b/
    }

    private static var usPattern: Regex<(Substring, Substring, Substring, Substring)> {
        /\b(\d{1,2})\/(\d{1,2})\/(\d{4})\b/
    }

    public init() {}

    public func parse(block: OCRBlock) -> [RecognizedArtifact] {
        isoArtifacts(in: block) + usArtifacts(in: block)
    }

    private func isoArtifacts(in block: OCRBlock) -> [RecognizedArtifact] {
        block.text.matches(of: Self.isoPattern).compactMap { match in
            guard let normalized = Self.isoDate(
                year: String(match.1), month: String(match.2), day: String(match.3)
            ) else { return nil }
            return artifact(raw: String(match.0), normalized: normalized, block: block)
        }
    }

    private func usArtifacts(in block: OCRBlock) -> [RecognizedArtifact] {
        block.text.matches(of: Self.usPattern).compactMap { match in
            guard let normalized = Self.isoDate(
                year: String(match.3), month: String(match.1), day: String(match.2)
            ) else { return nil }
            return artifact(raw: String(match.0), normalized: normalized, block: block)
        }
    }

    private func artifact(raw: String, normalized: String, block: OCRBlock) -> RecognizedArtifact {
        RecognizedArtifact(
            kind: kind,
            rawValue: raw,
            normalizedValue: normalized,
            parserID: id,
            confidence: block.confidence,
            region: block.region
        )
    }

    private static func isoDate(year: String, month: String, day: String) -> String? {
        guard let monthValue = Int(month), let dayValue = Int(day),
              (1 ... 12).contains(monthValue), (1 ... 31).contains(dayValue)
        else { return nil }
        return String(format: "%@-%02d-%02d", year, monthValue, dayValue)
    }
}

/// Runs every parser over every block, in stable block-then-parser order.
public struct ParserPipeline: Sendable {
    public let parsers: [any FieldParser]

    public init(parsers: [any FieldParser]) {
        self.parsers = parsers
    }

    public static let standard = ParserPipeline(parsers: [
        SerialNumberParser(),
        ModelNumberParser(),
        MeterReadingParser(),
        PriceParser(),
        DateParser(),
    ])

    public func artifacts(in blocks: [OCRBlock]) -> [RecognizedArtifact] {
        blocks.flatMap { block in
            parsers.flatMap { $0.parse(block: block) }
        }
    }
}
