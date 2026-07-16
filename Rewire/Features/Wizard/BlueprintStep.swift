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
                            index: 0, label: "When", accent: RepStage.trigger.color,
                            content: Text(draft.stimulus).font(.voice(18))
                        )
                        blueprintRow(
                            index: 1, label: "I notice", accent: RepStage.notice.color,
                            content: noticeContent
                        )
                        blueprintRow(
                            index: 2, label: "I accept", accent: RepStage.accept.color,
                            content: Text("that it's here — without a fight.")
                                .font(.voice(18))
                        )
                        blueprintRow(
                            index: 3, label: "I choose \(draft.emotionName.lowercased())",
                            accent: RepStage.choose.color,
                            content: Text("“\(draft.mantra)”").font(.voice(18)),
                            isLast: true
                        )
                    }
                    .padding(24)
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

    private var noticeContent: some View {
        VStack(alignment: .leading, spacing: 6) {
            noticeLine("feeling", draft.oldFeelings)
            noticeLine("thinking", draft.oldThoughts)
            noticeLine("doing", draft.oldBehavior)
        }
    }

    @ViewBuilder
    private func noticeLine(_ verb: String, _ text: String) -> some View {
        if !text.trimmed.isEmpty {
            (Text("\(verb) ").font(.voice(15)).foregroundStyle(Ink.textTertiary)
             + Text(text).font(.voice(18)).foregroundStyle(Ink.textPrimary))
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    private func blueprintRow(
        index: Int, label: String, accent: Color,
        content: some View, isLast: Bool = false
    ) -> some View {
        HStack(alignment: .top, spacing: 16) {
            // The thread: a dot per stage, joined by a hairline.
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

            VStack(alignment: .leading, spacing: 6) {
                TrackedLabel(text: label, size: 10, color: accent.opacity(0.95))
                content
                    .foregroundStyle(Ink.textPrimary)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .padding(.bottom, isLast ? 0 : 24)

            Spacer(minLength: 0)
        }
        .fixedSize(horizontal: false, vertical: true)
    }
}
