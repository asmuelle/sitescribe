import CaptureFeature
import CaptureKit
import DesignSystem
import ReportFeature
import ReportKit
import ReviewFeature
import StorageKit
import SwiftUI

/// The M1 vertical slice on one screen flow: pick a bundled sample capture,
/// run it through persist → recognize → extract (pipeline state, no
/// spinners), then review and export. Works entirely in airplane mode.
struct JobFlowView: View {
    enum FlowPhase {
        case capture
        case review(ReviewViewModel)
        case export(ReportExportViewModel)
    }

    let job: Job
    let environment: AppEnvironment

    @State private var phase: FlowPhase = .capture
    @State private var completedStages: Set<PipelineStage> = []
    @State private var isProcessing = false
    @State private var errorMessage: String?

    var body: some View {
        content
            .navigationTitle(job.clientName)
        #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
        #endif
    }

    @ViewBuilder
    private var content: some View {
        switch phase {
        case .capture:
            CaptureSampleView(
                completedStages: completedStages,
                isProcessing: isProcessing,
                errorMessage: errorMessage,
                onCapture: process(sample:)
            )
        case let .review(viewModel):
            ReviewView(viewModel: viewModel, template: environment.template) { finalized in
                phase = .export(ReportExportViewModel(
                    report: finalized,
                    template: environment.template
                ))
            }
        case let .export(viewModel):
            ReportExportView(viewModel: viewModel)
        }
    }

    private func process(sample: SampleCapture) {
        guard !isProcessing else { return }
        isProcessing = true
        completedStages = []
        errorMessage = nil
        Task {
            do {
                let result = try await environment.pipeline.process(
                    jobID: job.id,
                    kind: .documentScan,
                    data: sample.data,
                    onStage: { stage in
                        Task { @MainActor in completedStages.insert(stage) }
                    }
                )
                phase = .review(ReviewViewModel(report: result.report))
            } catch {
                errorMessage = "Processing failed — the capture is saved; re-shoot or retry."
            }
            isProcessing = false
        }
    }
}

/// Charcoal field screen: sample capture list + the one safety-orange action.
private struct CaptureSampleView: View {
    let completedStages: Set<PipelineStage>
    let isProcessing: Bool
    let errorMessage: String?
    let onCapture: (SampleCapture) -> Void

    @State private var samples: [SampleCapture] = []
    @State private var loadFailed = false

    var body: some View {
        ZStack {
            JobsitePalette.surface.ignoresSafeArea()
            VStack(alignment: .leading, spacing: JobsiteMetrics.sectionSpacing) {
                OfflineBadge()
                Text("CAPTURE")
                    .font(JobsiteTypography.sectionHeader)
                    .foregroundStyle(JobsitePalette.inkOnSurface)
                pipelineBadges
                sampleButtons
                if let errorMessage {
                    Text(errorMessage)
                        .font(JobsiteTypography.caption)
                        .foregroundStyle(JobsitePalette.safetyOrange)
                }
                Spacer()
            }
            .padding()
        }
        .task { loadSamples() }
    }

    private var pipelineBadges: some View {
        HStack(spacing: 14) {
            PipelineStepBadge(label: "persisted", isDone: completedStages.contains(.persisted))
            PipelineStepBadge(label: "recognized", isDone: completedStages.contains(.recognized))
            PipelineStepBadge(label: "extracted", isDone: completedStages.contains(.extracted))
        }
    }

    @ViewBuilder
    private var sampleButtons: some View {
        if loadFailed {
            Text("Sample captures are missing from this build.")
                .font(JobsiteTypography.body)
                .foregroundStyle(JobsitePalette.mutedOnSurface)
        } else {
            ForEach(samples) { sample in
                Button("CAPTURE — \(sample.title)") {
                    onCapture(sample)
                }
                .buttonStyle(CaptureButtonStyle())
                .disabled(isProcessing)
                .opacity(isProcessing ? 0.5 : 1)
            }
        }
    }

    private func loadSamples() {
        do {
            samples = try SampleCaptureLibrary.loadAll()
        } catch {
            loadFailed = true
        }
    }
}
