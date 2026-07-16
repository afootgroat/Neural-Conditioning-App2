import SwiftUI

/// The app's living canvas: a slow value-noise aurora rendered by the
/// `aurora` Metal shader, tinted by context. `surge(_:)` triggers a brief
/// energy swell (used on maturity advancement) — envelopes are computed from
/// timestamps inside the TimelineView so they are frame-accurate without any
/// Animatable plumbing.
struct AuroraBackground: View {
    var tint: Color
    var surgeDate: Date? = nil

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    private static let epoch = Date()

    var body: some View {
        GeometryReader { geo in
            // Under Reduce Motion the field holds still, so stop ticking too.
            TimelineView(.animation(minimumInterval: 1.0 / 30.0, paused: reduceMotion)) { context in
                let t = reduceMotion ? 0 : context.date.timeIntervalSince(Self.epoch)
                let energy = surgeEnvelope(at: context.date)
                Rectangle()
                    .fill(Ink.base)
                    .colorEffect(
                        ShaderLibrary.aurora(
                            .float2(geo.size),
                            .float(Float(t)),
                            .color(tint),
                            .float(Float(energy))
                        )
                    )
            }
        }
        .ignoresSafeArea()
        .allowsHitTesting(false)
    }

    /// 0→1→0 swell over 2.4s, shaped like a struck bell.
    private func surgeEnvelope(at now: Date) -> Double {
        guard let surgeDate else { return 0 }
        let x = now.timeIntervalSince(surgeDate) / 2.4
        guard x > 0, x < 1 else { return 0 }
        let rise = min(1, x / 0.15)
        let fall = 1 - max(0, (x - 0.15) / 0.85)
        return rise * fall * fall
    }
}
