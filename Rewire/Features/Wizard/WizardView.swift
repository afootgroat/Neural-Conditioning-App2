import SwiftUI

enum WizardMode: Identifiable {
    case create
    case edit(Pathway)

    var id: String {
        switch self {
        case .create: "create"
        case .edit(let p): p.id.uuidString
        }
    }
}

/// The guided blueprint wizard. One question per screen, serif prompts,
/// progress dots, springy lateral step transitions.
struct WizardView: View {
    @Environment(PathwayStore.self) private var store
    @Environment(\.dismiss) private var dismiss

    let mode: WizardMode

    @State private var draft: Pathway
    @State private var step = 0
    @State private var goingForward = true

    private let stepCount = 5

    init(mode: WizardMode) {
        self.mode = mode
        switch mode {
        case .create: _draft = State(initialValue: Pathway())
        case .edit(let pathway): _draft = State(initialValue: pathway)
        }
    }

    private var isEditing: Bool {
        if case .edit = mode { return true } else { return false }
    }

    var body: some View {
        ZStack {
            AuroraBackground(tint: draft.hue.color.opacity(0.7))

            VStack(spacing: 0) {
                chrome
                stepBody
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
                footer
            }
            .padding(.horizontal, Metrics.screenMargin)
        }
        .background(Ink.base)
        .preferredColorScheme(.dark)
        .gesture(backSwipe)
    }

    // MARK: Chrome

    private var chrome: some View {
        HStack {
            Button {
                if step > 0 { go(to: step - 1) } else { dismiss() }
            } label: {
                Image(systemName: step > 0 ? "chevron.left" : "xmark")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(Ink.textSecondary)
                    .frame(width: 44, height: 44)
                    .background(Circle().fill(.white.opacity(0.06)))
                    .contentTransition(.symbolEffect(.replace))
            }
            .buttonStyle(PressableStyle(scale: 0.92))

            Spacer()
            progressDots
            Spacer()
            Color.clear.frame(width: 44, height: 44)
        }
        .padding(.top, 12)
        .padding(.bottom, 20)
    }

    private var progressDots: some View {
        HStack(spacing: 8) {
            ForEach(0..<stepCount, id: \.self) { i in
                Capsule()
                    .fill(i == step ? draft.hue.color : Color.white.opacity(0.15))
                    .frame(width: i == step ? 20 : 6, height: 6)
            }
        }
        .animation(Springs.snappy, value: step)
        .animation(Springs.snappy, value: draft.hue)
    }

    // MARK: Steps

    @ViewBuilder
    private var stepBody: some View {
        ZStack {
            Group {
                switch step {
                case 0: NameStep(draft: $draft)
                case 1: StimulusStep(draft: $draft)
                case 2: OldReactionStep(draft: $draft)
                case 3: NewResponseStep(draft: $draft)
                default: BlueprintStep(draft: draft, isEditing: isEditing)
                }
            }
            .id(step)
            .transition(.asymmetric(
                insertion: .move(edge: goingForward ? .trailing : .leading)
                    .combined(with: .opacity),
                removal: .move(edge: goingForward ? .leading : .trailing)
                    .combined(with: .opacity)
            ))
        }
        .animation(Springs.standard, value: step)
    }

    private var canAdvance: Bool {
        switch step {
        case 0: !draft.name.trimmed.isEmpty
        case 1: !draft.stimulus.trimmed.isEmpty
        case 2: !draft.oldFeelings.trimmed.isEmpty
        case 3: !draft.emotionName.isEmpty && !draft.mantra.trimmed.isEmpty
        default: true
        }
    }

    private var footer: some View {
        GlowButton(
            title: step < stepCount - 1
                ? "Continue"
                : (isEditing ? "Save blueprint" : "Begin training"),
            hue: draft.hue.color
        ) {
            if step < stepCount - 1 {
                go(to: step + 1)
            } else {
                commit()
            }
        }
        .disabled(!canAdvance)
        .opacity(canAdvance ? 1 : 0.35)
        .animation(.easeOut(duration: 0.2), value: canAdvance)
        .padding(.bottom, 16)
    }

    // MARK: Actions

    private func go(to newStep: Int) {
        goingForward = newStep > step
        Haptics.shared.tick()
        withAnimation(Springs.standard) { step = newStep }
    }

    private var backSwipe: some Gesture {
        DragGesture(minimumDistance: 30)
            .onEnded { value in
                if value.translation.width > 70, abs(value.translation.height) < 60,
                   step > 0 {
                    go(to: step - 1)
                }
            }
    }

    private func commit() {
        var final = draft
        final.name = final.name.trimmed
        final.stimulus = final.stimulus.trimmed
        final.oldFeelings = final.oldFeelings.trimmed
        final.oldThoughts = final.oldThoughts.trimmed
        final.oldBehavior = final.oldBehavior.trimmed
        final.mantra = final.mantra.trimmed
        if isEditing {
            store.update(final)
        } else {
            store.add(final)
        }
        Haptics.shared.repFired()
        dismiss()
    }
}

extension String {
    var trimmed: String { trimmingCharacters(in: .whitespacesAndNewlines) }
}
