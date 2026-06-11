import CaptureFeature
import Foundation
import Testing

@Suite("SampleCaptureLibrary")
struct SampleCaptureLibraryTests {
    @Test("loads bundled sample captures in stable alphabetical order")
    func loadsBundledSamplesInStableOrder() throws {
        // Act
        let samples = try SampleCaptureLibrary.loadAll()

        // Assert
        #expect(!samples.isEmpty)
        let ids = samples.map(\.id)
        #expect(ids == ids.sorted())
    }

    @Test("every sample carries non-empty data and a human-readable title")
    func samplesCarryDataAndTitles() throws {
        // Act
        let samples = try SampleCaptureLibrary.loadAll()

        // Assert
        for sample in samples {
            #expect(!sample.data.isEmpty)
            #expect(!sample.title.isEmpty)
            #expect(!sample.title.contains("_"))
        }
    }
}
