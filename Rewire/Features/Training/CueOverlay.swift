import SwiftUI

/// Hold-to-reveal cue text for the current stage — the "script" the user is
/// rehearsing. Serif voice on an ink scrim; disappears on release.
struct CueOverlay: View {
    var stage: RepStage
    var pathway: Pathway

    var body: some View {
        ZStack {
            // Scrim: keep the orb faintly visible beneath the words.
            LinearGradient(
                colors: [Ink.base.opacity(0.55), Ink.base.opacity(0.88), Ink.base.opacity(0.55)],
                startPoint: .top, endPoint: .bottom
            )
            .ignoresSafeArea()

            VStack(spacing: 22) {
                TrackedLabel(text: stage.title, size: 12, weight: .bold, color: stage.color)
                cueBody
            }
            .padding(.horizontal, 40)
            .frame(maxWidth: 480)
        }
    }

    @ViewBuilder
    private var cueBody: some View {
        switch stage {
        case .trigger:
            VStack(spacing: 14) {
                Text(pathway.stimulus)
                    .font(.voice(24))
                    .foregroundStyle(Ink.textPrimary)
                Text("Bring it to mind. Let it feel real.")
                    .font(.voice(15))
                    .foregroundStyle(Ink.textSecondary)
            }
            .multilineTextAlignment(.center)

        case .notice:
            VStack(alignment: .leading, spacing: 18) {
                cueRow(label: "Feeling", text: pathway.oldFeelings)
                cueRow(label: "Thinking", text: pathway.oldThoughts)
                cueRow(label: "Doing", text: pathway.oldBehavior)
            }

        case .accept:
            VStack(spacing: 16) {
                Text("It's already here.")
                Text("You don't have to fix the feeling.")
                Text("Breathe once, and let it be.")
            }
            .font(.voice(21))
            .foregroundStyle(Ink.textPrimary)
            .multilineTextAlignment(.center)

        case .choose:
            VStack(spacing: 18) {
                TrackedLabel(text: pathway.emotionName, size: 11,
                             color: pathway.hue.color)
                Text("“\(pathway.mantra)”")
                    .font(.voice(26))
                    .foregroundStyle(Ink.textPrimary)
                    .multilineTextAlignment(.center)
            }
        }
    }

    private func cueRow(label: String, text: String) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            TrackedLabel(text: label, size: 10, color: stage.color.opacity(0.9))
            Text(text)
                .font(.voice(19))
                .foregroundStyle(Ink.textPrimary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}
