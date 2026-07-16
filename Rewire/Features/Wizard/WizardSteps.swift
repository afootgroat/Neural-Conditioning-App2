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

    @FocusState private var focused: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            TextField("", text: $text, axis: .vertical)
                .font(.voice(20))
                .foregroundStyle(Ink.textPrimary)
                .tint(hue)
                .lineLimit(1...4)
                .focused($focused)
                .overlay(alignment: .leadingFirstTextBaseline) {
                    if text.isEmpty {
                        Text(placeholder)
                            .font(.voice(20))
                            .foregroundStyle(Ink.textTertiary)
                            .allowsHitTesting(false)
                    }
                }
            Rectangle()
                .fill(focused ? hue.opacity(0.7) : Ink.hairline)
                .frame(height: 1)
                .animation(.easeOut(duration: 0.25), value: focused)
        }
        .contentShape(Rectangle())
        .onTapGesture { focused = true }
        .onAppear {
            if focusOnAppear {
                // Let the step transition land before summoning the keyboard.
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.45) {
                    focused = true
                }
            }
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
            InkField(placeholder: "Road rage",
                     text: $draft.name, hue: draft.hue.color,
                     focusOnAppear: true)
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
            InkField(placeholder: "Someone cuts me off in traffic",
                     text: $draft.stimulus, hue: draft.hue.color,
                     focusOnAppear: true)
        }
        .padding(.top, 24)
    }
}

// MARK: - Step 3 · The old reaction

struct OldReactionStep: View {
    @Binding var draft: Pathway

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 32) {
                StepPrompt(
                    question: "What happens now?",
                    whisper: "Capture the old reaction so you can catch it in the act."
                )
                labeledField("I feel…", placeholder: "A hot flash of anger",
                             text: $draft.oldFeelings)
                labeledField("I think…", placeholder: "“They did that on purpose.”",
                             text: $draft.oldThoughts)
                labeledField("I do…", placeholder: "Tailgate, mutter, grip the wheel",
                             text: $draft.oldBehavior)
            }
            .padding(.top, 24)
        }
        .scrollIndicators(.hidden)
        .scrollDismissesKeyboard(.interactively)
    }

    private func labeledField(_ label: String, placeholder: String,
                              text: Binding<String>) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            TrackedLabel(text: label, size: 11, color: draft.hue.color.opacity(0.9))
            InkField(placeholder: placeholder, text: text, hue: draft.hue.color)
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
                customMantra = draft.mantra
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

            // Or write your own.
            InkField(placeholder: "Or write your own…",
                     text: $customMantra, hue: preset.hue.color)
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
