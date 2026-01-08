import SwiftUI

// MARK: - Processing View (Enhanced with SF Symbols & Skeleton)

struct ProcessingView: View {
    let status: String
    let progress: Double
    
    @State private var animateIcons = false
    @State private var shimmerOffset: CGFloat = -200
    
    // Determine icon based on status
    private var currentIcon: String {
        if status.contains("Menu") || status.contains("Scan") {
            return "doc.text.viewfinder"
        } else if status.contains("Personal") || status.contains("Assemb") {
            return "sparkles"
        } else if status.contains("Safety") {
            return "checkmark.shield"
        } else {
            return "wand.and.stars"
        }
    }
    
    var body: some View {
        VStack(spacing: AmbrosiaTheme.Spacing.xl) {
            // Animated SF Symbol Icon
            ZStack {
                // Glow Background
                Circle()
                    .fill(AmbrosiaTheme.Gradients.coralSunset)
                    .frame(width: 100, height: 100)
                    .blur(radius: 30)
                    .opacity(0.5)
                
                // Icon with Animation
                Image(systemName: currentIcon)
                    .font(.system(size: 48, weight: .medium))
                    .foregroundStyle(AmbrosiaTheme.Gradients.coralSunset)
                    .symbolEffect(.variableColor.iterative, options: .repeating, value: animateIcons)
                    .contentTransition(.symbolEffect(.replace))
            }
            .frame(height: 120)
            
            // Status Text
            Text(status)
                .font(AmbrosiaTheme.Typography.headline)
                .foregroundStyle(AmbrosiaTheme.Colors.textPrimary)
                .multilineTextAlignment(.center)
                .contentTransition(.numericText())
                .animation(.smooth, value: status)
            
            // Skeleton Bento Grid Preview
            SkeletonBentoGrid()
                .frame(height: 100)
            
            // Progress bar with gradient
            if progress > 0 {
                GeometryReader { geo in
                    ZStack(alignment: .leading) {
                        Capsule()
                            .fill(AmbrosiaTheme.Colors.surfaceSecondary) // Gray background for visibility
                            .frame(height: 6)
                        
                        Capsule()
                            .fill(AmbrosiaTheme.Gradients.primary) // Blue gradient
                            .frame(width: geo.size.width * progress, height: 6)
                            .animation(.easeInOut, value: progress)
                    }
                }
                .frame(width: 200, height: 6)
            }
        }
        .padding(AmbrosiaTheme.Spacing.xxl)
        .glassCard()
        .onAppear {
            animateIcons = true
        }
    }
}

// MARK: - Skeleton Bento Grid

struct SkeletonBentoGrid: View {
    @State private var shimmer = false
    
    var body: some View {
        HStack(spacing: AmbrosiaTheme.Bento.spacing) {
            // Left tile
            SkeletonTile()
            
            // Right column
            VStack(spacing: AmbrosiaTheme.Bento.spacing) {
                SkeletonTile()
                SkeletonTile()
            }
        }
        .onAppear {
            withAnimation(.easeInOut(duration: 1.5).repeatForever(autoreverses: false)) {
                shimmer = true
            }
        }
    }
}

// MARK: - Skeleton Tile with Shimmer

struct SkeletonTile: View {
    @State private var shimmerOffset: CGFloat = -100
    
    var body: some View {
        RoundedRectangle(cornerRadius: AmbrosiaTheme.Radius.lg, style: .continuous)
            .fill(AmbrosiaTheme.Colors.surfaceSecondary) // Gray placeholder
            .overlay(
                // Shimmer Effect (Darker for light mode)
                GeometryReader { geo in
                    RoundedRectangle(cornerRadius: AmbrosiaTheme.Radius.lg, style: .continuous)
                        .fill(
                            LinearGradient(
                                colors: [
                                    .clear,
                                    Color.black.opacity(0.05), // Subtle dark shimmer
                                    Color.black.opacity(0.1),
                                    Color.black.opacity(0.05),
                                    .clear
                                ],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .frame(width: 80)
                        .offset(x: shimmerOffset)
                        .onAppear {
                            withAnimation(.linear(duration: 1.5).repeatForever(autoreverses: false)) {
                                shimmerOffset = geo.size.width + 100
                            }
                        }
                }
                .clipped()
            )
            .clipShape(RoundedRectangle(cornerRadius: AmbrosiaTheme.Radius.lg, style: .continuous))
    }
}

// MARK: - Shimmer View Modifier

struct ShimmerModifier: ViewModifier {
    @State private var phase: CGFloat = 0
    
    func body(content: Content) -> some View {
        content
            .overlay(
                GeometryReader { geo in
                    Rectangle()
                        .fill(
                            LinearGradient(
                                colors: [
                                    .clear,
                                    Color.white.opacity(0.15),
                                    .clear
                                ],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .frame(width: 60)
                        .offset(x: phase * geo.size.width - 60)
                        .onAppear {
                            withAnimation(.linear(duration: 1.2).repeatForever(autoreverses: false)) {
                                phase = 1
                            }
                        }
                }
                .clipped()
            )
    }
}

extension View {
    func shimmer() -> some View {
        modifier(ShimmerModifier())
    }
}
