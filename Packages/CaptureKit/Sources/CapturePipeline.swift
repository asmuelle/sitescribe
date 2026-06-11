import ExtractionKit
import Foundation
import os
import RecognitionKit
import ReportKit
import StorageKit

public enum PipelineStage: String, Codable, Sendable {
    case persisted
    case recognized
    case extracted
}

public enum CapturePipelineError: Error, Equatable, Sendable {
    case recognitionFailed(String)
    case extractionFailed(String)
}

public struct CapturePipelineResult: Sendable {
    public let capture: CaptureItem
    public let artifacts: [RecognizedArtifact]
    public let report: Report

    public init(capture: CaptureItem, artifacts: [RecognizedArtifact], report: Report) {
        self.capture = capture
        self.artifacts = artifacts
        self.report = report
    }
}

/// The M1 vertical slice: capture → persist FIRST (invariant 6) → deterministic
/// recognition → LLM extraction → draft report. Entirely on-device; no step
/// may await a network call (invariant 1).
public struct CapturePipeline: Sendable {
    private static let logger = Logger(subsystem: "com.sitescribe.capturekit", category: "pipeline")

    private let store: any JobStore
    private let recognizer: any TextRecognizing
    private let parsers: ParserPipeline
    private let extraction: ExtractionPipeline
    private let template: ReportTemplate
    private let schema: FindingSchema

    public init(
        store: any JobStore,
        recognizer: any TextRecognizing,
        parsers: ParserPipeline = .standard,
        extraction: ExtractionPipeline,
        template: ReportTemplate,
        schema: FindingSchema
    ) {
        self.store = store
        self.recognizer = recognizer
        self.parsers = parsers
        self.extraction = extraction
        self.template = template
        self.schema = schema
    }

    public func process(
        jobID: UUID,
        kind: CaptureKind,
        data: Data,
        onStage: (@Sendable (PipelineStage) -> Void)? = nil
    ) async throws -> CapturePipelineResult {
        // 1. Persist before anything else touches the capture (invariant 6).
        let capture = CaptureItem(jobID: jobID, kind: kind, content: data)
        try await store.saveCapture(capture)
        onStage?(.persisted)

        // 2. Deterministic layer: OCR + parsers own every identifier (invariant 4).
        let blocks = try await recognize(data: data, captureID: capture.id)
        let artifacts = parsers.artifacts(in: blocks)
        try await store.updateCaptureState(id: capture.id, to: .recognized)
        onStage?(.recognized)

        // 3. LLM layer classifies and narrates — never identifiers.
        let findings = try await extractFindings(from: blocks, captureID: capture.id)
        try await store.updateCaptureState(id: capture.id, to: .extracted)
        onStage?(.extracted)

        // 4. Assemble the draft: deterministic fields verbatim + confirmed,
        //    LLM fields unreviewed (invariant 5).
        let report = ReportAssembler.draftReport(
            jobID: jobID,
            template: template,
            deterministicValues: deterministicValues(from: artifacts, captureID: capture.id),
            findings: attributedFindings(findings, captureID: capture.id)
        )
        return CapturePipelineResult(
            capture: capture.withProcessingState(.extracted),
            artifacts: artifacts,
            report: report
        )
    }

    private func recognize(data: Data, captureID: UUID) async throws -> [OCRBlock] {
        do {
            return try await recognizer.recognizeText(in: data)
        } catch {
            await markFailed(captureID)
            throw CapturePipelineError.recognitionFailed(String(describing: error))
        }
    }

    private func extractFindings(from blocks: [OCRBlock], captureID: UUID) async throws -> [Finding] {
        let fullText = blocks.map(\.text).joined(separator: "\n")
        do {
            return try await extraction.extract(from: fullText, schema: schema)
        } catch {
            await markFailed(captureID)
            throw CapturePipelineError.extractionFailed(String(describing: error))
        }
    }

    /// Marking failure must never mask the original error; a failure to
    /// record the failed state is logged and surfaced via the thrown error.
    private func markFailed(_ captureID: UUID) async {
        do {
            try await store.updateCaptureState(id: captureID, to: .failed)
        } catch {
            Self.logger.error("Could not mark capture \(captureID) failed: \(String(describing: error))")
        }
    }
}

// MARK: - Mapping into ReportKit

extension CapturePipeline {
    private func deterministicValues(
        from artifacts: [RecognizedArtifact],
        captureID: UUID
    ) -> [DeterministicValue] {
        var perKindIndex: [ArtifactKind: Int] = [:]
        return artifacts.map { artifact in
            let index = perKindIndex[artifact.kind, default: 0]
            perKindIndex[artifact.kind] = index + 1
            return DeterministicValue(
                schemaKeyPath: "equipment.\(artifact.kind.rawValue)[\(index)]",
                value: artifact.normalizedValue,
                confidence: artifact.confidence,
                provenance: Provenance(
                    captureItemID: captureID,
                    region: artifact.region.map(Self.normalizedRect(from:))
                )
            )
        }
    }

    private func attributedFindings(_ findings: [Finding], captureID: UUID) -> [AttributedFinding] {
        findings.map { finding in
            AttributedFinding(
                finding: finding,
                provenance: Provenance(captureItemID: captureID),
                confidence: 0.5 // LLM output starts mid-confidence; review is the gate
            )
        }
    }

    private static func normalizedRect(from region: TextRegion) -> NormalizedRect {
        NormalizedRect(x: region.x, y: region.y, width: region.width, height: region.height)
    }
}
