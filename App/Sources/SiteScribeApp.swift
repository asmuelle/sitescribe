import DesignSystem
import JobsFeature
import StorageKit
import SwiftUI

@main
struct SiteScribeApp: App {
    @State private var bootResult = Result { try AppEnvironment() }

    var body: some Scene {
        WindowGroup {
            switch bootResult {
            case let .success(environment):
                RootView(environment: environment)
            case let .failure(error):
                BootFailureView(detail: String(describing: error))
            }
        }
    }
}

/// Jobs list → job flow (capture → review → export), all offline.
struct RootView: View {
    let environment: AppEnvironment
    @State private var path: [Job] = []

    var body: some View {
        NavigationStack(path: $path) {
            VStack(spacing: 0) {
                if let note = environment.bootNote {
                    Text(note)
                        .font(JobsiteTypography.caption)
                        .foregroundStyle(JobsitePalette.unreviewedAmber)
                }
                JobsListView(viewModel: JobsViewModel(store: environment.store)) { job in
                    path.append(job)
                }
            }
            .background(JobsitePalette.surface)
            .navigationDestination(for: Job.self) { job in
                JobFlowView(job: job, environment: environment)
            }
        }
        .preferredColorScheme(.dark)
    }
}

struct BootFailureView: View {
    let detail: String

    var body: some View {
        ZStack {
            JobsitePalette.surface.ignoresSafeArea()
            VStack(spacing: 12) {
                Text("SITESCRIBE COULD NOT START")
                    .font(JobsiteTypography.sectionHeader)
                    .foregroundStyle(JobsitePalette.inkOnSurface)
                Text(detail)
                    .font(JobsiteTypography.caption)
                    .foregroundStyle(JobsitePalette.mutedOnSurface)
                Text("Reinstall the app to restore the bundled report template.")
                    .font(JobsiteTypography.body)
                    .foregroundStyle(JobsitePalette.inkOnSurface)
            }
            .padding()
        }
    }
}
