import Foundation

/// Splits long transcripts into chunks that fit the on-device model's small
/// context window. Invariant 7: chunking is lossless — the concatenation of
/// all chunks is exactly the original text. Silently dropping content is
/// forbidden, so this type has no failure mode that discards input.
public struct TranscriptChunker: Sendable {
    /// Character budget per chunk — a conservative proxy for AFM Core's
    /// ~4k-token context once the prompt scaffold is accounted for.
    public let maxChunkLength: Int

    public init(maxChunkLength: Int = 3000) {
        self.maxChunkLength = max(1, maxChunkLength)
    }

    /// Chunks on line boundaries where possible, hard-splitting only lines
    /// that alone exceed the budget. Guarantee: `chunk(t).joined() == t`.
    public func chunk(_ text: String) -> [String] {
        guard !text.isEmpty else { return [] }
        var chunks: [String] = []
        var current = ""
        for unit in units(of: text) {
            if current.isEmpty {
                current = unit
            } else if current.count + unit.count <= maxChunkLength {
                current += unit
            } else {
                chunks.append(current)
                current = unit
            }
        }
        if !current.isEmpty {
            chunks.append(current)
        }
        return chunks
    }

    /// Lines (keeping their newline) further hard-split to the budget so a
    /// single unit never exceeds `maxChunkLength`.
    private func units(of text: String) -> [String] {
        var lines: [String] = []
        var current = ""
        for character in text {
            current.append(character)
            if character == "\n" {
                lines.append(current)
                current = ""
            }
        }
        if !current.isEmpty {
            lines.append(current)
        }
        return lines.flatMap(hardSplit)
    }

    private func hardSplit(_ unit: String) -> [String] {
        guard unit.count > maxChunkLength else { return [unit] }
        var pieces: [String] = []
        var start = unit.startIndex
        while start < unit.endIndex {
            let end = unit.index(start, offsetBy: maxChunkLength, limitedBy: unit.endIndex)
                ?? unit.endIndex
            pieces.append(String(unit[start ..< end]))
            start = end
        }
        return pieces
    }
}
