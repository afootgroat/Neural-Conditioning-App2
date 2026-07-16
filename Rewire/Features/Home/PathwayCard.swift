import SwiftUI

/// One pathway on the home screen: name, maturity, a thread of progress,
/// a spark for practice-today, and an optional quiet moon to set it down.
struct PathwayCard: View {
    var pathway: Pathway
    /// Reserves trailing space for `PathwayRestButton` overlaid by Home.
    var reservesRestSlot: Bool = true

    var body: some View {
        GlassCard(tint: pathway.hue.color) {
            VStack(alignment: .leading, spacing: 16) {
                HStack(alignment: .center, spacing: 8) {
                    Text(pathway.name)
                        .font(.system(size: 19, weight: .semibold, design: .rounded))
                        .foregroundStyle(Ink.textPrimary)
                        .lineLimit(1)
                        .frame(maxWidth: .infinity, alignment: .leading)

                    spark

                    if reservesRestSlot {
                        // Matches PathwayRestButton so the overlaid moon aligns.
                        Color.clear.frame(width: 32, height: 32)
                    }
                }

                HStack(alignment: .center, spacing: 10) {
                    TrackedLabel(text: pathway.maturity.title, size: 10,
                                 color: pathway.hue.color)
                    Spacer()
                    if let remaining = pathway.repsToNextStage {
                        Text("\(remaining) to go")
                            .font(.system(size: 11, weight: .medium, design: .rounded))
                            .monospacedDigit()
                            .foregroundStyle(Ink.textTertiary)
                    } else {
                        Image(systemName: "infinity")
                            .font(.system(size: 10, weight: .semibold))
                            .foregroundStyle(pathway.hue.color.opacity(0.8))
                    }
                }

                ProgressThread(progress: pathway.progressToNextStage,
                               hue: pathway.hue.color)
            }
            .padding(20)
        }
        .accessibilityElement(children: .contain)
        .accessibilityLabel(accessibilitySummary)
    }

    /// Practiced-today indicator: a lit spark vs a resting ember.
    private var spark: some View {
        HStack(spacing: 5) {
            if pathway.practicedToday {
                RollingCounter(value: pathway.todayReps, size: 13,
                               color: pathway.hue.color)
            }
            Image(systemName: pathway.practicedToday ? "sparkle" : "circle.dotted")
                .font(.system(size: 12, weight: .semibold))
                .foregroundStyle(
                    pathway.practicedToday ? pathway.hue.color : Ink.textTertiary
                )
                .shadow(
                    color: pathway.practicedToday
                        ? pathway.hue.color.opacity(0.8) : .clear,
                    radius: 5
                )
        }
        .animation(Springs.bouncy, value: pathway.practicedToday)
        .accessibilityHidden(true)
    }

    private var accessibilitySummary: String {
        var parts = [
            pathway.name,
            "stage \(pathway.maturity.title)",
            "\(pathway.lifetimeReps) lifetime reps",
        ]
        parts.append(pathway.practicedToday
            ? "practiced today, \(pathway.todayReps) reps"
            : "not practiced today")
        return parts.joined(separator: ", ")
    }
}

/// Quiet moon control — composed above the NavigationLink so it never
/// steals the zoom transition or opens training by accident.
struct PathwayRestButton: View {
    var pathwayName: String
    var action: () -> Void

    var body: some View {
        Button {
            Haptics.shared.tick()
            action()
        } label: {
            Image(systemName: "moon.zzz")
                .font(.system(size: 13, weight: .medium))
                .foregroundStyle(Ink.textTertiary)
                .frame(width: 32, height: 32)
                .background(Circle().fill(Color.white.opacity(0.04)))
                .contentShape(Circle())
        }
        .buttonStyle(PressableStyle(scale: 0.88))
        .accessibilityLabel("Rest \(pathwayName)")
        .accessibilityHint("Moves this pathway to Resting. You can wake it later.")
    }
}
