import SwiftUI

/// First-launch Arrival flow (Direction D): brand → practice → begin.
/// No Skip — the practice page is part of the introduction.
struct OnboardingView: View {
    var onBegin: () -> Void

    @State private var scene = 0
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    private let sceneCount = 3

    private var auroraTint: Color {
        switch scene {
        case 0: Color(hex: 0x8B7BFF)
        case 1: Color(hex: 0x3EDDC5)
        default: Color(hex: 0x8B7BFF)
        }
    }

    var body: some View {
        ZStack {
            AuroraBackground(tint: auroraTint.opacity(0.85))

            Group {
                switch scene {
                case 0: brandScene
                case 1: practiceScene
                default: beginScene
                }
            }
            .id(scene)
            .transition(sceneTransition)
            .padding(.horizontal, Metrics.screenMargin)
            .padding(.bottom, 120)

            VStack {
                Spacer()
                footer
            }
            .padding(.horizontal, Metrics.screenMargin)
            .padding(.bottom, 28)
        }
        .background(Ink.base)
        .preferredColorScheme(.dark)
        .animation(Springs.scene, value: scene)
    }

    private var sceneTransition: AnyTransition {
        if reduceMotion { return .opacity }
        return .asymmetric(
            insertion: .opacity.combined(with: .offset(y: 14)),
            removal: .opacity.combined(with: .offset(y: -10))
        )
    }

    // MARK: Scenes

    private var brandScene: some View {
        VStack(spacing: 0) {
            Spacer()
            brandMark(size: 72)
                .padding(.bottom, 36)

            Text("Rewire")
                .font(.voice(42, weight: .medium))
                .tracking(0.8)
                .foregroundStyle(Ink.textPrimary)

            Text("A practice for the pattern you keep repeating.")
                .font(.system(size: 14, design: .rounded))
                .foregroundStyle(Ink.textSecondary)
                .lineLimit(1)
                .minimumScaleFactor(0.85)
                .padding(.top, 14)
            Spacer()
        }
        .frame(maxWidth: .infinity)
    }

    private var practiceScene: some View {
        VStack(alignment: .leading, spacing: 0) {
            Spacer(minLength: 12)

            TrackedLabel(text: "The practice", size: 10, color: RepStage.choose.color)
                .padding(.bottom, 18)

            Text("Don’t fight the pattern,\nrehearse a new one.")
                .font(.voice(32, weight: .medium))
                .foregroundStyle(Ink.textPrimary)
                .lineSpacing(4)
                .padding(.bottom, 20)

            Text("Each rehearsal strengthens the new pathway. Train it until the new path is the one your mind reaches for first.")
                .font(.system(size: 15, design: .rounded))
                .foregroundStyle(Ink.textSecondary)
                .lineSpacing(5)
                .fixedSize(horizontal: false, vertical: true)
                .frame(maxWidth: 300, alignment: .leading)

            VStack(spacing: 0) {
                pillarRow(stage: .notice, line: "See it happening")
                pillarRow(stage: .accept, line: "Let it be here")
                pillarRow(stage: .choose, line: "Take the new path", isLast: true)
            }
            .padding(.top, 40)

            // Centers the epigraph in the band between the pillars and the page dots.
            Spacer(minLength: 0)
            Text("“The signal you amplify becomes\nthe reality you perceive.”")
                .font(.voice(16.5, weight: .regular))
                .italic()
                .foregroundStyle(Ink.textPrimary.opacity(0.58))
                .tracking(-0.25)
                .lineSpacing(7)
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)
                .frame(maxWidth: .infinity)
            Spacer(minLength: 0)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var beginScene: some View {
        VStack(spacing: 0) {
            Spacer()
            brandMark(size: 48)
                .padding(.bottom, 28)

            Text("Name one pattern.")
                .font(.voice(30, weight: .medium))
                .foregroundStyle(Ink.textPrimary)
                .padding(.bottom, 12)

            Text("Road rage. Doomscrolling. Snapping at the kids.\nShort and honest — the way you’d say it to yourself.")
                .font(.system(size: 14, design: .rounded))
                .foregroundStyle(Ink.textSecondary)
                .multilineTextAlignment(.center)
                .lineSpacing(4)
                .frame(maxWidth: 260)
            Spacer()
        }
        .frame(maxWidth: .infinity)
    }

    // MARK: Pieces

    private func brandMark(size: CGFloat) -> some View {
        ZStack {
            Circle()
                .stroke(RepStage.choose.color.opacity(0.35), lineWidth: 1)
                .shadow(color: RepStage.choose.color.opacity(0.2), radius: 16)
            Circle()
                .fill(
                    RadialGradient(
                        colors: [
                            Ink.textPrimary.opacity(0.9),
                            RepStage.choose.color.opacity(0.55),
                            RepStage.accept.color.opacity(0.2)
                        ],
                        center: UnitPoint(x: 0.4, y: 0.35),
                        startRadius: 2,
                        endRadius: size * 0.5
                    )
                )
                .padding(size * 0.25)
                .shadow(color: RepStage.choose.color.opacity(0.45), radius: 14)
        }
        .frame(width: size, height: size)
    }

    private func pillarRow(stage: RepStage, line: String, isLast: Bool = false) -> some View {
        HStack(alignment: .firstTextBaseline, spacing: 16) {
            Text(stage.title.uppercased())
                .font(.system(size: 11, weight: .semibold))
                .tracking(1.4)
                .foregroundStyle(stage.color)
                .frame(width: 72, alignment: .leading)

            Text(line)
                .font(.voice(17))
                .italic()
                .foregroundStyle(Ink.textPrimary)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(.vertical, 16)
        .overlay(alignment: .top) {
            Rectangle().fill(Ink.hairline).frame(height: 1)
        }
        .overlay(alignment: .bottom) {
            if isLast {
                Rectangle().fill(Ink.hairline).frame(height: 1)
            }
        }
    }

    private var footer: some View {
        VStack(spacing: 20) {
            HStack(spacing: 7) {
                ForEach(0..<sceneCount, id: \.self) { index in
                    Capsule()
                        .fill(index == scene ? RepStage.choose.color : Color.white.opacity(0.14))
                        .frame(width: index == scene ? 18 : 6, height: 6)
                        .shadow(
                            color: index == scene ? RepStage.choose.color.opacity(0.5) : .clear,
                            radius: 5
                        )
                        .animation(Springs.standard, value: scene)
                }
            }

            Button {
                advance()
            } label: {
                Text(scene == sceneCount - 1 ? "Begin" : "Continue")
                    .font(.system(size: 16, weight: .semibold, design: .rounded))
                    .foregroundStyle(scene == sceneCount - 1 ? Color(hex: 0x0A0814) : Ink.base)
                    .frame(maxWidth: .infinity)
                    .frame(height: 54)
                    .background { ctaBackground }
            }
            .buttonStyle(PressableStyle())
        }
    }

    @ViewBuilder
    private var ctaBackground: some View {
        let isBegin = scene == sceneCount - 1
        if isBegin {
            Capsule()
                .fill(
                    LinearGradient(
                        colors: [Color(hex: 0xC4BBFF), RepStage.choose.color],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .shadow(color: RepStage.choose.color.opacity(0.4), radius: 16, y: 4)
        } else {
            Capsule()
                .fill(Ink.textPrimary)
                .shadow(color: .black.opacity(0.4), radius: 16, y: 4)
        }
    }

    private func advance() {
        if scene < sceneCount - 1 {
            scene += 1
        } else {
            onBegin()
        }
    }
}

#Preview {
    OnboardingView(onBegin: {})
}
