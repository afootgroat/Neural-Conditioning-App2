import SwiftUI

// MARK: - Shared step scaffolding

/// Serif question + optional whisper of guidance, left-aligned like a page.
struct StepPrompt: View {
    var question: String
    var whisper: String? = nil

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(question)
                .font(.voice(28, weight: .medium))
                .foregroundStyle(Ink.textPrimary)
                .fixedSize(horizontal: false, vertical: true)
            if let whisper {
                Text(whisper)
                    .font(.system(size: 13, design: .rounded))
                    .foregroundStyle(Ink.textSecondary)
                    .lineSpacing(3)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

/// The wizard's writing surface: serif input over a hairline base line.
struct InkField: View {
    var placeholder: String
    @Binding var text: String
    var hue: Color
    var focusOnAppear: Bool = false
    var maxCharacters: Int? = nil
    var singleLine: Bool = false
    var onLimitReached: (() -> Void)? = nil

    @FocusState private var focused: Bool

    private var atLimit: Bool {
        guard let maxCharacters else { return false }
        return text.count >= maxCharacters
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Group {
                if singleLine {
                    TextField("", text: $text)
                } else {
                    TextField("", text: $text, axis: .vertical)
                        .lineLimit(1...4)
                }
            }
            .font(.voice(20))
            .foregroundStyle(Ink.textPrimary)
            .tint(hue)
            .focused($focused)
            .overlay(alignment: .leadingFirstTextBaseline) {
                if text.isEmpty {
                    Text(placeholder)
                        .font(.voice(20))
                        .foregroundStyle(Ink.textTertiary)
                        .allowsHitTesting(false)
                }
            }
            .onChange(of: text) { oldValue, newValue in
                guard let maxCharacters else { return }
                if newValue.count > maxCharacters {
                    text = String(newValue.prefix(maxCharacters))
                    onLimitReached?()
                } else if newValue.count == maxCharacters, oldValue.count < maxCharacters {
                    onLimitReached?()
                }
            }

            Rectangle()
                .fill(lineColor)
                .frame(height: 1)
                .shadow(color: atLimit ? hue.opacity(0.45) : .clear, radius: atLimit ? 6 : 0)
                .animation(.easeOut(duration: 0.28), value: focused)
                .animation(Springs.snappy, value: atLimit)
        }
        .contentShape(Rectangle())
        .onTapGesture { focused = true }
        .onAppear {
            if focusOnAppear {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.45) {
                    focused = true
                }
            }
        }
    }

    private var lineColor: Color {
        if atLimit { return hue.opacity(0.85) }
        if focused { return hue.opacity(0.7) }
        return Ink.hairline
    }
}

/// Ink field with the quiet countdown meter + italic settle whisper.
/// Used on name, stimulus, and each old-reaction line — one pattern, many surfaces.
struct LimitedInkField: View {
    var placeholder: String
    @Binding var text: String
    var hue: Color
    var maxCharacters: Int
    var whisper: String
    var singleLine: Bool = false
    var focusOnAppear: Bool = false

    @State private var showLimitWhisper = false
    @State private var didAnnounceLimit = false
    @State private var limitPulse = false

    private var remaining: Int { max(0, maxCharacters - text.count) }
    private var nearLimit: Bool { remaining <= 10 }
    private var atLimit: Bool { remaining == 0 }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            InkField(
                placeholder: placeholder,
                text: $text,
                hue: hue,
                focusOnAppear: focusOnAppear,
                maxCharacters: maxCharacters,
                singleLine: singleLine,
                onLimitReached: announceLimit
            )
            .scaleEffect(limitPulse ? 1.012 : 1, anchor: .leading)
            .animation(Springs.snappy, value: limitPulse)

            // Meter + whisper sit in one quiet row under the ink line.
            HStack(alignment: .firstTextBaseline, spacing: 12) {
                if showLimitWhisper {
                    Text(whisper)
                        .font(.voice(13))
                        .italic()
                        .foregroundStyle(Ink.textSecondary)
                        .transition(.asymmetric(
                            insertion: .opacity.combined(with: .offset(y: 5)),
                            removal: .opacity
                        ))
                }

                Spacer(minLength: 8)

                if nearLimit {
                    meter
                        .transition(.opacity.combined(with: .scale(scale: 0.92, anchor: .trailing)))
                }
            }
            .padding(.top, 10)
            .frame(minHeight: 20)
            .animation(Springs.standard, value: showLimitWhisper)
            .animation(Springs.standard, value: nearLimit)
        }
        .onChange(of: text) { _, newValue in
            if newValue.count < maxCharacters {
                didAnnounceLimit = false
                withAnimation(Springs.standard) { showLimitWhisper = false }
            }
        }
        .accessibilityElement(children: .contain)
        .accessibilityHint(atLimit
                           ? "Limit reached, \(maxCharacters) characters"
                           : "\(remaining) characters remaining")
    }

    /// Countdown, not a fraction — quieter, more intentional.
    private var meter: some View {
        HStack(spacing: 6) {
            if atLimit {
                Circle()
                    .fill(hue.opacity(0.9))
                    .frame(width: 4, height: 4)
                    .shadow(color: hue.opacity(0.7), radius: 3)
            }
            Text(atLimit ? "Set" : "\(remaining)")
                .font(.system(size: 11, weight: .semibold, design: .rounded))
                .monospacedDigit()
                .foregroundStyle(atLimit ? hue : Ink.textTertiary)
                .contentTransition(.numericText(value: Double(remaining)))
        }
        .accessibilityLabel(atLimit ? "Character limit reached" : "\(remaining) characters left")
    }

    private func announceLimit() {
        guard !didAnnounceLimit else { return }
        didAnnounceLimit = true
        Haptics.shared.tick()
        withAnimation(Springs.standard) { showLimitWhisper = true }
        // A single soft settle on the field — not a shake.
        limitPulse = true
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.18) {
            limitPulse = false
        }
    }
}

// MARK: - Step 1 · Name

struct NameStep: View {
    @Binding var draft: Pathway

    var body: some View {
        VStack(alignment: .leading, spacing: 36) {
            StepPrompt(
                question: "Name the pattern.",
                whisper: "Short and honest — the way you'd describe it to yourself. “Road rage.” “Doomscrolling.” “Snapping at the kids.”"
            )

            LimitedInkField(
                placeholder: "Road rage",
                text: $draft.name,
                hue: draft.hue.color,
                maxCharacters: Metrics.nameMaxLength,
                whisper: "A name, not a sentence.",
                singleLine: true,
                focusOnAppear: true
            )
        }
        .padding(.top, 24)
    }
}

// MARK: - Step 2 · Stimulus

struct StimulusStep: View {
    @Binding var draft: Pathway

    var body: some View {
        VStack(alignment: .leading, spacing: 36) {
            StepPrompt(
                question: "What sets it off?",
                whisper: "The trigger, as a scene you can picture. You'll rehearse summoning this moment on purpose."
            )

            LimitedInkField(
                placeholder: "Someone cuts me off in traffic",
                text: $draft.stimulus,
                hue: draft.hue.color,
                maxCharacters: Metrics.stimulusMaxLength,
                whisper: "Brief enough to summarize in a single breath.",
                focusOnAppear: true
            )
        }
        .padding(.top, 24)
    }
}

// MARK: - Step 3 · The old reaction

struct OldReactionStep: View {
    @Binding var draft: Pathway

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 28) {
                StepPrompt(
                    question: "What happens now?",
                    whisper: "Capture the old reaction for your record — so you can recognize it later. It won’t be practiced in training."
                )

                labeledLimited(
                    "I feel…",
                    placeholder: "A hot flash of anger",
                    text: $draft.oldFeelings,
                    whisper: "Name the feeling."
                )
                labeledLimited(
                    "I think…",
                    placeholder: "“They did that on purpose.”",
                    text: $draft.oldThoughts,
                    whisper: "One thought."
                )
                labeledLimited(
                    "I do…",
                    placeholder: "Tailgate, mutter, grip the wheel",
                    text: $draft.oldBehavior,
                    whisper: "Just the action."
                )
            }
            .padding(.top, 24)
            .padding(.bottom, 8)
        }
        .scrollIndicators(.hidden)
        .scrollDismissesKeyboard(.interactively)
    }

    private func labeledLimited(_ label: String, placeholder: String,
                                text: Binding<String>, whisper: String) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            TrackedLabel(text: label, size: 11, color: draft.hue.color.opacity(0.9))
            LimitedInkField(
                placeholder: placeholder,
                text: text,
                hue: draft.hue.color,
                maxCharacters: Metrics.reactionMaxLength,
                whisper: whisper,
                singleLine: true
            )
        }
    }
}

// MARK: - Step 4 · The new response

struct NewResponseStep: View {
    @Binding var draft: Pathway
    @State private var customMantra = ""

    private var selectedPreset: EmotionPreset? {
        EmotionPreset.named(draft.emotionName)
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 30) {
                StepPrompt(
                    question: "Choose the new path.",
                    whisper: "When the trigger comes, what do you want to feel instead — and what will you say to yourself?"
                )

                emotionGrid

                if let preset = selectedPreset {
                    mantraPicker(preset)
                        .transition(.opacity.combined(with: .move(edge: .bottom)))
                }
            }
            .padding(.top, 24)
            .padding(.bottom, 24)
            .animation(Springs.standard, value: draft.emotionName)
        }
        .scrollIndicators(.hidden)
        .scrollDismissesKeyboard(.interactively)
        .onAppear {
            if !EmotionPreset.all.contains(where: { $0.mantras.contains(draft.mantra) }) {
                customMantra = String(draft.mantra.prefix(Metrics.mantraMaxLength))
            }
        }
    }

    private var emotionGrid: some View {
        LazyVGrid(columns: [GridItem(.flexible(), spacing: 10), GridItem(.flexible())],
                  spacing: 10) {
            ForEach(EmotionPreset.all) { preset in
                let selected = draft.emotionName == preset.name
                Button {
                    Haptics.shared.tick()
                    draft.emotionName = preset.name
                    draft.hue = preset.hue
                    // Reset mantra choice when the emotion changes.
                    if !preset.mantras.contains(draft.mantra), customMantra.isEmpty {
                        draft.mantra = ""
                    }
                } label: {
                    HStack(spacing: 9) {
                        Circle()
                            .fill(preset.hue.color)
                            .frame(width: 8, height: 8)
                            .shadow(color: preset.hue.color.opacity(selected ? 0.9 : 0),
                                    radius: 4)
                        Text(preset.name)
                            .font(.system(size: 15, weight: .medium, design: .rounded))
                            .foregroundStyle(selected ? Ink.textPrimary : Ink.textSecondary)
                        Spacer(minLength: 0)
                    }
                    .padding(.horizontal, 16)
                    .frame(height: 52)
                    .background {
                        let shape = RoundedRectangle(cornerRadius: 18, style: .continuous)
                        shape.fill(selected ? preset.hue.color.opacity(0.14) : .white.opacity(0.04))
                            .overlay(shape.stroke(
                                selected ? preset.hue.color.opacity(0.6) : Ink.hairline,
                                lineWidth: 1))
                    }
                }
                .buttonStyle(PressableStyle())
                .animation(Springs.snappy, value: selected)
            }
        }
    }

    private func mantraPicker(_ preset: EmotionPreset) -> some View {
        VStack(alignment: .leading, spacing: 14) {
            TrackedLabel(text: "Your mantra", size: 11,
                         color: preset.hue.color.opacity(0.9))

            ForEach(preset.mantras, id: \.self) { mantra in
                let selected = draft.mantra == mantra
                Button {
                    Haptics.shared.tick()
                    draft.mantra = mantra
                    customMantra = ""
                } label: {
                    HStack {
                        Text("“\(mantra)”")
                            .font(.voice(17))
                            .foregroundStyle(selected ? Ink.textPrimary : Ink.textSecondary)
                            .multilineTextAlignment(.leading)
                        Spacer()
                        Image(systemName: "checkmark")
                            .font(.system(size: 12, weight: .bold))
                            .foregroundStyle(preset.hue.color)
                            .opacity(selected ? 1 : 0)
                            .scaleEffect(selected ? 1 : 0.5)
                    }
                    .padding(.horizontal, 18)
                    .padding(.vertical, 15)
                    .background {
                        let shape = RoundedRectangle(cornerRadius: 18, style: .continuous)
                        shape.fill(selected ? preset.hue.color.opacity(0.1) : .white.opacity(0.03))
                            .overlay(shape.stroke(
                                selected ? preset.hue.color.opacity(0.5) : Ink.hairline,
                                lineWidth: 1))
                    }
                }
                .buttonStyle(PressableStyle(scale: 0.98))
                .animation(Springs.snappy, value: selected)
            }

            // Or write your own — same quiet limit as the other ink fields.
            LimitedInkField(
                placeholder: "Or write your own…",
                text: $customMantra,
                hue: preset.hue.color,
                maxCharacters: Metrics.mantraMaxLength,
                whisper: "Short enough to say under pressure.",
                singleLine: true
            )
            .onChange(of: customMantra) { _, newValue in
                if !newValue.trimmed.isEmpty {
                    draft.mantra = newValue.trimmed
                } else if !preset.mantras.contains(draft.mantra) {
                    draft.mantra = ""
                }
            }
            .padding(.top, 4)
        }
    }
}
