import SwiftUI

/// Training-header control to revise a pathway's blueprint.
/// Same 44pt footprint as dismiss — quiet glass, pathway-tinted pencil.
struct BlueprintEditButton: View {
    var hue: Color
    var action: () -> Void

    var body: some View {
        Button {
            Haptics.shared.tick()
            action()
        } label: {
            Image(systemName: "pencil.line")
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(
                    LinearGradient(
                        colors: [Ink.textSecondary, hue.opacity(0.75)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .frame(width: 44, height: 44)
                .background(Circle().fill(Color.white.opacity(0.05)))
        }
        .buttonStyle(PressableStyle(scale: 0.92))
        .accessibilityLabel("Edit blueprint")
        .accessibilityHint("Revise this pathway's trigger, reaction, and mantra")
    }
}
