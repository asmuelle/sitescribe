import SwiftUI

/// "Jobsite Instrument" palette (DESIGN.md). Color is semantic state, never
/// decoration: safety orange = capture/record only, amber = unreviewed AI
/// field only, green = confirmed/synced only. Values are sRGB approximations
/// of the OKLCH spec tokens.
public enum JobsitePalette {
    /// Asphalt charcoal — field-screen surface. ≈ oklch(22% 0.01 260)
    public static let surface = Color(red: 0.118, green: 0.122, blue: 0.141)
    /// Paper white — report/review surface.
    public static let paper = Color(red: 0.976, green: 0.973, blue: 0.965)
    /// Safety orange — reserved for capture/record actions. ≈ oklch(68% 0.19 45)
    public static let safetyOrange = Color(red: 0.949, green: 0.420, blue: 0.110)
    /// Amber — strictly "unreviewed AI field".
    public static let unreviewedAmber = Color(red: 1.0, green: 0.690, blue: 0.125)
    /// Green — strictly "confirmed/synced".
    public static let confirmedGreen = Color(red: 0.180, green: 0.620, blue: 0.270)
    /// High-contrast ink on charcoal (direct-sunlight legibility).
    public static let inkOnSurface = Color(red: 0.93, green: 0.94, blue: 0.96)
    /// Ink on paper.
    public static let inkOnPaper = Color(red: 0.12, green: 0.12, blue: 0.13)
    /// Muted ink for secondary labels on charcoal.
    public static let mutedOnSurface = Color(red: 0.62, green: 0.64, blue: 0.69)
}

/// Glove-friendly, sunlight-ready metrics.
public enum JobsiteMetrics {
    /// Oversized tap targets on capture surfaces (≥ 56pt per DESIGN.md).
    public static let minimumTapTargetPoints: Double = 56
    /// Minimum body size — never smaller than 17pt.
    public static let minimumBodyPointSize: Double = 17
    public static let sectionSpacing: Double = 24
    public static let fieldSpacing: Double = 12
    public static let cornerRadius: Double = 10
}

/// SF Pro for UI; SF Mono for every captured value — the trust layer made
/// visible: monospace signals "verbatim from the device, not generated".
public enum JobsiteTypography {
    public static func capturedValue(size: Double = JobsiteMetrics.minimumBodyPointSize) -> Font {
        .system(size: size, weight: .medium, design: .monospaced)
    }

    public static var sectionHeader: Font {
        .system(size: 22, weight: .heavy)
    }

    public static var body: Font {
        .system(size: JobsiteMetrics.minimumBodyPointSize)
    }

    public static var caption: Font {
        .system(size: 13, weight: .semibold)
    }
}
