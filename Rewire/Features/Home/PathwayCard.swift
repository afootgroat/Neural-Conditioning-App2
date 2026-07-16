import SwiftUI

/// One pathway on the home screen: name, maturity, a thread of progress,
/// and a spark that lights up once it has been practiced today.
struct PathwayCard: View {
    var pathway: Pathway

    var body: some View {
        GlassCard(tint: pathway.hue.color) {
            VStack(alignment: .leading, spacing: 16) {
                HStack(alignment: .firstTextBaseline) {
                    Text(pathway.name)
                        .font(.system(size: 19, weight: .semibold, design: .rounded))
                        .foregroundStyle(Ink.textPrimary)
                        .lineLimit(1)
                    Spacer()
                    spark
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
        .accessibilityElement(children: .combine)
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
