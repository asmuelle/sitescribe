import DesignSystem
import StorageKit
import SwiftUI

/// Field screen: charcoal, high contrast, oversized targets.
public struct JobsListView: View {
    @State private var viewModel: JobsViewModel
    private let onOpenJob: (Job) -> Void

    public init(viewModel: JobsViewModel, onOpenJob: @escaping (Job) -> Void) {
        _viewModel = State(initialValue: viewModel)
        self.onOpenJob = onOpenJob
    }

    public var body: some View {
        ZStack {
            JobsitePalette.surface.ignoresSafeArea()
            VStack(alignment: .leading, spacing: JobsiteMetrics.sectionSpacing) {
                header
                jobList
                newJobButton
            }
            .padding()
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 8) {
            OfflineBadge()
            Text("JOBS")
                .font(JobsiteTypography.sectionHeader)
                .foregroundStyle(JobsitePalette.inkOnSurface)
        }
    }

    private var jobList: some View {
        ScrollView {
            LazyVStack(spacing: JobsiteMetrics.fieldSpacing) {
                ForEach(viewModel.jobs) { job in
                    Button {
                        onOpenJob(job)
                    } label: {
                        JobRow(job: job)
                    }
                    .buttonStyle(.plain)
                }
            }
        }
        .task { await viewModel.load() }
    }

    private var newJobButton: some View {
        Button("NEW JOB") {
            Task {
                await viewModel.createJob(
                    clientName: "Walk-in Client",
                    siteAddress: "Site TBD",
                    jobType: .inspection
                )
            }
        }
        .buttonStyle(CaptureButtonStyle())
        .accessibilityHint("Creates a job you can rename later")
    }
}

struct JobRow: View {
    let job: Job

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(job.clientName)
                .font(JobsiteTypography.body.weight(.semibold))
                .foregroundStyle(JobsitePalette.inkOnSurface)
            Text(job.siteAddress)
                .font(JobsiteTypography.caption)
                .foregroundStyle(JobsitePalette.mutedOnSurface)
        }
        .frame(maxWidth: .infinity, minHeight: JobsiteMetrics.minimumTapTargetPoints, alignment: .leading)
        .padding(.horizontal, 14)
        .background(
            RoundedRectangle(cornerRadius: JobsiteMetrics.cornerRadius)
                .fill(JobsitePalette.inkOnSurface.opacity(0.06))
        )
    }
}
