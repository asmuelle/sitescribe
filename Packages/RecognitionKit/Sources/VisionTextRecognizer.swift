#if canImport(Vision)
    import Foundation
    import Vision

    /// Vision-backed OCR — the universal device path (invariant 3: works on
    /// every supported device, no AFM requirement). Not exercised on CI; the
    /// pipeline is covered through `FixtureTextRecognizer` golden tests.
    public struct VisionTextRecognizer: TextRecognizing {
        public init() {}

        public func recognizeText(in data: Data) async throws -> [OCRBlock] {
            let request = VNRecognizeTextRequest()
            request.recognitionLevel = .accurate
            request.usesLanguageCorrection = false
            let handler = VNImageRequestHandler(data: data)
            do {
                try handler.perform([request])
            } catch {
                throw RecognitionError.recognitionFailed(String(describing: error))
            }
            let observations = request.results ?? []
            return observations.compactMap(block(from:))
        }

        private func block(from observation: VNRecognizedTextObservation) -> OCRBlock? {
            guard let candidate = observation.topCandidates(1).first else { return nil }
            let box = observation.boundingBox
            return OCRBlock(
                text: candidate.string,
                confidence: Double(candidate.confidence),
                region: TextRegion(
                    x: box.origin.x,
                    y: 1 - box.origin.y - box.height, // Vision is bottom-left origin
                    width: box.width,
                    height: box.height
                )
            )
        }
    }
#endif
