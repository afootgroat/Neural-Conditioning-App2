import SwiftUI

/// Final wizard step: the whole rewiring laid out as a ritual card —
/// the contract the user is about to start training.
struct BlueprintStep: View {
    var draft: Pathway
    var isEditing: Bool

    @State private var revealed = false

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 28) {
                StepPrompt(
                    question: "Your blueprint.",
                    whisper: isEditing
                        ? "Read it once, slowly. Then keep training."
                        : "Read it once, slowly. This is the path you'll practice."
                )

                GlassCard(tint: draft.hue.color) {
                    VStack(alignment: .leading, spacing: 0) {
                        blueprintRow(
                            label: "When", accent: RepStage.trigger.color,
                            content: whisperPhrase(draft.stimulus, size: 16, brighter: true)
                        )
                        blueprintRow(
                            label: "I notice", accent: RepStage.notice.color,
                            content: VStack(alignment: .leading, spacing: 0) {
                                whisperPhrase(PracticeScript.noticeLine1)
                                whisperPhrase(PracticeScript.noticeLine2)
                                Spacer().frame(height: 12)
                                whisperPhrase(PracticeScript.noticeAction)
                            }
                        )
                        blueprintRow(
                            label: "I accept", accent: RepStage.accept.color,
                            content: VStack(alignment: .leading, spacing: 0) {
                                whisperPhrase(PracticeScript.acceptLine1)
                                whisperPhrase(PracticeScript.acceptLine2)
                                Spacer().frame(height: 12)
                                whisperPhrase(PracticeScript.acceptAction)
                            }
                        )
                        blueprintRow(
                            label: "I choose \(draft.emotionName.lowercased())",
                            accent: RepStage.choose.color,
                            content: whisperPhrase(draft.mantra, brighter: true),
                            isLast: true
                        )
                    }
                    .padding(24)
                }

                if hasRecord {
                    recordCard
                }

                HStack(spacing: 8) {
                    Image(systemName: "lock")
                        .font(.system(size: 10, weight: .semibold))
                    Text("Stays on this device. No account, no cloud.")
                        .font(.system(size: 12, design: .rounded))
                }
                .foregroundStyle(Ink.textTertiary)
                .frame(maxWidth: .infinity)
            }
            .padding(.top, 24)
            .padding(.bottom, 24)
            .opacity(revealed ? 1 : 0)
            .offset(y: revealed ? 0 : 12)
        }
        .scrollIndicators(.hidden)
        .onAppear {
            withAnimation(Springs.scene.delay(0.15)) { revealed = true }
        }
    }

    /// Quiet italic body — Continuity A · Whisper italic.
    private func whisperPhrase(_ text: String, size: CGFloat = 15,
                               brighter: Bool = false) -> some View {
        Text(text)
            .font(.voice(size))
            .italic()
            .foregroundStyle(brighter
                             ? Ink.textPrimary.opacity(0.72)
                             : Ink.textSecondary)
            .fixedSize(horizontal: false, vertical: true)
    }

    private var hasRecord: Bool {
        !draft.oldFeelings.trimmed.isEmpty
            || !draft.oldThoughts.trimmed.isEmpty
            || !draft.oldBehavior.trimmed.isEmpty
    }

    private var recordCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                TrackedLabel(text: "Your record", size: 10, color: Ink.textTertiary)
                Spacer()
                Text("Not practiced · kept privately")
                    .font(.system(size: 10, design: .rounded))
                    .foregroundStyle(Ink.textTertiary)
            }
            recordLine("feeling", draft.oldFeelings)
            recordLine("thinking", draft.oldThoughts)
            recordLine("doing", draft.oldBehavior)
        }
        .padding(.horizontal, 18)
        .padding(.vertical, 16)
        .background {
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .fill(Color.white.opacity(0.025))
                .overlay(
                    RoundedRectangle(cornerRadius: 22, style: .continuous)
                        .stroke(Color.white.opacity(0.06), lineWidth: 1)
                )
        }
    }

    @ViewBuilder
    private func recordLine(_ verb: String, _ text: String) -> some View {
        if !text.trimmed.isEmpty {
            HStack(alignment: .top, spacing: 8) {
                Text(verb)
                    .font(.system(size: 11, design: .rounded))
                    .foregroundStyle(Ink.textTertiary)
                    .frame(width: 64, alignment: .leading)
                Text(text)
                    .font(.voice(14))
                    .italic()
                    .foregroundStyle(Ink.textTertiary)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .padding(.top, 4)
        }
    }

    private func blueprintRow(
        label: String, accent: Color,
        content: some View, isLast: Bool = false
    ) -> some View {
        HStack(alignment: .top, spacing: 16) {
            VStack(spacing: 0) {
                Circle()
                    .fill(accent)
                    .frame(width: 7, height: 7)
                    .shadow(color: accent.opacity(0.8), radius: 3)
                    .padding(.top, 5)
                if !isLast {
                    Rectangle()
                        .fill(Ink.hairline)
                        .frame(width: 1)
                        .frame(maxHeight: .infinity)
                        .padding(.vertical, 4)
                }
            }
            .frame(width: 8)

            VStack(alignment: .leading, spacing: 8) {
                TrackedLabel(text: label, size: 10, color: accent.opacity(0.95))
                content
            }
            .padding(.bottom, isLast ? 0 : 24)

            Spacer(minLength: 0)
        }
        .fixedSize(horizontal: false, vertical: true)
    }
}
