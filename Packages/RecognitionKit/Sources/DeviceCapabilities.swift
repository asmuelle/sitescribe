import Foundation

/// Snapshot of what the current device can do, taken at capture time and
/// stored alongside the capture. Invariant 3: nothing may hard-require the
/// advanced tier — every flow must work with `universal`.
public struct DeviceCapabilities: Codable, Hashable, Sendable {
    /// On-device language model available for text-only guided generation.
    public let afmTextAvailable: Bool
    /// Image-input model tier (AFM Core Advanced class) available.
    public let afmImageInputAvailable: Bool

    public init(afmTextAvailable: Bool, afmImageInputAvailable: Bool) {
        self.afmTextAvailable = afmTextAvailable
        self.afmImageInputAvailable = afmImageInputAvailable
    }

    /// The baseline every supported device meets: Vision OCR + barcode +
    /// regex parsers only. All features must function at this level.
    public static let universal = DeviceCapabilities(
        afmTextAvailable: false,
        afmImageInputAvailable: false
    )

    /// Probes the running device. On platforms or OS versions without
    /// FoundationModels this reports `universal` — never throws, never blocks.
    public static func probe() -> DeviceCapabilities {
        #if canImport(FoundationModels)
            if #available(iOS 26.0, macOS 26.0, *) {
                return DeviceCapabilities(
                    afmTextAvailable: FoundationModelsProbe.isTextModelAvailable(),
                    afmImageInputAvailable: false // image-input tier gating lands with M2
                )
            }
            return .universal
        #else
            return .universal
        #endif
    }
}

#if canImport(FoundationModels)
    import FoundationModels

    @available(iOS 26.0, macOS 26.0, *)
    enum FoundationModelsProbe {
        static func isTextModelAvailable() -> Bool {
            if case .available = SystemLanguageModel.default.availability {
                return true
            }
            return false
        }
    }
#endif
