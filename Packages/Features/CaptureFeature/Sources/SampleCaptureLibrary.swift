import Foundation

/// A bundled demo capture — M1 ships fixture "photos" (OCR-equivalent text
/// payloads) so the full offline pipeline is drivable on the simulator
/// without camera hardware. Real camera capture replaces this in M2.
public struct SampleCapture: Identifiable, Hashable, Sendable {
    public let id: String
    public let title: String
    public let data: Data

    public init(id: String, title: String, data: Data) {
        self.id = id
        self.title = title
        self.data = data
    }
}

public enum SampleCaptureError: Error, Equatable, Sendable {
    case resourcesMissing
}

public enum SampleCaptureLibrary {
    /// Loads every bundled sample, alphabetical by file name for stability.
    public static func loadAll() throws -> [SampleCapture] {
        guard let urls = Bundle.module.urls(
            forResourcesWithExtension: "txt",
            subdirectory: "SampleCaptures"
        ), !urls.isEmpty else {
            throw SampleCaptureError.resourcesMissing
        }
        return try urls
            .sorted { $0.lastPathComponent < $1.lastPathComponent }
            .map { url in
                let name = url.deletingPathExtension().lastPathComponent
                return try SampleCapture(
                    id: name,
                    title: name.replacingOccurrences(of: "_", with: " ").capitalized,
                    data: Data(contentsOf: url)
                )
            }
    }
}
