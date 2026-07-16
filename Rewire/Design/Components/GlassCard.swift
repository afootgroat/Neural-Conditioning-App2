import SwiftUI

/// The app's one card material: tinted ultra-thin glass, continuous corners,
/// hairline stroke, and a faint top-edge glow instead of a drop shadow
/// (light comes from the aurora behind — depth by luminance, not shadow).
struct GlassCard<Content: View>: View {
    var cornerRadius: CGFloat = Metrics.cardRadius
    var tint: Color = .clear
    @ViewBuilder var content: Content

    var body: some View {
        content
            .background {
                let shape = RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                shape
                    .fill(.ultraThinMaterial)
                    .overlay(shape.fill(Ink.raised.opacity(0.55)))
                    .overlay(shape.fill(tint.opacity(0.06)))
                    .overlay {
                        // Top-edge light.
                        shape
                            .stroke(
                                LinearGradient(
                                    colors: [.white.opacity(0.14), .white.opacity(0.03)],
                                    startPoint: .top, endPoint: .bottom
                                ),
                                lineWidth: 1
                            )
                    }
                    .clipShape(shape)
            }
    }
}

/// A thin thread of light showing progress toward the next maturity stage.
/// The filled portion glows in the pathway's hue with a bright head.
struct ProgressThread: View {
    var progress: Double
    var hue: Color

    var body: some View {
        GeometryReader { geo in
            let width = geo.size.width
            let filled = max(0, min(1, progress)) * width
            ZStack(alignment: .leading) {
                Capsule().fill(Color.white.opacity(0.08))
                if progress > 0 {
                    Capsule()
                        .fill(
                            LinearGradient(
                                colors: [hue.opacity(0.25), hue],
                                startPoint: .leading, endPoint: .trailing
                            )
                        )
                        .frame(width: max(4, filled))
                        .shadow(color: hue.opacity(0.7), radius: 3)
                    // The bright head.
                    Circle()
                        .fill(.white)
                        .frame(width: 4, height: 4)
                        .shadow(color: hue, radius: 4)
                        .offset(x: max(4, filled) - 4)
                        .offset(y: (geo.size.height - 4) / 2)
                        .frame(maxHeight: .infinity, alignment: .top)
                }
            }
        }
        .frame(height: 3)
    }
}

/// Rolling numeral that animates digit changes without layout jitter.
struct RollingCounter: View {
    var value: Int
    var size: CGFloat = 17
    var weight: Font.Weight = .semibold
    var color: Color = Ink.textPrimary

    var body: some View {
        Text("\(value)")
            .font(.counter(size, weight: weight))
            .monospacedDigit()
            .foregroundStyle(color)
            .contentTransition(.numericText(value: Double(value)))
    }
}

/// One aggregate stat in the home header strip.
struct StatBlock: View {
    var value: Int
    var label: String

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            RollingCounter(value: value, size: 26, weight: .bold)
            TrackedLabel(text: label, size: 10, color: Ink.textTertiary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

/// Capsule call-to-action tinted by context hue.
struct GlowButton: View {
    var title: String
    var hue: Color
    var prominent: Bool = true
    var action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.system(size: 16, weight: .semibold, design: .rounded))
                .foregroundStyle(prominent ? Ink.base : Ink.textPrimary)
                .frame(maxWidth: .infinity)
                .frame(height: 54)
                .background {
                    if prominent {
                        Capsule()
                            .fill(hue)
                            .shadow(color: hue.opacity(0.45), radius: 16, y: 4)
                    } else {
                        Capsule()
                            .fill(.white.opacity(0.06))
                            .overlay(Capsule().stroke(Ink.hairline, lineWidth: 1))
                    }
                }
        }
        .buttonStyle(PressableStyle())
    }
}

/// Universal press feedback: a quick, springy compress.
struct PressableStyle: ButtonStyle {
    var scale: CGFloat = 0.96

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? scale : 1)
            .opacity(configuration.isPressed ? 0.9 : 1)
            .animation(Springs.snappy, value: configuration.isPressed)
    }
}
