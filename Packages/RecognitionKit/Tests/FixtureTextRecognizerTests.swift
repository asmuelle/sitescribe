import Foundation
import Testing
@testable import RecognitionKit

@Suite("FixtureTextRecognizer")
struct FixtureTextRecognizerTests {
    @Test("Emits one block per non-empty line, top to bottom")
    func emitsOneBlockPerLine() async throws {
        let text = "LINE ONE\n\nLINE TWO\n  \nLINE THREE\n"
        let data = Data(text.utf8)

        let blocks = try await FixtureTextRecognizer().recognizeText(in: data)

        #expect(blocks.map(\.text) == ["LINE ONE", "LINE TWO", "LINE THREE"])
        let ys = blocks.compactMap { $0.region?.y }
        #expect(ys == ys.sorted(), "Regions must be ordered top to bottom")
    }

    @Test("Rejects non-UTF8 payloads with a typed error")
    func rejectsNonUTF8Payloads() async {
        let invalid = Data([0xFF, 0xFE, 0xFD])

        await #expect(throws: RecognitionError.undecodableInput) {
            _ = try await FixtureTextRecognizer().recognizeText(in: invalid)
        }
    }

    @Test("Device capability probe never fails and defaults safely")
    func capabilityProbeDefaultsSafely() {
        let capabilities = DeviceCapabilities.probe()

        // Invariant 3: image input is enhancement-only; it must never be
        // reported available before the gating ships (M2).
        #expect(capabilities.afmImageInputAvailable == false)
    }
}
