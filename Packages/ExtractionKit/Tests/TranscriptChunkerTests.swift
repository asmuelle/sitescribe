import Foundation
import Testing
@testable import ExtractionKit

@Suite("TranscriptChunker (invariant 7: chunked, never truncated)")
struct TranscriptChunkerTests {
    @Test("Chunks rejoin to exactly the original text")
    func chunksRejoinLosslessly() {
        let transcript = Array(
            repeating: "Walked the basement. Corrosion on the heat exchanger.\n",
            count: 200
        ).joined()
        let chunker = TranscriptChunker(maxChunkLength: 500)

        let chunks = chunker.chunk(transcript)

        #expect(chunks.count > 1, "A long transcript must actually be chunked")
        #expect(chunks.joined() == transcript)
    }

    @Test("No chunk exceeds the budget when lines fit the budget")
    func chunksRespectBudget() {
        let transcript = Array(repeating: "Short line of notes.\n", count: 100).joined()
        let budget = 200
        let chunker = TranscriptChunker(maxChunkLength: budget)

        let chunks = chunker.chunk(transcript)

        #expect(chunks.allSatisfy { $0.count <= budget })
        #expect(chunks.joined() == transcript)
    }

    @Test("A single oversized line is hard-split, not dropped")
    func oversizedLineIsHardSplitNotDropped() {
        let monsterLine = String(repeating: "x", count: 7)
        let chunker = TranscriptChunker(maxChunkLength: 3)

        let chunks = chunker.chunk(monsterLine)

        #expect(chunks == ["xxx", "xxx", "x"])
        #expect(chunks.joined() == monsterLine)
    }

    @Test("Empty input produces no chunks")
    func emptyInputProducesNoChunks() {
        #expect(TranscriptChunker().chunk("").isEmpty)
    }

    @Test("Text shorter than the budget stays in one chunk")
    func shortTextStaysWhole() {
        let text = "One short note about the attic."

        let chunks = TranscriptChunker(maxChunkLength: 3000).chunk(text)

        #expect(chunks == [text])
    }
}
