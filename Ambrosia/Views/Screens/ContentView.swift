import SwiftUI
import VisionKit

// MARK: - App Entry Point
// Moved to AmbrosiaApp.swift

// MARK: - Main View (Liquid Glass Style)

struct ContentView: View {
    @EnvironmentObject var manager: AmbrosiaManager
    @State private var showGroupSetup = false // Local state for wizard visibility (Group Mode)

    var body: some View {
        NavigationStack(path: $manager.path) {
            ZStack {
                // Background
                LiquidBackground()
                
                // Root View
                ModeSelectionView()
            }
            .navigationDestination(for: AmbrosiaManager.Destination.self) { destination in
                switch destination {
                case .scanner:
                    ScannerContainer(showGroupSetup: $showGroupSetup)
                        .environmentObject(manager) // Explicit injection for safety
                        .navigationBarBackButtonHidden(true)
                case .result(let recommendation):
                    ChefCardView(recommendation: recommendation) {
                        manager.resetSession()
                    }
                    .navigationBarBackButtonHidden(true)
                case .combo(let combo):
                    ComboResultView(combo: combo) { keyword in
                        // Refinement logic remains same
                        var updatedProfile = manager.groupProfile
                        updatedProfile.refinementKeywords.append(keyword)
                        manager.groupProfile = updatedProfile
                        Task { await manager.generateRecommendation() }
                    }
                    .navigationBarBackButtonHidden(true)
                }
            }
        }
        .animation(.spring(response: 0.6, dampingFraction: 0.7), value: manager.state) // Keep silky transitions for overlays
        .environmentObject(manager)
    }
}

// Wrapper to handle Overlays (Processing, Error, Wizard) on top of Camera
struct ScannerContainer: View {
    @EnvironmentObject var manager: AmbrosiaManager
    @Binding var showGroupSetup: Bool
    
    // Extract images from manager directly
    var currentImages: [Data] {
        return manager.currentImages
    }
    
    var body: some View {
        ZStack {
            // Base: Scanner
            ScannerView(
                images: currentImages,
                onCapture: { image in manager.addImage(image) },
                onAnalyze: {
                    if manager.appMode == .group {
                        withAnimation { showGroupSetup = true }
                    } else {
                        Task { await manager.generateRecommendation() }
                    }
                },
                onCancel: {
                    manager.resetSession()
                }
            )
            .allowsHitTesting(!showGroupSetup) // Prevent interaction with scanner when wizard is open
            
            // Overlays driven by State
            switch manager.state {
            case .decoding(let progress):
                ProcessingView(status: "Reading Menu...", progress: progress)
            case .reasoning(let stage):
                ProcessingView(status: stage, progress: 0.5)
            case .verifying:
                ProcessingView(status: "Safety Checks...", progress: 0.8)
            case .error(let message):
                ErrorView(message: message) {
                    manager.startSession() // Retry (resets to scanning)
                }
            default:
                EmptyView()
            }
            
            // Group Wizard Overlay
            if showGroupSetup {
                GroupSetupView { profile in
                    manager.groupProfile = profile
                    withAnimation { showGroupSetup = false }
                    Task { await manager.generateRecommendation() }
                }
                .transition(.move(edge: .bottom).combined(with: .opacity))
                .zIndex(2)
            }
        }
    }
}

// MARK: - Subviews

struct WelcomeView: View {
    @EnvironmentObject var manager: AmbrosiaManager
    @State private var showSettings = false
    
    var body: some View {
        VStack(spacing: 30) {
            ZStack {
                Circle()
                    .fill(AmbrosiaTheme.Gradients.coralSunset)
                    .frame(width: 120, height: 120)
                    .blur(radius: 20)
                    .opacity(0.4)
                
                Image(systemName: "fork.knife.circle.fill")
                    .font(.system(size: 100))
                    .foregroundStyle(AmbrosiaTheme.Gradients.coralSunset)
                    .shadow(color: AmbrosiaTheme.Shadows.glowColor, radius: 15, x: 0, y: 5)
            }
            .onTapGesture {
                manager.startSession()
            }
            
            VStack(spacing: 12) {
                Text("Ambrosia")
                    .font(AmbrosiaTheme.Typography.display)
                    .foregroundStyle(AmbrosiaTheme.Colors.textPrimary)
                
                Text("Digital Sommelier for your Food")
                    .font(AmbrosiaTheme.Typography.body)
                    .foregroundStyle(AmbrosiaTheme.Colors.textSecondary)
            }
            
            Spacer() // Push button to bottom
            
            GlassButton(title: "Scan Menu", icon: "camera.fill", variant: .primary) {
                manager.startSession()
            }
            .padding(.horizontal, 40)
            .padding(.bottom, AmbrosiaTheme.Spacing.xxl) // Add bottom padding
            
            // Settings Button
            Button {
                showSettings = true
            } label: {
                Image(systemName: "gearshape.fill")
                    .font(.system(size: 20))
                    .foregroundStyle(AmbrosiaTheme.Colors.textTertiary)
                    .padding()
            }
        }
        .sheet(isPresented: $showSettings) {
             SettingsView()
                 .presentationDetents([.medium])
        }
    }
}

struct ScannerView: View {
    let images: [Data]
    let onCapture: (Data) -> Void
    let onAnalyze: () -> Void
    let onCancel: () -> Void
    
    @State private var isCapturing = false
    @State private var scannedData: Data? = nil
    
    var body: some View {
        ZStack(alignment: .bottom) {
            // Layer 1: Camera (Full Screen)
            if DataScannerViewController.isSupported && DataScannerViewController.isAvailable {
                CameraScannerView(scannedImage: $scannedData, shouldCaptureTrigger: isCapturing)
                    .ignoresSafeArea()
                    .overlay(
                        Color.white.opacity(isCapturing ? 0.3 : 0)
                            .animation(.easeOut(duration: 0.2), value: isCapturing)
                    )
                    .onChange(of: scannedData) { _, newData in
                        if let data = newData {
                            onCapture(data)
                            isCapturing = false 
                            scannedData = nil
                        }
                    }
            } else {
                // Fallback for devices without camera
                ZStack {
                    ImmersiveBackground()
                    VStack(spacing: AmbrosiaTheme.Spacing.lg) {
                        Image(systemName: "camera.slash")
                            .font(.system(size: 48))
                            .foregroundStyle(AmbrosiaTheme.Colors.textTertiary)
                        Text("Camera Not Available")
                            .font(AmbrosiaTheme.Typography.headline)
                            .foregroundStyle(AmbrosiaTheme.Colors.textSecondary)
                    }
                    .padding(AmbrosiaTheme.Spacing.xxl)
                    .glassCard()
                }
            }
            
            // Top Navigation Bar (Custom)
            VStack {
                HStack {
                    Button {
                        onCancel()
                    } label: {
                        Image(systemName: "chevron.left")
                            .font(.system(size: 18, weight: .bold))
                            .foregroundStyle(AmbrosiaTheme.Colors.textPrimary)
                            .frame(width: 44, height: 44)
                            .background(.ultraThinMaterial)
                            .clipShape(Circle())
                            .overlay(
                                Circle()
                                    .stroke(AmbrosiaTheme.Colors.glassBorder, lineWidth: 1)
                            )
                            .shadow(color: AmbrosiaTheme.Shadows.cardShadowColor, radius: 4, x: 0, y: 2)
                    }
                    Spacer()
                }
                .padding(.horizontal, AmbrosiaTheme.Spacing.lg)
                .padding(.top, 60) // Safe Area buffer
                Spacer()
            }
            
            // Bottom Control Bar
            ZStack(alignment: .bottom) {
                // Side Controls (Left/Right)
                HStack {
                    // Page Counter Pill (Left)
                    if !images.isEmpty {
                        HStack(spacing: AmbrosiaTheme.Spacing.sm) {
                            Text("\(images.count)")
                                .font(AmbrosiaTheme.Typography.title)
                                .foregroundStyle(AmbrosiaTheme.Colors.textPrimary)
                            Text("Pages")
                                .font(AmbrosiaTheme.Typography.caption)
                                .foregroundStyle(AmbrosiaTheme.Colors.textSecondary)
                        }
                        .padding(.horizontal, AmbrosiaTheme.Spacing.lg)
                        .padding(.vertical, AmbrosiaTheme.Spacing.md)
                        .background(.ultraThinMaterial)
                        .clipShape(Capsule())
                        .overlay(
                            Capsule()
                                .stroke(AmbrosiaTheme.Colors.glassBorder, lineWidth: 0.5)
                        )
                    }
                    
                    Spacer()
                    
                    // Analyze Button (Right)
                    if !images.isEmpty {
                        Button {
                            onAnalyze()
                        } label: {
                            HStack(spacing: AmbrosiaTheme.Spacing.sm) {
                                Image(systemName: "sparkles")
                                    .font(.system(size: 16, weight: .semibold))
                                    .foregroundStyle(.white)
                                Text("Analyze")
                                    .font(AmbrosiaTheme.Typography.button)
                                    .foregroundStyle(.white)
                            }
                            .padding(.horizontal, AmbrosiaTheme.Spacing.xl)
                            .padding(.vertical, AmbrosiaTheme.Spacing.md)
                            .background(AmbrosiaTheme.Gradients.primary)
                            .clipShape(Capsule())
                            .shadow(color: AmbrosiaTheme.Shadows.glowColor, radius: 10, x: 0, y: 4)
                        }
                    }
                }
                .padding(.horizontal, AmbrosiaTheme.Spacing.xl)
                .padding(.bottom, 60) // Align with capture button center
                
                // Capture Button (Excatly Center Bottom)
                Button {
                    isCapturing = true
                } label: {
                    ZStack {
                        Circle()
                            .fill(.white)
                            .frame(width: 72, height: 72)
                            .shadow(color: .black.opacity(0.15), radius: 8, x: 0, y: 4)
                        Circle()
                            .stroke(AmbrosiaTheme.Colors.glassBorder, lineWidth: 4)
                            .frame(width: 82, height: 82)
                    }
                }
                .disabled(isCapturing)
                .scaleEffect(isCapturing ? 0.9 : 1.0)
                .animation(.spring(response: 0.3), value: isCapturing)
                .padding(.bottom, 50)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottom)
            .ignoresSafeArea(.keyboard, edges: .bottom)
        }
    }
}


struct ChefCardView: View {
    let recommendation: MenuRecommendation
    let onReset: () -> Void
    
    var body: some View {
        ZStack {
            // Background
            ImmersiveBackground()
            
            // Main Content
            ScrollView {
                VStack(spacing: 0) {
                    // Top spacing for back button
                    Spacer().frame(height: 80)
                    
                    // Image Header (Full Bleed)
                    if let url = recommendation.imageURL {
                        AsyncImage(url: url) { image in
                            image.resizable()
                                .aspectRatio(contentMode: .fill)
                                .frame(height: 280)
                                .clipped()
                        } placeholder: {
                            Rectangle()
                                .fill(AmbrosiaTheme.Colors.surfaceSecondary)
                                .overlay(
                                    Image(systemName: "photo")
                                        .font(.system(size: 40))
                                        .foregroundStyle(AmbrosiaTheme.Colors.textTertiary)
                                )
                                .frame(height: 280)
                        }
                        .clipShape(RoundedRectangle(cornerRadius: AmbrosiaTheme.Radius.xl, style: .continuous))
                        .padding(.horizontal, AmbrosiaTheme.Spacing.lg)
                    }
                    
                    // Content Body
                    VStack(spacing: AmbrosiaTheme.Spacing.xl) {
                        // Badge
                        HStack {
                            Spacer()
                            Text("Chef's Choice")
                                .font(AmbrosiaTheme.Typography.caption)
                                .fontWeight(.bold)
                                .tracking(1.5)
                                .textCase(.uppercase)
                                .foregroundStyle(AmbrosiaTheme.Colors.warmOrange)
                                .padding(.vertical, AmbrosiaTheme.Spacing.sm)
                                .padding(.horizontal, AmbrosiaTheme.Spacing.md)
                                .background(AmbrosiaTheme.Colors.warmOrange.opacity(0.15))
                                .clipShape(Capsule())
                            Spacer()
                        }
                        .padding(.top, AmbrosiaTheme.Spacing.xl)
                        
                        // Titles
                        VStack(spacing: AmbrosiaTheme.Spacing.sm) {
                            Text(recommendation.translation.localizedName)
                                .font(AmbrosiaTheme.Typography.display)
                                .foregroundStyle(AmbrosiaTheme.Colors.textPrimary)
                                .multilineTextAlignment(.center)
                            
                            Text(recommendation.recommendedItem.originalName)
                                .font(AmbrosiaTheme.Typography.subheadline.italic())
                                .foregroundStyle(AmbrosiaTheme.Colors.textSecondary)
                        }
                        
                        Divider()
                            .background(AmbrosiaTheme.Colors.glassBorder)
                        
                        // Description
                        Text(recommendation.translation.culturalContext)
                            .font(AmbrosiaTheme.Typography.body)
                            .foregroundStyle(AmbrosiaTheme.Colors.textSecondary)
                            .lineSpacing(5)
                            .multilineTextAlignment(.leading)
                            .padding(.horizontal, AmbrosiaTheme.Spacing.sm)
                        
                        // Warnings
                        if !recommendation.translation.warnings.isEmpty {
                            HStack(spacing: AmbrosiaTheme.Spacing.sm) {
                                ForEach(recommendation.translation.warnings, id: \.self) { warn in
                                    Text(warn)
                                        .font(AmbrosiaTheme.Typography.caption)
                                        .padding(AmbrosiaTheme.Spacing.sm)
                                        .background(Color.red.opacity(0.2))
                                        .foregroundColor(.red)
                                        .clipShape(Capsule())
                                }
                            }
                        }
                        
                        Spacer(minLength: AmbrosiaTheme.Spacing.lg)
                        
                        GlassButton(title: "Another Course?", icon: "arrow.counterclockwise", variant: .secondary) {
                            onReset()
                        }
                    }
                    .padding(AmbrosiaTheme.Spacing.xl)
                    .glassCard()
                    .padding(.horizontal, AmbrosiaTheme.Spacing.lg)
                    .padding(.top, AmbrosiaTheme.Spacing.lg)
                }
            }
            
            // Floating Back Button
            FloatingBackButton {
                onReset()
            }
        }
    }
}

struct ErrorView: View {
    let message: String
    let onRetry: () -> Void
    
    var body: some View {
        VStack(spacing: AmbrosiaTheme.Spacing.lg) {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.system(size: 48))
                .foregroundStyle(AmbrosiaTheme.Colors.coralStart)
            
            Text("Something went wrong")
                .font(AmbrosiaTheme.Typography.header)
                .foregroundStyle(AmbrosiaTheme.Colors.textPrimary)
            
            Text(message)
                .font(AmbrosiaTheme.Typography.body)
                .foregroundStyle(AmbrosiaTheme.Colors.textSecondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, AmbrosiaTheme.Spacing.lg)
            
            GlassButton(title: "Try Again", icon: "arrow.clockwise", variant: .primary) {
                onRetry()
            }
            .padding(.top, AmbrosiaTheme.Spacing.sm)
        }
        .padding(AmbrosiaTheme.Spacing.xxl)
        .glassCard()
    }
}

// MARK: - Legacy Cleanup
// Removed GlassButtonStyle and glassCard extension in favor of AmbrosiaTheme and Components.

