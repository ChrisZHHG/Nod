import SwiftUI

// MARK: - App Root View (TCA-Style with @Observable Store)

struct AppRootView: View {
    @State private var store = AppStore()
    @State private var showErrorAlert: Bool = false
    @State private var showHistory = false

    /// True whenever an agent pipeline is actively running
    private var isProcessing: Bool {
        switch store.appState {
        case .decoding, .reasoning, .verifying: return true
        default: return false
        }
    }

    /// Extract error message from AppState.error, if any
    private var errorMessage: String? {
        if case .error(let error) = store.appState { return error.localizedDescription }
        return nil
    }

    var body: some View {
        ZStack {
            NavigationStack(path: $store.navigationPath) {
                ZStack {
                    Color.clear.ignoresSafeArea()
                    ModeSelectionRootView(store: store)
                }
                .navigationDestination(for: AppDestination.self) { destination in
                    switch destination {
                    case .scanner:
                        ScannerView(
                            images: store.capturedImages,
                            onCapture: { data in store.captureImage(data) },
                            onAnalyze: {
                                if store.mode == .agentChat {
                                    store.navigationPath.append(.agentChatLobby(isHost: true))
                                } else {
                                    store.navigationPath.append(.wizard)
                                }
                            },
                            onCancel: { store.resetSession() }
                        )
                        .navigationBarBackButtonHidden(true)
                    case .wizard:
                        ProgressiveWizardView(store: store)
                            .navigationBarBackButtonHidden(true)
                    case .agentChatLobby(let isHost):
                        AgentChatView(store: store, isHost: isHost)
                            .navigationBarBackButtonHidden(true)
                    case .soloResult(let recommendationSet):
                        MultiChoiceResultCarousel(
                            store: store,
                            mode: .individual,
                            soloSet: recommendationSet,
                            groupSet: nil
                        )
                        .navigationBarBackButtonHidden(true)
                    case .groupResult(let comboSet):
                        MultiChoiceResultCarousel(
                            store: store,
                            mode: .group,
                            soloSet: nil,
                            groupSet: comboSet
                        )
                        .navigationBarBackButtonHidden(true)
                    }
                }
            }
            .animation(.spring(response: 0.6, dampingFraction: 0.7), value: store.appState)

            // ── Simmer overlay — covers the whole app during AI processing ──
            if isProcessing {
                ProcessingView(store: store)
                    .zIndex(99)
                    .transition(.opacity.animation(.easeInOut(duration: 0.4)))
            }
        }
        .animation(.easeInOut(duration: 0.35), value: isProcessing)
        .onChange(of: errorMessage) { _, newValue in showErrorAlert = newValue != nil }
        // ── Error alert — surfaces any agent pipeline failure ──
        .alert("Something went wrong", isPresented: $showErrorAlert) {
            Button("Dismiss") { showErrorAlert = false }
        } message: {
            Text(errorMessage ?? "")
        }
        // ── History Sheet ──
        .sheet(isPresented: $showHistory) {
            HistoryView(store: store.historyStore) { entry in
                showHistory = false
            }
        }
        .environment(\.historyStoreKey, store.historyStore)
        .environment(\.showHistoryKey, $showHistory)
    }
}


// MARK: - Mode Selection Root

struct ModeSelectionRootView: View {
    let store: AppStore
    var body: some View {
        ModeSelectionContent(store: store)
    }
}

// MARK: - Hero Images

private let cinematicHeroURLs: [String] = [
    "https://images.unsplash.com/photo-1414235077428-338989a2e8c0?w=1200&q=85",
    "https://images.unsplash.com/photo-1569050467447-ce54b3bbc37d?w=1200&q=85",
    "https://images.unsplash.com/photo-1517248135467-4c7edcad34c4?w=1200&q=85",
    "https://images.unsplash.com/photo-1563245372-f21724e3856d?w=1200&q=85",
    "https://images.unsplash.com/photo-1559339352-11d035aa65de?w=1200&q=85",
    "https://images.unsplash.com/photo-1555949258-eb67b1ef0ceb?w=1200&q=85",
]

// MARK: - Mode Selection Content

struct ModeSelectionContent: View {
    let store: AppStore
    @Environment(\.historyStoreKey) private var historyStore
    @Environment(\.showHistoryKey) private var showHistory

    // Per-word opacity (0.9 base, breathes to 1.0 during intro sequence)
    @State private var opacities: [Double] = [0.9, 0.9, 0.9, 0.9]

    // Post-sequence reveals
    @State private var showButtons = false
    @State private var nodTilt: Double = 0

    // Hover state for plate buttons
    @State private var hoveredMode: AppMode? = nil
    @State private var isPressingIndividual = false
    @State private var isPressingGroup = false
    @State private var isPressingAgentChat = false

    private let heroURL: String = cinematicHeroURLs.randomElement()!

    var body: some View {
        ZStack {
            // Full-bleed hero image
            heroLayer

            // Gradient overlay — lighter at top so glass text reads
            NodTheme.Cinematic.heroOverlay.ignoresSafeArea()

            // Top-left title stack + bottom buttons
            VStack(alignment: .leading, spacing: 0) {

                // History button — top trailing corner
                HStack {
                    Spacer()
                    Button {
                        showHistory.wrappedValue = true
                    } label: {
                        Image(systemName: "clock.arrow.trianglehead.counterclockwise.rotate.90")
                            .font(.system(size: 20, weight: .light))
                            .foregroundStyle(.ultraThinMaterial)
                            .shadow(color: .black.opacity(0.4), radius: 4)
                            .padding(20)
                    }
                    .opacity(showButtons ? 1 : 0)
                    .animation(.easeIn(duration: 0.4).delay(0.3), value: showButtons)
                }

                // Vertical word stack — always in layout, never added/removed
                VStack(alignment: .leading, spacing: 16) {
                    glassWordWithIcon("Snap",   icon: "camera.fill",   index: 0, size: 50, weight: .light)
                    glassWordWithIcon("Decode", icon: "globe",          index: 1, size: 50, weight: .light)
                    glassWordWithIcon("Trust",  icon: "hand.tap.fill",  index: 2, size: 50, weight: .light)

                    // NOD — massive title treatment
                    nodWordGroup
                }
                .padding(.top, 8)
                .padding(.leading, 28)

                Spacer()

                // Bottom place-setting buttons
                placeSettingSection
                    .opacity(showButtons ? 1 : 0)
                    .offset(y: showButtons ? 0 : 40)
                    .animation(.spring(response: 0.7, dampingFraction: 0.8), value: showButtons)
                    .padding(.bottom, 50)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .ignoresSafeArea()
        .task {
            await runBreathingSequence()
        }
    }

    // MARK: - Liquid Glass Word (plain)

    @ViewBuilder
    private func glassWord(
        _ text: String,
        index: Int,
        size: CGFloat,
        weight: Font.Weight
    ) -> some View {
        Text(text)
            .font(.system(size: size, weight: weight, design: .rounded))
            .foregroundStyle(.ultraThinMaterial)
            .shadow(color: .white.opacity(0.28), radius: 4, x: 0, y: 1)
            .opacity(opacities[index])
            .animation(.easeInOut(duration: 0.55), value: opacities[index])
    }

    // MARK: - Liquid Glass Word + trailing SF Symbol icon

    @ViewBuilder
    private func glassWordWithIcon(
        _ text: String,
        icon: String,
        index: Int,
        size: CGFloat,
        weight: Font.Weight
    ) -> some View {
        HStack(alignment: .center, spacing: 9) {
            Text(text)
                .font(.system(size: size, weight: weight, design: .rounded))
                .foregroundStyle(.ultraThinMaterial)
                .shadow(color: .white.opacity(0.28), radius: 4, x: 0, y: 1)
            Image(systemName: icon)
                .font(.system(size: size * 0.52, weight: weight))
                .foregroundStyle(.ultraThinMaterial)
                .shadow(color: .white.opacity(0.22), radius: 3, x: 0, y: 1)
        }
        .opacity(opacities[index])
        .animation(.easeInOut(duration: 0.55), value: opacities[index])
    }

    // MARK: - NOD Word Group (large title + tagline)

    private var nodWordGroup: some View {
        VStack(alignment: .leading, spacing: 0) {
            // NOD letters — N and D white glass, O amber (nodding)
            HStack(alignment: .center, spacing: 0) {
                Text("N")
                    .font(.cinematicHero(size: 88))
                    .fontWeight(.black)
                    .foregroundStyle(.ultraThinMaterial)
                    .shadow(color: .white.opacity(0.2), radius: 3, x: 0, y: 1)

                // O — amber, bends forward on X axis (nodding yes)
                Text("O")
                    .font(.cinematicHero(size: 88))
                    .fontWeight(.black)
                    .foregroundColor(NodTheme.Cinematic.amber)
                    .rotation3DEffect(
                        .degrees(nodTilt),
                        axis: (x: 1, y: 0, z: 0),
                        anchor: .bottom,
                        perspective: 0.3
                    )

                Text("D")
                    .font(.cinematicHero(size: 88))
                    .fontWeight(.black)
                    .foregroundStyle(.ultraThinMaterial)
                    .shadow(color: .white.opacity(0.2), radius: 3, x: 0, y: 1)
            }

            // Tagline aligned below the D
            HStack(spacing: 0) {
                Spacer().frame(width: 120)
                Text("Your cultural dining guide.")
                    .font(.system(size: 10, weight: .light, design: .rounded))
                    .italic()
                    .foregroundStyle(.ultraThinMaterial)
            }
            .padding(.top, -4)
        }
        .shadow(color: .black.opacity(0.5), radius: 14, y: 7)
        .opacity(opacities[3])
        .animation(.easeInOut(duration: 0.8), value: opacities[3])
    }

    // MARK: - Hero Background Layer

    private var heroLayer: some View {
        GeometryReader { geo in
            AsyncImage(url: URL(string: heroURL)) { phase in
                switch phase {
                case .success(let img):
                    img.resizable().scaledToFill()
                        .frame(width: geo.size.width, height: geo.size.height)
                        .clipped()
                default:
                    // Fallback gradient while loading
                    ZStack {
                        LinearGradient(
                            stops: [
                                .init(color: Color(hex: "2C1810"), location: 0),
                                .init(color: Color(hex: "150D07"), location: 0.5),
                                .init(color: Color(hex: "101010"), location: 1)
                            ],
                            startPoint: .topTrailing, endPoint: .bottomLeading
                        )
                        Circle()
                            .fill(NodTheme.Cinematic.amber.opacity(0.07))
                            .frame(width: geo.size.width * 1.4)
                            .offset(y: -geo.size.height * 0.3)
                            .blur(radius: 80)
                    }
                    .frame(width: geo.size.width, height: geo.size.height)
                }
            }
        }
        .ignoresSafeArea()
    }

    // MARK: - Place-Setting Section

    private var placeSettingSection: some View {
        VStack(alignment: .center, spacing: 0) {
            Text("How are you dining today?")
                .font(.system(size: 14, weight: .light, design: .rounded))
                .italic()
                .tracking(0.5)
                .foregroundColor(.white.opacity(0.70))
                .shadow(color: .black, radius: 6)
                .padding(.bottom, 20)

            HStack(spacing: 20) {
                placeSettingButton(
                    mode: .individual,
                    title: "Solo Tasting",
                    subtitle: "Just for you",
                    isGroup: false,
                    isPressing: $isPressingIndividual
                ) {
                    store.setMode(.individual)
                    store.startSession()
                }

                placeSettingButton(
                    mode: .group,
                    title: "Grand Feast",
                    subtitle: "Sharing table",
                    isGroup: true,
                    isPressing: $isPressingGroup
                ) {
                    store.setMode(.group)
                    store.startSession()
                }

                placeSettingButton(
                    mode: .agentChat,
                    title: "Agent Chat",
                    subtitle: "AI Consensus",
                    isGroup: true,
                    isPressing: $isPressingAgentChat
                ) {
                    store.setMode(.agentChat)
                    store.startSession()
                }
            }
            .padding(.horizontal, 16)

            // Join as a Delegate (different action — not hosting, joining an existing table)
            Button(action: {
                store.setMode(.agentChat)
                store.navigationPath.append(.agentChatLobby(isHost: false))
            }) {
                HStack(spacing: 6) {
                    Image(systemName: "wave.3.left")
                        .font(.system(size: 11, weight: .regular))
                    Text("Join a Table")
                        .font(.system(size: 12, weight: .regular, design: .rounded))
                }
                .foregroundColor(.white.opacity(0.50))
            }
            .padding(.top, 18)
        }
        .frame(maxWidth: .infinity)
    }

    // MARK: - Breathing Sequence (looping async/await)

    private func runBreathingSequence() async {
        let breathIn:  UInt64 = 550_000_000   // 0.55s fade in
        let hold:      UInt64 = 500_000_000   // 0.5s hold
        let breathOut: UInt64 = 300_000_000   // 0.3s fade out
        let gap:       UInt64 = 120_000_000   // 0.12s gap between words
        try? await Task.sleep(nanoseconds: 400_000_000) // initial pause
        var cycleCount = 0
        var isFirstCycle = true

        while !Task.isCancelled {
            // After 1 cycle, keep NOD fully lit and stop the intro sequence
            if cycleCount >= 1 {
                withAnimation(.easeOut(duration: 1.0)) { opacities[3] = 1.0 }
                return 
            }

            // Snap, Simmer, Pick — breathe in, hold, breathe out
            for i in 0..<3 {
                withAnimation(.easeInOut(duration: 0.55)) { opacities[i] = 1.0 }
                try? await Task.sleep(nanoseconds: breathIn + hold)
                withAnimation(.easeIn(duration: 0.3)) { opacities[i] = 0.9 } // Vibrant base
                try? await Task.sleep(nanoseconds: breathOut + gap)
            }

            // NOD — breathe in and hold 1.8s
            withAnimation(.easeOut(duration: 0.6)) { opacities[3] = 1.0 }
            try? await Task.sleep(nanoseconds: 1_800_000_000)

            if isFirstCycle {
                isFirstCycle = false
                // Kick off nodding O and reveal buttons on first cycle only
                withAnimation(.easeInOut(duration: 0.9).repeatForever(autoreverses: true)) {
                    nodTilt = 15
                }
                try? await Task.sleep(nanoseconds: 400_000_000)
                showButtons = true
            }

            // Dim NOD briefly before settling (or looping if cycleCount > 1)
            cycleCount += 1
            if cycleCount < 1 {
                withAnimation(.easeIn(duration: 0.35)) { opacities[3] = 0.9 }
                try? await Task.sleep(nanoseconds: 400_000_000)
            }
        }
    }

    // MARK: - Plate Setting Button

    @ViewBuilder
    private func placeSettingButton(
        mode: AppMode,
        title: String,
        subtitle: String,
        isGroup: Bool,
        isPressing: Binding<Bool>,
        action: @escaping () -> Void
    ) -> some View {
        let isActive = hoveredMode == mode
        let isOtherActive = hoveredMode != nil && hoveredMode != mode

        VStack(spacing: 14) {
            // Plate visual
            ZStack {
                // Outer ring, highlight on active
                Circle()
                    .stroke(
                        NodTheme.Cinematic.amber.opacity(isActive ? 1.0 : 0.30),
                        lineWidth: isActive ? 2.5 : 1
                    )
                    .frame(width: 90, height: 90)

                // Plate fill
                Circle()
                    .fill(
                        isGroup
                            ? NodTheme.Cinematic.amber
                            : Color(hex: "F5F0E8")
                    )
                    .frame(width: 78, height: 78)
                    .shadow(
                        color: isGroup
                            ? NodTheme.Cinematic.amber.opacity(isActive ? 0.6 : 0.25)
                            : Color(hex: "F5F0E8").opacity(isActive ? 0.45 : 0.15),
                        radius: isActive ? 28 : 12
                    )

                // Mode icon — each mode gets a distinct symbol
                switch mode {
                case .agentChat:
                    Image(systemName: "person.wave.2.fill")
                        .font(.system(size: 30, weight: .semibold))
                        .foregroundColor(NodTheme.Cinematic.deepBlack)
                case .group:
                    Image(systemName: "person.3.fill")
                        .font(.system(size: 28, weight: .semibold))
                        .foregroundColor(NodTheme.Cinematic.deepBlack)
                case .individual:
                    Image(systemName: "person.fill")
                        .font(.system(size: 34, weight: .medium))
                        .foregroundColor(NodTheme.Cinematic.deepBlack.opacity(0.75))
                }
            }
            .scaleEffect(isActive ? 1.10 : (isOtherActive ? 0.92 : 1.0))
            .animation(.spring(response: 0.30, dampingFraction: 0.55), value: hoveredMode)

            // Labels
            VStack(spacing: 5) {
                Text(title.uppercased())
                    .font(.system(size: 15, weight: .black, design: .rounded))
                    .tracking(1.5)
                    .foregroundColor(.white)
                    .shadow(color: .black.opacity(0.85), radius: 5, y: 2)

                Text(subtitle)
                    .font(.system(size: 11, weight: .regular, design: .rounded))
                    .foregroundColor(.white.opacity(0.45))
                    .shadow(color: .black, radius: 5)
            }
        }
        .frame(maxWidth: .infinity)
        // Fade out non-hovered button
        .opacity(isOtherActive ? 0.30 : 1.0)
        .animation(.easeInOut(duration: 0.30), value: hoveredMode)
        // Press to spotlight, release to navigate
        .simultaneousGesture(
            DragGesture(minimumDistance: 0)
                .onChanged { _ in
                    if !isPressing.wrappedValue {
                        isPressing.wrappedValue = true
                        HapticFeedback.selection.trigger()
                        withAnimation(.spring(response: 0.25, dampingFraction: 0.7)) {
                            hoveredMode = mode
                        }
                    }
                }
                .onEnded { _ in
                    isPressing.wrappedValue = false
                    HapticFeedback.medium.trigger()
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) { action() }
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                        withAnimation(.easeOut(duration: 0.3)) { hoveredMode = nil }
                    }
                }
        )
    }
}
