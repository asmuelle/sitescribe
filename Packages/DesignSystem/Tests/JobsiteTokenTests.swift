import SwiftUI
import Testing
@testable import DesignSystem

@Suite("Jobsite Instrument tokens")
struct JobsiteTokenTests {
    @Test("Capture tap targets meet the glove-friendly 56pt floor")
    func tapTargetsMeetFloor() {
        #expect(JobsiteMetrics.minimumTapTargetPoints >= 56)
    }

    @Test("Body type never drops below 17pt")
    func bodyTypeMeetsFloor() {
        #expect(JobsiteMetrics.minimumBodyPointSize >= 17)
    }

    @Test("Semantic state colors are distinct — amber, green, and orange may never collide")
    func semanticColorsAreDistinct() {
        let semantic = [
            JobsitePalette.safetyOrange,
            JobsitePalette.unreviewedAmber,
            JobsitePalette.confirmedGreen,
        ]

        #expect(Set(semantic).count == semantic.count)
    }

    @Test("Field and report surfaces are different worlds (charcoal vs paper)")
    func surfacesDiffer() {
        #expect(JobsitePalette.surface != JobsitePalette.paper)
    }
}
