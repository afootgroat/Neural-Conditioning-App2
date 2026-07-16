import SwiftUI

/// Hold-to-reveal cue text for the current stage — the "script" the user is
/// rehearsing. Serif voice on an ink scrim; disappears on release.
/// Notice / Accept use fixed practice lines (not the old-reaction record).
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
                    .italic()
                    .foregroundStyle(Ink.textPrimary.opacity(0.85))
                Text("Bring it to mind. Let it feel real.")
                    .font(.voice(15))
                    .foregroundStyle(Ink.textSecondary)
            }
            .multilineTextAlignment(.center)

        case .notice:
            VStack(spacing: 0) {
                Text(PracticeScript.noticeLine1)
                Text(PracticeScript.noticeLine2)
                Spacer().frame(height: 14)
                Text(PracticeScript.noticeAction)
            }
            .font(.voice(22))
            .italic()
            .foregroundStyle(Ink.textPrimary.opacity(0.88))
            .multilineTextAlignment(.center)

        case .accept:
            VStack(spacing: 0) {
                Text(PracticeScript.acceptLine1)
                Text(PracticeScript.acceptLine2)
                Spacer().frame(height: 14)
                Text(PracticeScript.acceptAction)
            }
            .font(.voice(22))
            .italic()
            .foregroundStyle(Ink.textPrimary.opacity(0.88))
            .multilineTextAlignment(.center)

        case .choose:
            VStack(spacing: 18) {
                TrackedLabel(text: pathway.emotionName, size: 11,
                             color: pathway.hue.color)
                Text("“\(pathway.mantra)”")
                    .font(.voice(26))
                    .italic()
                    .foregroundStyle(Ink.textPrimary.opacity(0.9))
                    .multilineTextAlignment(.center)
            }
        }
    }
}
