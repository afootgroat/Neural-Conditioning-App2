import SwiftUI

/// The core loop. One focal point — the orb. Tap to move through
/// TRIGGER → NOTICE → ACCEPT → CHOOSE; the fourth tap fires a rep.
/// Long-press to reveal the current stage's cue text.
struct TrainingView: View {
    @Environment(PathwayStore.self) private var store
    @Environment(\.dismiss) private var dismiss

    let pathwayID: Pathway.ID

    // Rep-cycle state. Envelopes are timestamp-driven (see OrbView).
    @State private var stage: RepStage = .trigger
    @State private var previousStage: RepStage = .trigger
    @State private var stageChangedAt: Date = .distantPast
    @State private var firedAt: Date? = nil

    // Cue overlay (long-press) & celebration.
    @State private var isHolding = false
    @State private var cueVisible = false
    @State private var celebration: MaturityStage? = nil
    @State private var surgeDate: Date? = nil

    private var pathway: Pathway? { store.pathway(id: pathwayID) }

    /// Chrome recedes while the cue is held or a celebration is playing.
    private var chromeOpacity: Double { (cueVisible || celebration != nil) ? 0 : 1 }

    var body: some View {
        ZStack {
            if let pathway {
                content(for: pathway)
            }
        }
        .background(Ink.base)
        .toolbarVisibility(.hidden, for: .navigationBar)
        .statusBarHidden()
    }

    private func content(for pathway: Pathway) -> some View {
        ZStack {
            AuroraBackground(tint: stage.color, surgeDate: surgeDate)

            // The chrome recedes while the cue is held — only orb and words.
            VStack(spacing: 0) {
                header(pathway)
                    .opacity(chromeOpacity)
                Spacer()
                stageLabel
                    .padding(.bottom, 44)
                    .opacity(chromeOpacity)
                orb(pathway)
                Spacer()
                counters(pathway)
                    .padding(.bottom, 36)
                    .opacity(chromeOpacity)
            }
            .padding(.horizontal, Metrics.screenMargin)
            .animation(.easeOut(duration: 0.35), value: chromeOpacity)

            if cueVisible {
                CueOverlay(stage: stage, pathway: pathway)
                    .transition(.asymmetric(
                        insertion: .opacity.combined(with: .scale(scale: 1.02)),
                        removal: .opacity
                    ))
                    .zIndex(2)
                    .allowsHitTesting(false)
            }

            if let celebration {
                WeaveOverlay(stage: celebration, hue: pathway.hue.color) {
                    self.celebration = nil
                }
                .zIndex(3)
            }
        }
        .modifier(RepRipple(firedAt: firedAt))
        .animation(Springs.scene, value: cueVisible)
    }

    // MARK: Pieces

    private func header(_ pathway: Pathway) -> some View {
        HStack {
            Button {
                dismiss()
            } label: {
                Image(systemName: "chevron.down")
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(Ink.textSecondary)
                    .frame(width: 44, height: 44)
                    .background(Circle().fill(.white.opacity(0.06)))
            }
            .buttonStyle(PressableStyle(scale: 0.92))

            Spacer()

            VStack(spacing: 3) {
                Text(pathway.name)
                    .font(.system(size: 15, weight: .semibold, design: .rounded))
                    .foregroundStyle(Ink.textPrimary)
                TrackedLabel(text: pathway.maturity.title, size: 10,
                             color: pathway.hue.color.opacity(0.9))
            }

            Spacer()

            // Balance the close button so the title is truly centered.
            Color.clear.frame(width: 44, height: 44)
        }
        .padding(.top, 12)
    }

    private var stageLabel: some View {
        VStack(spacing: 10) {
            TrackedLabel(text: stage.title, size: 15, weight: .bold, color: stage.color)
                .id(stage) // new identity per stage → clean transition
                .transition(.asymmetric(
                    insertion: .move(edge: .bottom).combined(with: .opacity),
                    removal: .move(edge: .top).combined(with: .opacity)
                ))
            Text(stage.hint)
                .font(.voice(17))
                .foregroundStyle(Ink.textSecondary)
                .id("hint-\(stage.rawValue)")
                .transition(.opacity)
        }
        .animation(Springs.standard, value: stage)
        .frame(height: 64)
    }

    private func orb(_ pathway: Pathway) -> some View {
        ZStack {
            // Maturity arc — a hairline halo of progress around the synapse.
            Circle()
                .stroke(.white.opacity(0.07), lineWidth: 2)
                .frame(width: Metrics.orbDiameter + 44, height: Metrics.orbDiameter + 44)
            Circle()
                .trim(from: 0, to: pathway.progressToNextStage)
                .stroke(
                    pathway.hue.color.opacity(0.85),
                    style: StrokeStyle(lineWidth: 2, lineCap: .round)
                )
                .frame(width: Metrics.orbDiameter + 44, height: Metrics.orbDiameter + 44)
                .rotationEffect(.degrees(-90))
                .shadow(color: pathway.hue.color.opacity(0.6), radius: 4)
                .animation(Springs.scene, value: pathway.progressToNextStage)

            OrbView(
                stage: stage,
                previousStage: previousStage,
                stageChangedAt: stageChangedAt,
                firedAt: firedAt,
                // Seed shifts only when a rep fires — the interior stays
                // continuous within a rep, and no two reps render alike.
                seed: Double(pathway.lifetimeReps % 64),
                isHolding: isHolding
            )
        }
        .contentShape(Circle().inset(by: -22))
        .onTapGesture { advance(pathway) }
        .onLongPressGesture(minimumDuration: 0.35, maximumDistance: 80) {
            cueVisible = true
            Haptics.shared.revealOpen()
        } onPressingChanged: { pressing in
            isHolding = pressing
            if !pressing, cueVisible {
                cueVisible = false
                Haptics.shared.revealClose()
            }
        }
    }

    private func counters(_ pathway: Pathway) -> some View {
        VStack(spacing: 14) {
            HStack(spacing: 28) {
                counter(value: pathway.todayReps, label: "Today")
                Rectangle().fill(Ink.hairline).frame(width: 1, height: 26)
                counter(value: pathway.lifetimeReps, label: "Lifetime")
            }
            if let remaining = pathway.repsToNextStage, let next = pathway.maturity.next {
                Text("\(remaining) reps to \(next.title)")
                    .font(.system(size: 12, weight: .medium, design: .rounded))
                    .monospacedDigit()
                    .foregroundStyle(Ink.textTertiary)
                    .contentTransition(.numericText(value: Double(remaining)))
            } else {
                Text(MaturityStage.enlightenment.meaning)
                    .font(.voice(13))
                    .foregroundStyle(Ink.textTertiary)
            }
        }
        .animation(Springs.standard, value: pathway.lifetimeReps)
    }

    private func counter(value: Int, label: String) -> some View {
        VStack(spacing: 4) {
            RollingCounter(value: value, size: 24, weight: .bold)
            TrackedLabel(text: label, size: 9, color: Ink.textTertiary)
        }
    }

    // MARK: Rep cycle

    private func advance(_ pathway: Pathway) {
        guard celebration == nil else { return }

        let completed = stage
        previousStage = stage
        stage = stage.next
        stageChangedAt = .now

        if completed == .choose {
            // Full cycle — the rep fires.
            firedAt = .now
            Haptics.shared.repFired()
            let result = store.logRep(for: pathway.id)

            if let advanced = result?.advancedTo {
                // Let the fire land, then celebrate the new maturity stage.
                surgeDate = .now.addingTimeInterval(0.45)
                Task { @MainActor in
                    try? await Task.sleep(for: .milliseconds(450))
                    Haptics.shared.stageAdvanced()
                    withAnimation(Springs.scene) { celebration = advanced }
                }
            }
        } else {
            Haptics.shared.stage(completed)
        }
    }
}

// MARK: - Rep ripple (screen-space layer effect)

/// Refracts the whole training screen outward from the orb when a rep fires.
/// Always mounted (so view identity is stable); `active` gates the timeline,
/// flipping back off after the wave completes so the screen stops re-rendering.
private struct RepRipple: ViewModifier {
    var firedAt: Date?

    @State private var active = false

    private static let duration = 1.1

    func body(content: Content) -> some View {
        TimelineView(.animation(minimumInterval: nil, paused: !active)) { context in
            let progress = progress(at: context.date)
            let amplitude: Float = active && progress > 0 && progress < 1 ? 1 : 0
            content
                .visualEffect { view, proxy in
                    view.layerEffect(
                        ShaderLibrary.ripple(
                            .float2(proxy.size),
                            // The orb sits at ~52% of the screen's height.
                            .float2(CGPoint(x: proxy.size.width * 0.5,
                                            y: proxy.size.height * 0.52)),
                            .float(Float(progress)),
                            .float(amplitude)
                        ),
                        maxSampleOffset: CGSize(width: 40, height: 40)
                    )
                }
        }
        .task(id: firedAt) {
            guard firedAt != nil else { return }
            active = true
            try? await Task.sleep(for: .seconds(Self.duration + 0.05))
            active = false
        }
    }

    private func progress(at date: Date) -> Double {
        guard let firedAt else { return 0 }
        let x = date.timeIntervalSince(firedAt) / Self.duration
        return min(1, max(0, x))
    }
}
