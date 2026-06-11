import Foundation

/// One block of recognized text (typically a line) with its confidence and
/// where it sits in the source image.
public struct OCRBlock: Codable, Hashable, Sendable {
    public let text: String
    public let confidence: Double
    public let region: TextRegion?

    public init(text: String, confidence: Double, region: TextRegion? = nil) {
        self.text = text
        self.confidence = confidence
        self.region = region
    }
}

public enum RecognitionError: Error, Equatable, Sendable {
    case undecodableInput
    case visionUnavailable
    case recognitionFailed(String)
}

/// Abstraction over the OCR engine so the pipeline can run with Vision on
/// device and with a deterministic fixture recognizer in tests and on CI.
public protocol TextRecognizing: Sendable {
    func recognizeText(in data: Data) async throws -> [OCRBlock]
}

/// Deterministic recognizer used by tests, CI, and the in-app sample flow:
/// treats the capture payload as UTF-8 text and emits one block per
/// non-empty line, with a synthetic top-to-bottom region per line.
public struct FixtureTextRecognizer: TextRecognizing {
    public init() {}

    public func recognizeText(in data: Data) async throws -> [OCRBlock] {
        guard let text = String(data: data, encoding: .utf8) else {
            throw RecognitionError.undecodableInput
        }
        let lines = text
            .split(separator: "\n", omittingEmptySubsequences: true)
            .map { $0.trimmingCharacters(in: .whitespaces) }
            .filter { !$0.isEmpty }
        let count = max(lines.count, 1)
        return lines.enumerated().map { index, line in
            OCRBlock(
                text: line,
                confidence: 1.0,
                region: TextRegion(
                    x: 0,
                    y: Double(index) / Double(count),
                    width: 1,
                    height: 1 / Double(count)
                )
            )
        }
    }
}
