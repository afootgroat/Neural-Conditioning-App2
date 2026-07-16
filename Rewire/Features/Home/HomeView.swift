import SwiftUI

/// Home: greeting, aggregate stats, and the pathway garden. Cards zoom into
/// training; the wizard and archive live in sheets.
struct HomeView: View {
    @Environment(PathwayStore.self) private var store

    @Namespace private var zoom
    @State private var wizard: WizardMode? = nil
    @State private var showArchive = false

    var body: some View {
        NavigationStack {
            ZStack {
                AuroraBackground(tint: Color(hex: 0x4B4B8F))

                ScrollView {
                    VStack(alignment: .leading, spacing: 28) {
                        header
                        if store.active.isEmpty {
                            EmptyGarden { wizard = .create }
                                .padding(.top, 40)
                        } else {
                            statsStrip
                            pathwayList
                        }
                    }
                    .padding(.horizontal, Metrics.screenMargin)
                    .padding(.top, 8)
                    .padding(.bottom, 120)
                }
                .scrollIndicators(.hidden)

                if !store.active.isEmpty {
                    newPathwayButton
                }
            }
            .background(Ink.base)
            .navigationDestination(for: Pathway.ID.self) { id in
                TrainingView(pathwayID: id)
                    .navigationTransition(.zoom(sourceID: id, in: zoom))
            }
        }
        .preferredColorScheme(.dark)
        .fullScreenCover(item: $wizard) { mode in
            WizardView(mode: mode)
        }
        .sheet(isPresented: $showArchive) {
            ArchiveView()
                .presentationDetents([.medium, .large])
                .presentationBackground(.thinMaterial)
                .presentationCornerRadius(32)
        }
    }

    // MARK: Header

    private var greeting: String {
        switch Calendar.current.component(.hour, from: .now) {
        case 5..<12:  "Good morning."
        case 12..<18: "Good afternoon."
        default:      "Good evening."
        }
    }

    private var header: some View {
        HStack(alignment: .top) {
            VStack(alignment: .leading, spacing: 6) {
                Text(greeting)
                    .font(.voice(30, weight: .medium))
                    .foregroundStyle(Ink.textPrimary)
                if store.practicedTodayCount > 0 {
                    Text("You've practiced \(store.practicedTodayCount) of \(store.active.count) pathways today.")
                        .font(.system(size: 13, weight: .medium, design: .rounded))
                        .foregroundStyle(Ink.textSecondary)
                } else if !store.active.isEmpty {
                    Text("The mind rewires one rep at a time.")
                        .font(.voice(14))
                        .foregroundStyle(Ink.textSecondary)
                }
            }
            Spacer()
            if !store.archived.isEmpty || !store.active.isEmpty {
                Button {
                    showArchive = true
                } label: {
                    Image(systemName: "moon.zzz")
                        .font(.system(size: 15, weight: .medium))
                        .foregroundStyle(store.archived.isEmpty ? Ink.textTertiary : Ink.textSecondary)
                        .frame(width: 44, height: 44)
                        .background(Circle().fill(.white.opacity(0.05)))
                }
                .buttonStyle(PressableStyle(scale: 0.92))
                .accessibilityLabel("Resting pathways")
            }
        }
        .padding(.top, 16)
    }

    // MARK: Stats

    private var statsStrip: some View {
        GlassCard {
            HStack(spacing: 0) {
                StatBlock(value: store.active.count, label: "Pathways")
                divider
                StatBlock(value: store.todayReps, label: "Reps today")
                divider
                StatBlock(value: store.totalReps, label: "Lifetime")
            }
            .padding(.horizontal, 22)
            .padding(.vertical, 18)
        }
    }

    private var divider: some View {
        Rectangle().fill(Ink.hairline).frame(width: 1, height: 30)
            .padding(.trailing, 18)
    }

    // MARK: Pathways

    private var pathwayList: some View {
        LazyVStack(spacing: 14) {
            ForEach(store.active) { pathway in
                NavigationLink(value: pathway.id) {
                    PathwayCard(pathway: pathway)
                }
                .buttonStyle(PressableStyle(scale: 0.98))
                .matchedTransitionSource(id: pathway.id, in: zoom)
                .contextMenu {
                    Button {
                        wizard = .edit(pathway)
                    } label: {
                        Label("Edit blueprint", systemImage: "pencil.line")
                    }
                    Button {
                        withAnimation(Springs.standard) { store.archive(pathway.id) }
                    } label: {
                        Label("Rest pathway", systemImage: "moon.zzz")
                    }
                }
            }
        }
        .animation(Springs.standard, value: store.active.map(\.id))
    }

    // MARK: New pathway

    private var newPathwayButton: some View {
        VStack {
            Spacer()
            Button {
                wizard = .create
            } label: {
                HStack(spacing: 8) {
                    Image(systemName: "plus")
                        .font(.system(size: 14, weight: .bold))
                    Text("New pathway")
                        .font(.system(size: 15, weight: .semibold, design: .rounded))
                }
                .foregroundStyle(Ink.base)
                .padding(.horizontal, 22)
                .frame(height: 50)
                .background {
                    Capsule()
                        .fill(Ink.textPrimary)
                        .shadow(color: .black.opacity(0.5), radius: 24, y: 8)
                }
            }
            .buttonStyle(PressableStyle(scale: 0.94))
            .padding(.bottom, 24)
        }
    }
}

// MARK: - Empty state

private struct EmptyGarden: View {
    var onCreate: () -> Void

    var body: some View {
        VStack(spacing: 28) {
            // A quiet seed of the training orb.
            Circle()
                .fill(
                    RadialGradient(
                        colors: [Color(hex: 0x8B7BFF).opacity(0.5), .clear],
                        center: .center, startRadius: 4, endRadius: 70
                    )
                )
                .frame(width: 140, height: 140)
                .overlay(
                    Circle()
                        .stroke(Color(hex: 0x8B7BFF).opacity(0.5), lineWidth: 1)
                        .frame(width: 58, height: 58)
                )

            VStack(spacing: 10) {
                Text("Every pattern can be rewired.")
                    .font(.voice(24, weight: .medium))
                    .foregroundStyle(Ink.textPrimary)
                Text("Name a reaction you'd like to change,\nand design the response you want instead.")
                    .font(.system(size: 14, design: .rounded))
                    .foregroundStyle(Ink.textSecondary)
                    .lineSpacing(3)
            }
            .multilineTextAlignment(.center)

            GlowButton(title: "Begin", hue: Color(hex: 0x8B7BFF), action: onCreate)
                .frame(width: 200)
        }
        .frame(maxWidth: .infinity)
        .padding(.top, 40)
    }
}
