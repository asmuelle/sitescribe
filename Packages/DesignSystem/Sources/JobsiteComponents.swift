import SwiftUI

/// The quiet offline badge: offline is a normal working state, never a
/// blocking modal (DESIGN.md motion/state rules).
public struct OfflineBadge: View {
    public init() {}

    public var body: some View {
        Label("OFFLINE — everything still works", systemImage: "airplane")
            .font(JobsiteTypography.caption)
            .foregroundStyle(JobsitePalette.mutedOnSurface)
            .padding(.horizontal, 10)
            .padding(.vertical, 5)
            .background(
                Capsule().strokeBorder(JobsitePalette.mutedOnSurface.opacity(0.4))
            )
            .accessibilityLabel("Offline. Everything still works.")
    }
}

/// Safety-orange capture button: the one place the accent color is allowed.
/// Glove-friendly ≥ 56pt target.
public struct CaptureButtonStyle: ButtonStyle {
    public init() {}

    public func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(size: 19, weight: .bold))
            .foregroundStyle(.white)
            .frame(maxWidth: .infinity)
            .frame(minHeight: JobsiteMetrics.minimumTapTargetPoints)
            .background(
                RoundedRectangle(cornerRadius: JobsiteMetrics.cornerRadius)
                    .fill(JobsitePalette.safetyOrange)
                    .opacity(configuration.isPressed ? 0.75 : 1)
            )
    }
}

/// Pipeline state rendered as discrete steps — progress is pipeline state
/// (persisted → recognized → extracted), not a spinner.
public struct PipelineStepBadge: View {
    public let label: String
    public let isDone: Bool

    public init(label: String, isDone: Bool) {
        self.label = label
        self.isDone = isDone
    }

    public var body: some View {
        Label(label, systemImage: isDone ? "checkmark.circle.fill" : "circle.dotted")
            .font(JobsiteTypography.caption)
            .foregroundStyle(isDone ? JobsitePalette.confirmedGreen : JobsitePalette.mutedOnSurface)
            .accessibilityValue(isDone ? "complete" : "pending")
    }
}
