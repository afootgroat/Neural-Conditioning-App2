import SwiftUI

/// Home: greeting, aggregate stats, and the pathway garden. Cards zoom into
/// training; the wizard opens as a cover; resting pathways use an overlay
/// sheet so the moon can toggle it closed.
struct HomeView: View {
    @Environment(PathwayStore.self) private var store

    @Namespace private var zoom
    @State private var wizard: WizardMode? = nil
    @State private var showArchive = false
    @State private var pendingRest: Pathway? = nil
    @State private var restToast: String? = nil
    @State private var moonReceiving = false

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
                .allowsHitTesting(!showArchive && pendingRest == nil)

                if !store.active.isEmpty {
                    newPathwayButton
                        .opacity(showArchive || pendingRest != nil ? 0 : 1)
                        .allowsHitTesting(!showArchive && pendingRest == nil)
                }

                if showArchive {
                    archiveOverlay
                        .transition(.opacity)
                        .zIndex(1)
                }

                if let pathway = pendingRest {
                    restConfirmOverlay(pathway)
                        .transition(.opacity)
                        .zIndex(3)
                }

                if let restToast {
                    Text(restToast)
                        .font(.voice(14))
                        .italic()
                        .foregroundStyle(Ink.textSecondary)
                        .padding(.horizontal, 18)
                        .padding(.vertical, 12)
                        .background {
                            Capsule()
                                .fill(.ultraThinMaterial)
                                .overlay(Capsule().fill(Ink.raised.opacity(0.85)))
                                .overlay(Capsule().stroke(Ink.hairline, lineWidth: 1))
                        }
                        .padding(.bottom, 100)
                        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottom)
                        .transition(.opacity.combined(with: .offset(y: 10)))
                        .zIndex(4)
                        .allowsHitTesting(false)
                }

                // Moon stays above the scrim so it can toggle the sheet closed.
                if showsMoonButton {
                    VStack {
                        HStack {
                            Spacer()
                            moonButton
                        }
                        .padding(.horizontal, Metrics.screenMargin)
                        .padding(.top, 24)
                        Spacer()
                    }
                    .zIndex(5)
                }
            }
            .background(Ink.base)
            .animation(Springs.standard, value: showArchive)
            .animation(Springs.standard, value: pendingRest?.id)
            .animation(Springs.standard, value: restToast)
            .navigationDestination(for: Pathway.ID.self) { id in
                TrainingView(pathwayID: id)
                    .navigationTransition(.zoom(sourceID: id, in: zoom))
            }
        }
        .preferredColorScheme(.dark)
        .fullScreenCover(item: $wizard) { mode in
            WizardView(mode: mode)
        }
    }

    private var showsMoonButton: Bool {
        !store.archived.isEmpty || !store.active.isEmpty
    }

    private var moonButton: some View {
        Button {
            withAnimation(Springs.standard) { showArchive.toggle() }
        } label: {
            Image(systemName: "moon.zzz")
                .font(.system(size: 15, weight: .medium))
                .foregroundStyle(store.archived.isEmpty ? Ink.textTertiary : Ink.textSecondary)
                .frame(width: 44, height: 44)
                .background {
                    Circle()
                        .fill(.white.opacity(0.05))
                        .overlay {
                            Circle().stroke(
                                store.archived.isEmpty
                                    ? Color.clear
                                    : Color(hex: 0x8B7BFF).opacity(0.4),
                                lineWidth: 1
                            )
                        }
                        .shadow(
                            color: store.archived.isEmpty
                                ? .clear
                                : Color(hex: 0x8B7BFF).opacity(0.25),
                            radius: 10
                        )
                }
                .scaleEffect(moonReceiving ? 1.12 : 1)
        }
        .buttonStyle(PressableStyle(scale: 0.92))
        .accessibilityLabel("Resting pathways")
        .animation(Springs.bouncy, value: moonReceiving)
        .animation(Springs.standard, value: store.archived.isEmpty)
    }

    /// Custom resting sheet so the moon can toggle it closed and the
    /// dimmed area above dismisses — same interaction as the prototype.
    private var archiveOverlay: some View {
        GeometryReader { geo in
            ZStack(alignment: .bottom) {
                Color.black.opacity(0.45)
                    .ignoresSafeArea()
                    .onTapGesture {
                        withAnimation(Springs.standard) { showArchive = false }
                    }

                ArchiveView()
                    .frame(maxWidth: .infinity)
                    .frame(height: geo.size.height * 0.72, alignment: .top)
                    .background {
                        UnevenRoundedRectangle(
                            topLeadingRadius: 32, bottomLeadingRadius: 0,
                            bottomTrailingRadius: 0, topTrailingRadius: 32,
                            style: .continuous
                        )
                        .fill(.ultraThinMaterial)
                        .overlay {
                            UnevenRoundedRectangle(
                                topLeadingRadius: 32, bottomLeadingRadius: 0,
                                bottomTrailingRadius: 0, topTrailingRadius: 32,
                                style: .continuous
                            )
                            .fill(Ink.raised.opacity(0.55))
                        }
                        .ignoresSafeArea(edges: .bottom)
                    }
                    .transition(.move(edge: .bottom).combined(with: .opacity))
            }
        }
        .ignoresSafeArea(edges: .bottom)
    }

    private func restConfirmOverlay(_ pathway: Pathway) -> some View {
        ZStack(alignment: .bottom) {
            Color.black.opacity(0.45)
                .ignoresSafeArea()
                .onTapGesture {
                    withAnimation(Springs.standard) { pendingRest = nil }
                }

            RestConfirmSheet(
                pathwayName: pathway.name,
                onKeep: {
                    withAnimation(Springs.standard) { pendingRest = nil }
                },
                onRest: {
                    commitRest(pathway)
                }
            )
            .padding(.horizontal, 16)
            .padding(.bottom, 28)
            .transition(.move(edge: .bottom).combined(with: .opacity))
        }
    }

    private func commitRest(_ pathway: Pathway) {
        withAnimation(Springs.standard) { pendingRest = nil }

        moonReceiving = true
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.55) {
            moonReceiving = false
        }

        withAnimation(Springs.standard) {
            store.archive(pathway.id)
        }
        Haptics.shared.tick()

        withAnimation(Springs.standard) {
            restToast = "“\(pathway.name)” is resting."
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.4) {
            withAnimation(Springs.standard) {
                if restToast == "“\(pathway.name)” is resting." {
                    restToast = nil
                }
            }
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
            // Reserve space so the floating moon aligns with this slot.
            if showsMoonButton {
                Color.clear.frame(width: 44, height: 44)
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
                ZStack(alignment: .topTrailing) {
                    NavigationLink(value: pathway.id) {
                        PathwayCard(pathway: pathway)
                    }
                    .buttonStyle(PressableStyle(scale: 0.98))
                    .matchedTransitionSource(id: pathway.id, in: zoom)

                    // Moon sits above the link so taps never open training.
                    PathwayRestButton(pathwayName: pathway.name) {
                        withAnimation(Springs.standard) { pendingRest = pathway }
                    }
                    .padding(.top, 20)
                    .padding(.trailing, 20)
                }
                .contextMenu {
                    Button {
                        wizard = .edit(pathway)
                    } label: {
                        Label("Edit blueprint", systemImage: "pencil.line")
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
