import SwiftUI

// MARK: - Color tokens

extension Color {
    /// sRGB hex, e.g. `Color(hex: 0xFF5C39)`.
    init(hex: UInt32, opacity: Double = 1) {
        self.init(
            .sRGB,
            red: Double((hex >> 16) & 0xFF) / 255,
            green: Double((hex >> 8) & 0xFF) / 255,
            blue: Double(hex & 0xFF) / 255,
            opacity: opacity
        )
    }
}

/// The Rewire palette. Dark-only by design — see docs/DESIGN.md §2.
enum Ink {
    static let base = Color(hex: 0x07070C)
    static let raised = Color(hex: 0x101018)
    static let textPrimary = Color(hex: 0xF4F2EC)
    static let textSecondary = Color(hex: 0x8E8E9E)
    static let textTertiary = Color(hex: 0x55555F)
    static let hairline = Color.white.opacity(0.08)
}

// MARK: - Typography

extension Font {
    /// Big rounded numerals that never jitter.
    static func counter(_ size: CGFloat, weight: Font.Weight = .semibold) -> Font {
        .system(size: size, weight: weight, design: .rounded)
    }

    /// The app's "inner voice" — mantras, prompts, cue text.
    static func voice(_ size: CGFloat, weight: Font.Weight = .regular) -> Font {
        .system(size: size, weight: weight, design: .serif)
    }
}

/// Uppercase, wide-tracked micro label — stage names, section headers.
struct TrackedLabel: View {
    var text: String
    var size: CGFloat = 12
    var weight: Font.Weight = .semibold
    var color: Color = Ink.textSecondary

    var body: some View {
        Text(text.uppercased())
            .font(.system(size: size, weight: weight))
            .kerning(size * 0.14)
            .foregroundStyle(color)
    }
}

// MARK: - Motion

enum Springs {
    /// Everyday movement.
    static let standard = Animation.spring(response: 0.45, dampingFraction: 0.82)
    /// Celebration — a touch of overshoot.
    static let bouncy = Animation.spring(response: 0.5, dampingFraction: 0.68)
    /// Stage taps — quick and settled.
    static let snappy = Animation.spring(response: 0.3, dampingFraction: 0.85)
    /// Slow scene shifts (cue overlay, blueprint reveal).
    static let scene = Animation.spring(response: 0.6, dampingFraction: 0.86)
}

// MARK: - Metrics

enum Metrics {
    static let cardRadius: CGFloat = 28
    static let screenMargin: CGFloat = 24
    static let orbDiameter: CGFloat = 288
}
