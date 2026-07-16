import SwiftUI

/// Resting pathways. They keep their history; they can wake up again,
/// or be released for good (with their reps preserved in lifetime stats).
struct ArchiveView: View {
    @Environment(PathwayStore.self) private var store
    @Environment(\.dismiss) private var dismiss

    @State private var pendingDelete: Pathway? = nil

    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Resting")
                        .font(.voice(26, weight: .medium))
                        .foregroundStyle(Ink.textPrimary)
                    Text("Pathways you've set down. They remember everything.")
                        .font(.system(size: 13, design: .rounded))
                        .foregroundStyle(Ink.textSecondary)
                }
                Spacer()
            }
            .padding(.top, 28)

            if store.archived.isEmpty {
                VStack(spacing: 10) {
                    Image(systemName: "moon.zzz")
                        .font(.system(size: 28, weight: .light))
                        .foregroundStyle(Ink.textTertiary)
                    Text("Nothing is resting.")
                        .font(.voice(16))
                        .foregroundStyle(Ink.textTertiary)
                }
                .frame(maxWidth: .infinity)
                .padding(.top, 60)
            } else {
                ScrollView {
                    LazyVStack(spacing: 12) {
                        ForEach(store.archived) { pathway in
                            restingCard(pathway)
                        }
                    }
                    .padding(.bottom, 40)
                }
                .scrollIndicators(.hidden)
            }

            Spacer(minLength: 0)
        }
        .padding(.horizontal, Metrics.screenMargin)
        .preferredColorScheme(.dark)
        .confirmationDialog(
            "Release “\(pendingDelete?.name ?? "")”?",
            isPresented: Binding(
                get: { pendingDelete != nil },
                set: { if !$0 { pendingDelete = nil } }
            ),
            titleVisibility: .visible
        ) {
            Button("Release forever", role: .destructive) {
                if let pathway = pendingDelete {
                    withAnimation(Springs.standard) { store.delete(pathway.id) }
                }
                pendingDelete = nil
            }
        } message: {
            Text("Its reps stay in your lifetime total, but the blueprint is gone for good.")
        }
    }

    private func restingCard(_ pathway: Pathway) -> some View {
        GlassCard(cornerRadius: 22) {
            HStack(spacing: 14) {
                Circle()
                    .fill(pathway.hue.color.opacity(0.5))
                    .frame(width: 8, height: 8)

                VStack(alignment: .leading, spacing: 3) {
                    Text(pathway.name)
                        .font(.system(size: 16, weight: .semibold, design: .rounded))
                        .foregroundStyle(Ink.textSecondary)
                        .lineLimit(1)
                    Text("\(pathway.maturity.title) · \(pathway.lifetimeReps) reps")
                        .font(.system(size: 12, weight: .medium, design: .rounded))
                        .monospacedDigit()
                        .foregroundStyle(Ink.textSecondary.opacity(0.78))
                }

                Spacer()

                Button {
                    Haptics.shared.tick()
                    withAnimation(Springs.bouncy) { store.reactivate(pathway.id) }
                } label: {
                    Image(systemName: "sunrise")
                        .font(.system(size: 15, weight: .medium))
                        .foregroundStyle(pathway.hue.color)
                        .frame(width: 40, height: 40)
                        .background(Circle().fill(pathway.hue.color.opacity(0.12)))
                }
                .buttonStyle(PressableStyle(scale: 0.9))
                .accessibilityLabel("Reactivate \(pathway.name)")

                Button {
                    pendingDelete = pathway
                } label: {
                    Image(systemName: "xmark")
                        .font(.system(size: 13, weight: .medium))
                        .foregroundStyle(Ink.textTertiary)
                        .frame(width: 40, height: 40)
                        .background(Circle().fill(.white.opacity(0.05)))
                }
                .buttonStyle(PressableStyle(scale: 0.9))
                .accessibilityLabel("Delete \(pathway.name) forever")
            }
            .padding(.horizontal, 18)
            .padding(.vertical, 14)
        }
    }
}
