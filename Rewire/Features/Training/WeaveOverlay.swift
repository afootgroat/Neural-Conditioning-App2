import SwiftUI

/// Full-screen maturity-advancement moment: the `weave` shader braids threads
/// of light while the new stage name types on in the serif voice. Runs for
/// ~2.8s, or dismisses immediately on tap.
struct WeaveOverlay: View {
    var stage: MaturityStage
    var hue: Color
    var onFinished: () -> Void

    @State private var startedAt: Date = .now
    @State private var showTitle = false
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    private static let duration = 2.8

    var body: some View {
        ZStack {
            Ink.base.opacity(0.6).ignoresSafeArea()

            GeometryReader { geo in
                TimelineView(.animation) { context in
                    let elapsed = context.date.timeIntervalSince(startedAt)
                    let progress = min(1, max(0, elapsed / Self.duration))
                    Rectangle()
                        .fill(.white)
                        .colorEffect(
                            ShaderLibrary.weave(
                                .float2(geo.size),
                                .float(Float(reduceMotion ? 0 : elapsed)),
                                .color(hue),
                                .float(Float(reduceMotion ? 0.35 : progress))
                            )
                        )
                }
            }
            .ignoresSafeArea()
            .allowsHitTesting(false)

            VStack(spacing: 16) {
                TrackedLabel(text: "New stage", size: 11, color: Ink.textSecondary)
                    .opacity(showTitle ? 1 : 0)
                Text(stage.title)
                    .font(.voice(38, weight: .medium))
                    .foregroundStyle(Ink.textPrimary)
                    .opacity(showTitle ? 1 : 0)
                    .blur(radius: showTitle ? 0 : 6)
                    .scaleEffect(showTitle ? 1 : 0.96)
                Text(stage.meaning)
                    .font(.voice(16))
                    .foregroundStyle(Ink.textSecondary)
                    .opacity(showTitle ? 0.9 : 0)
            }
            .multilineTextAlignment(.center)
            .padding(.horizontal, 40)
        }
        .contentShape(Rectangle())
        .onTapGesture(perform: finish)
        .transition(.opacity)
        .task {
            withAnimation(Springs.scene.delay(0.35)) { showTitle = true }
            try? await Task.sleep(for: .seconds(Self.duration))
            finish()
        }
    }

    private func finish() {
        withAnimation(.easeOut(duration: 0.4)) { onFinished() }
    }
}
