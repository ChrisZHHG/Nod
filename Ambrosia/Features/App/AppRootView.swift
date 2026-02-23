import SwiftUI

// MARK: - App Root View (TCA-Style with @Observable Store)

struct AppRootView: View {
    @State private var store = AppStore()
    
    var body: some View {
        NavigationStack(path: $store.navigationPath) {
            ZStack {
                // Background
                LiquidBackground()
                
                // Root View - Mode Selection
                ModeSelectionRootView(store: store)
            }
            .navigationDestination(for: AppDestination.self) { destination in
                switch destination {
                case .scanner:
                    ScannerContainerView(store: store)
                        .navigationBarBackButtonHidden(true)
                case .result(let recommendation):
                    ResultRootView(recommendation: recommendation, store: store)
                        .navigationBarBackButtonHidden(true)
                case .combo(let combo):
                    ComboRootView(combo: combo, store: store)
                        .navigationBarBackButtonHidden(true)
                }
            }
        }
        .animation(.spring(response: 0.6, dampingFraction: 0.7), value: store.appState)
    }
}

// MARK: - Mode Selection Root (Wrapper for existing view)

struct ModeSelectionRootView: View {
    let store: AppStore
    
    var body: some View {
        // Reuse existing Bento Grid layout
        ModeSelectionContent(store: store)
    }
}

// MARK: - Mode Selection Content (Adapted from ModeSelectionView)

struct ModeSelectionContent: View {
    let store: AppStore
    @State private var animateIcons = false
    
    var body: some View {
        ScrollView(.vertical, showsIndicators: false) {
            VStack(spacing: 0) {
                headerSection
                    .padding(.top, 80)
                    .padding(.bottom, AmbrosiaTheme.Spacing.xxl)
                
                bentoGridSection
                    .padding(.horizontal, AmbrosiaTheme.Spacing.lg)
                
                footerSection
                    .padding(.top, AmbrosiaTheme.Spacing.xxxl)
                    .padding(.bottom, 40)
            }
        }
        .onAppear { animateIcons = true }
    }
    
    private var headerSection: some View {
        VStack(spacing: AmbrosiaTheme.Spacing.md) {
            ZStack {
                Circle()
                    .fill(AmbrosiaTheme.Gradients.coralSunset)
                    .frame(width: 80, height: 80)
                    .blur(radius: 25)
                    .opacity(0.5)
                
                Image(systemName: "fork.knife.circle.fill")
                    .font(.system(size: 56))
                    .foregroundStyle(AmbrosiaTheme.Gradients.coralSunset)
            }
            
            Text("Ambrosia")
                .font(AmbrosiaTheme.Typography.displayLarge)
                .foregroundStyle(AmbrosiaTheme.Colors.textPrimary)
            
            Text("How are we dining today?")
                .font(AmbrosiaTheme.Typography.title)
                .foregroundStyle(AmbrosiaTheme.Colors.textSecondary)
        }
    }
    
    private var bentoGridSection: some View {
        BentoGrid(columns: 2) {
            BentoHeroTile(
                title: "For Myself",
                subtitle: "Personal picks for your taste",
                icon: "person.fill",
                iconColor: AmbrosiaTheme.Colors.warmOrange,
                size: .tall
            ) {
                store.setMode(.individual)
                store.startSession()
            }
            
            BentoHeroTile(
                title: "Sharing",
                subtitle: "Dishes everyone will love",
                icon: "person.3.fill",
                iconColor: AmbrosiaTheme.Colors.coralEnd,
                size: .tall
            ) {
                store.setMode(.group)
                store.startSession()
            }
            
            BentoInfoTile(
                title: "AI-Powered Recommendations",
                description: "Scan any menu and get instant, personalized dish suggestions",
                gradient: AmbrosiaTheme.Gradients.coralSunset
            )
        }
    }
    
    private var footerSection: some View {
        HStack(spacing: AmbrosiaTheme.Spacing.sm) {
            Image(systemName: "sparkles")
                .font(.system(size: 12))
            Text("Powered by Gemini AI")
                .font(AmbrosiaTheme.Typography.caption)
        }
        .foregroundStyle(AmbrosiaTheme.Colors.textTertiary)
    }
}

// MARK: - Scanner Container (TCA-Style)

struct ScannerContainerView: View {
    let store: AppStore
    @State private var showGroupSetup = false
    
    var body: some View {
        ZStack {
            // Base: Camera Scanner
            ScannerView(
                images: store.capturedImages,
                onCapture: { image in store.captureImage(image) },
                onAnalyze: {
                    if store.mode == .group {
                        withAnimation { showGroupSetup = true }
                    } else {
                        Task { await store.generateRecommendation() }
                    }
                },
                onCancel: {
                    store.resetSession()
                }
            )
            .allowsHitTesting(!showGroupSetup)
            
            // Processing Overlays
            processingOverlay
            
            // Group Setup Sheet
            if showGroupSetup {
                GroupSetupView { profile in
                    store.groupProfile = profile
                    withAnimation { showGroupSetup = false }
                    Task { await store.generateRecommendation() }
                }
                .transition(.move(edge: .bottom))
                .zIndex(2)
            }
        }
    }
    
    @ViewBuilder
    private var processingOverlay: some View {
        switch store.appState {
        case .decoding(let progress):
            ProcessingView(status: "Reading Menu...", progress: progress)
        case .reasoning(let stage):
            ProcessingView(status: stage, progress: 0.5)
        case .verifying:
            ProcessingView(status: "Safety Checks...", progress: 0.8)
        case .error(let message):
            ErrorView(message: message) {
                store.resetSession()
            }
        default:
            EmptyView()
        }
    }
}

// MARK: - Result Root View

struct ResultRootView: View {
    let recommendation: MenuRecommendation
    let store: AppStore
    
    var body: some View {
        ChefCardView(recommendation: recommendation) {
            store.resetSession()
        }
    }
}

// MARK: - Combo Root View

struct ComboRootView: View {
    let combo: ComboRecommendation
    let store: AppStore
    
    var body: some View {
        ComboResultView(combo: combo) { keyword in
            var profile = store.groupProfile
            profile.refinementKeywords.append(keyword)
            store.groupProfile = profile
            Task { await store.generateRecommendation() }
        }
    }
}
