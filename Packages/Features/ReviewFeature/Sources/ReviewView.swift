import DesignSystem
import ReportKit
import SwiftUI

/// The review screen switches to the calm paper-white editorial layout —
/// the moment of professional judgment reads differently from capture.
public struct ReviewView: View {
    @State private var viewModel: ReviewViewModel
    private let template: ReportTemplate
    private let onFinalized: (Report) -> Void

    public init(
        viewModel: ReviewViewModel,
        template: ReportTemplate,
        onFinalized: @escaping (Report) -> Void
    ) {
        _viewModel = State(initialValue: viewModel)
        self.template = template
        self.onFinalized = onFinalized
    }

    public var body: some View {
        ZStack {
            JobsitePalette.paper.ignoresSafeArea()
            ScrollView {
                VStack(alignment: .leading, spacing: JobsiteMetrics.sectionSpacing) {
                    ForEach(template.sections, id: \.id) { section in
                        sectionView(section)
                    }
                    finalizeArea
                }
                .padding()
            }
        }
    }

    @ViewBuilder
    private func sectionView(_ section: TemplateSection) -> some View {
        let fields = viewModel.fields(inSection: section.id)
        if !fields.isEmpty {
            VStack(alignment: .leading, spacing: JobsiteMetrics.fieldSpacing) {
                Text(section.title.uppercased())
                    .font(JobsiteTypography.caption)
                    .foregroundStyle(JobsitePalette.inkOnPaper.opacity(0.5))
                ForEach(fields) { field in
                    FieldRow(field: field) {
                        viewModel.confirm(fieldID: field.id)
                    }
                }
            }
        }
    }

    private var finalizeArea: some View {
        VStack(alignment: .leading, spacing: 8) {
            if let message = viewModel.errorMessage {
                Text(message)
                    .font(JobsiteTypography.caption)
                    .foregroundStyle(JobsitePalette.safetyOrange)
            }
            Button(viewModel.canFinalize ? "FINALIZE REPORT" : "REVIEW \(viewModel.unreviewedCount) FIELDS") {
                if let finalized = viewModel.finalize() {
                    onFinalized(finalized)
                }
            }
            .buttonStyle(CaptureButtonStyle())
            .disabled(!viewModel.canFinalize)
            .opacity(viewModel.canFinalize ? 1 : 0.5)
        }
    }
}

/// One field with its tone, provenance hint, and confirm affordance.
struct FieldRow: View {
    let field: ExtractedField
    let onConfirm: () -> Void

    var body: some View {
        HStack(alignment: .firstTextBaseline, spacing: 10) {
            toneIndicator
            VStack(alignment: .leading, spacing: 3) {
                Text(field.schemaKeyPath)
                    .font(.system(size: 11, weight: .medium))
                    .foregroundStyle(JobsitePalette.inkOnPaper.opacity(0.45))
                valueText
                provenanceChip
            }
            Spacer()
            if fieldTone(for: field) == .unreviewed {
                Button("Confirm", action: onConfirm)
                    .font(JobsiteTypography.caption)
                    .buttonStyle(.bordered)
                    .tint(JobsitePalette.confirmedGreen)
            }
        }
        .padding(.vertical, 6)
    }

    private var toneIndicator: some View {
        Circle()
            .fill(toneColor)
            .frame(width: 10, height: 10)
            .accessibilityLabel(toneLabel)
    }

    @ViewBuilder
    private var valueText: some View {
        switch fieldTone(for: field) {
        case .verbatim:
            Text(field.value)
                .font(JobsiteTypography.capturedValue())
                .foregroundStyle(JobsitePalette.inkOnPaper)
        default:
            Text(field.value)
                .font(JobsiteTypography.body)
                .foregroundStyle(JobsitePalette.inkOnPaper)
        }
    }

    @ViewBuilder
    private var provenanceChip: some View {
        if field.provenance != nil {
            Label(field.source == .deterministic ? "captured" : "AI · \(confidencePercent)", systemImage: "link")
                .font(.system(size: 10, weight: .semibold))
                .foregroundStyle(JobsitePalette.inkOnPaper.opacity(0.4))
        }
    }

    private var confidencePercent: String {
        "\(Int(field.confidence * 100))%"
    }

    private var toneColor: Color {
        switch fieldTone(for: field) {
        case .verbatim: JobsitePalette.inkOnPaper.opacity(0.6)
        case .unreviewed: JobsitePalette.unreviewedAmber
        case .confirmed, .edited: JobsitePalette.confirmedGreen
        }
    }

    private var toneLabel: String {
        switch fieldTone(for: field) {
        case .verbatim: "Captured value"
        case .unreviewed: "Unreviewed AI field"
        case .confirmed: "Confirmed field"
        case .edited: "Edited field"
        }
    }
}
