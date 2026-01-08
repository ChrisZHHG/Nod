import SwiftUI

// MARK: - Mode Selection View (Bento Grid Layout)

struct ModeSelectionView: View {
    @EnvironmentObject var manager: AmbrosiaManager
    @State private var animateIcons = false
    
    var body: some View {
        ZStack {
            // Immersive Background with MeshGradient
            ImmersiveBackground()
            
            ScrollView(.vertical, showsIndicators: false) {
                VStack(spacing: 0) {
                    // Header Section
                    headerSection
                        .padding(.top, 80)
                        .padding(.bottom, AmbrosiaTheme.Spacing.xxl)
                    
                    // Bento Grid Layout
                    bentoGridSection
                        .padding(.horizontal, AmbrosiaTheme.Spacing.lg)
                    
                    // Footer
                    footerSection
                        .padding(.top, AmbrosiaTheme.Spacing.xxxl)
                        .padding(.bottom, 40)
                }
            }
        }
        .onAppear {
            animateIcons = true
        }
    }
    
    // MARK: - Header Section
    
    // MARK: - Header Section
    
    private var headerSection: some View {
        VStack(spacing: AmbrosiaTheme.Spacing.md) {
            // App Icon with Glow
            ZStack {
                Circle()
                    .fill(AmbrosiaTheme.Gradients.primary.opacity(0.2))
                    .frame(width: 80, height: 80)
                    .blur(radius: 20)
                
                Image(systemName: "fork.knife.circle.fill")
                    .font(.system(size: 56))
                    .foregroundStyle(AmbrosiaTheme.Gradients.primary)
                    .shadow(color: AmbrosiaTheme.Colors.accent.opacity(0.3), radius: 8, x: 0, y: 4)
            }
            
            Text("Ambrosia")
                .font(AmbrosiaTheme.Typography.displayLarge)
                .foregroundStyle(AmbrosiaTheme.Colors.textPrimary)
                // Removed harsh shadow for cleaner look
            
            Text("How are we dining today?")
                .font(AmbrosiaTheme.Typography.title)
                .foregroundStyle(AmbrosiaTheme.Colors.textSecondary)
        }
    }
    
    // MARK: - Bento Grid Section
    
    private var bentoGridSection: some View {
        BentoGrid(columns: 2, spacing: AmbrosiaTheme.Bento.spacing) {
            // Individual Mode Tile (Left column, tall)
            BentoHeroTile(
                title: "For Myself",
                subtitle: "Personal picks for your taste",
                icon: "person.fill",
                iconColor: AmbrosiaTheme.Colors.warmOrange,
                size: .tall
            ) {
                manager.setMode(.individual)
                manager.startSession()
            }
            .applyScrollTransition()
            
            // Group Mode Tile (Right column, tall)
            BentoHeroTile(
                title: "Sharing",
                subtitle: "Dishes everyone will love",
                icon: "person.3.fill",
                iconColor: AmbrosiaTheme.Colors.coralEnd,
                size: .tall
            ) {
                manager.setMode(.group)
                manager.startSession()
            }
            .applyScrollTransition()
            
            // Info Tile (Spans both columns)
            BentoInfoTile(
                title: "AI-Powered Recommendations",
                description: "Scan any menu and get instant, personalized dish suggestions",
                gradient: AmbrosiaTheme.Gradients.coralSunset
            )
            .applyScrollTransition()
        }
    }
    
    // MARK: - Footer Section
    
    private var footerSection: some View {
        HStack(spacing: AmbrosiaTheme.Spacing.sm) {
            Image(systemName: "sparkles")
                .font(.system(size: 12))
                .foregroundStyle(AmbrosiaTheme.Colors.textTertiary)
            
            Text("Powered by Gemini AI")
                .font(AmbrosiaTheme.Typography.caption)
                .foregroundStyle(AmbrosiaTheme.Colors.textTertiary)
        }
    }
}

// MARK: - Scroll Transition Extension

private extension View {
    @ViewBuilder
    func applyScrollTransition() -> some View {
        if #available(iOS 17.0, *) {
            self.scrollTransition(.animated(.smooth)) { content, phase in
                content
                    .scaleEffect(phase.isIdentity ? 1 : 0.95)
                    .opacity(phase.isIdentity ? 1 : 0.7)
                    .blur(radius: phase.isIdentity ? 0 : 2)
            }
        } else {
            self
        }
    }
}

// MARK: - Legacy ImmersiveModeCard (Preserved for reference)
// Removed - now using BentoHeroTile

