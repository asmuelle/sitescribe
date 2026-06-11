import DesignSystem
import ReportKit
import SwiftUI

/// Export surface — paper-white editorial layout like review: this is the
/// professional-judgment side of the app, not the capture side. The app
/// renders artifacts and hands them to the user; it never auto-sends.
public struct ReportExportView: View {
    @State private var viewModel: ReportExportViewModel

    public init(viewModel: ReportExportViewModel) {
        _viewModel = State(initialValue: viewModel)
    }

    public var body: some View {
        ZStack {
            JobsitePalette.paper.ignoresSafeArea()
            VStack(alignment: .leading, spacing: JobsiteMetrics.sectionSpacing) {
                header
                artifactRows
                if let message = viewModel.errorMessage {
                    Text(message)
                        .font(JobsiteTypography.caption)
                        .foregroundStyle(JobsitePalette.safetyOrange)
                }
                Button("EXPORT PDF + CSV") {
                    viewModel.exportAll()
                }
                .buttonStyle(CaptureButtonStyle())
                .disabled(!viewModel.canExport)
                .opacity(viewModel.canExport ? 1 : 0.5)
                Spacer()
            }
            .padding()
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("EXPORT")
                .font(JobsiteTypography.sectionHeader)
                .foregroundStyle(JobsitePalette.inkOnPaper)
            Text(statusLine)
                .font(JobsiteTypography.caption)
                .foregroundStyle(JobsitePalette.inkOnPaper.opacity(0.5))
        }
    }

    private var statusLine: String {
        viewModel.canExport
            ? "Finalized — ready to export"
            : "Report must be finalized before export"
    }

    private var artifactRows: some View {
        VStack(alignment: .leading, spacing: JobsiteMetrics.fieldSpacing) {
            artifactRow(label: "PDF report", artifact: viewModel.pdfArtifact)
            artifactRow(label: "CSV data", artifact: viewModel.csvArtifact)
        }
    }

    private func artifactRow(label: String, artifact: ExportArtifact?) -> some View {
        HStack(spacing: 10) {
            Circle()
                .fill(artifact == nil
                    ? JobsitePalette.inkOnPaper.opacity(0.2)
                    : JobsitePalette.confirmedGreen)
                .frame(width: 10, height: 10)
            Text(label)
                .font(JobsiteTypography.body)
                .foregroundStyle(JobsitePalette.inkOnPaper)
            Spacer()
            if let artifact {
                Text(artifact.suggestedFileName)
                    .font(JobsiteTypography.capturedValue(size: 13))
                    .foregroundStyle(JobsitePalette.inkOnPaper.opacity(0.6))
            }
        }
    }
}
