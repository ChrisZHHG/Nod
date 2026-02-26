import SwiftUI

// MARK: - Bento Grid System

/// A flexible grid container that creates asymmetric "Bento Box" layouts
struct BentoGrid<Content: View>: View {
    let columns: Int
    let spacing: CGFloat
    @ViewBuilder let content: () -> Content
    
    init(
        columns: Int = 2,
        spacing: CGFloat = AmbrosiaTheme.Bento.spacing,
        @ViewBuilder content: @escaping () -> Content
    ) {
        self.columns = columns
        self.spacing = spacing
        self.content = content
    }
    
    var body: some View {
        let gridColumns = Array(
            repeating: GridItem(.flexible(), spacing: spacing),
            count: columns
        )
        
        LazyVGrid(columns: gridColumns, spacing: spacing) {
            content()
        }
    }
}

// MARK: - Bento Tile Types

enum BentoTileSize {
    case small      // 1x1
    case medium     // 2x1 (spans 2 columns)
    case tall       // 1x2 (taller than small)
    case large      // 2x2
    
    var gridSpan: Int {
        switch self {
        case .small, .tall: return 1
        case .medium, .large: return 2
        }
    }
    
    var minHeight: CGFloat {
        switch self {
        case .small: return AmbrosiaTheme.Bento.tileMinHeight
        case .medium: return AmbrosiaTheme.Bento.tileMinHeight
        case .tall: return AmbrosiaTheme.Bento.tileLargeHeight * 1.5
        case .large: return AmbrosiaTheme.Bento.tileLargeHeight
        }
    }
}

// MARK: - Bento Tile

/// A single tile in the Bento Grid
struct AmbrosiaBentoTile<Content: View>: View {
    let size: BentoTileSize
    let action: (() -> Void)?
    @ViewBuilder let content: () -> Content
    
    @State private var isPressed = false
    
    init(
        size: BentoTileSize = .small,
        action: (() -> Void)? = nil,
        @ViewBuilder content: @escaping () -> Content
    ) {
        self.size = size
        self.action = action
        self.content = content
    }
    
    var body: some View {
        Group {
            if let action = action {
                Button(action: {
                    HapticFeedback.light.trigger()
                    action()
                }) {
                    tileContent
                }
                .buttonStyle(AmbrosiaBentoTileButtonStyle())
            } else {
                tileContent
            }
        }
    }
    
    private var tileContent: some View {
        content()
            .frame(maxWidth: .infinity, minHeight: size.minHeight)
            .glassCard()
    }
}

// MARK: - Bento Tile Button Style

struct AmbrosiaBentoTileButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.96 : 1.0)
            .opacity(configuration.isPressed ? 0.9 : 1.0)
            .animation(AmbrosiaTheme.Animation.microInteraction, value: configuration.isPressed)
    }
}

// MARK: - Pre-built Tile Variants

/// Hero tile with icon, title, and subtitle (for main actions)
struct BentoHeroTile: View {
    let title: String
    let subtitle: String
    let icon: String
    let iconColor: Color
    let size: BentoTileSize
    let action: () -> Void
    
    @State private var animateIcon = false
    
    var body: some View {
        AmbrosiaBentoTile(size: size, action: action) {
            VStack(alignment: .leading, spacing: AmbrosiaTheme.Spacing.md) {
                // High contrast, clean icon with no pastel blobs
                ZStack {
                    Circle()
                        .fill(Color.white.opacity(0.4))
                        .frame(width: 52, height: 52)
                        .shadow(color: Color.black.opacity(0.05), radius: 4, x: 0, y: 2)
                    
                    Image(systemName: icon)
                        .font(.system(size: 24, weight: .semibold))
                        .foregroundStyle(iconColor)
                        .symbolEffect(.pulse.byLayer, options: .repeating, value: animateIcon)
                }
                
                Spacer()
                
                VStack(alignment: .leading, spacing: AmbrosiaTheme.Spacing.xs) {
                    Text(title)
                        .font(AmbrosiaTheme.Typography.headline)
                        .foregroundStyle(AmbrosiaTheme.Colors.textPrimary)
                    
                    Text(subtitle)
                        .font(AmbrosiaTheme.Typography.caption)
                        .foregroundStyle(AmbrosiaTheme.Colors.textSecondary)
                        .lineLimit(2)
                }
            }
            .padding(AmbrosiaTheme.Spacing.xl)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .onAppear {
            animateIcon = true
        }
    }
}

/// Stats tile for displaying numbers (like "4 dishes scanned")
struct BentoStatTile: View {
    let value: String
    let label: String
    let icon: String
    let color: Color
    
    var body: some View {
        AmbrosiaBentoTile(size: .small) {
            VStack(alignment: .leading, spacing: AmbrosiaTheme.Spacing.sm) {
                Image(systemName: icon)
                    .font(.system(size: 20, weight: .medium))
                    .foregroundStyle(color)
                
                Spacer()
                
                Text(value)
                    .font(AmbrosiaTheme.Typography.bentoNumber)
                    .foregroundStyle(AmbrosiaTheme.Colors.textPrimary)
                
                Text(label)
                    .font(AmbrosiaTheme.Typography.caption)
                    .foregroundStyle(AmbrosiaTheme.Colors.textSecondary)
            }
            .padding(AmbrosiaTheme.Spacing.xl)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }
}

/// Info tile with gradient accent
struct BentoInfoTile: View {
    let title: String
    let description: String
    let gradient: LinearGradient
    
    var body: some View {
        AmbrosiaBentoTile(size: .medium) {
            HStack(spacing: AmbrosiaTheme.Spacing.lg) {
                // Gradient Accent Bar
                RoundedRectangle(cornerRadius: 4)
                    .fill(gradient)
                    .frame(width: 4)
                
                VStack(alignment: .leading, spacing: AmbrosiaTheme.Spacing.xs) {
                    Text(title)
                        .font(AmbrosiaTheme.Typography.headline)
                        .foregroundStyle(AmbrosiaTheme.Colors.textPrimary)
                    
                    Text(description)
                        .font(AmbrosiaTheme.Typography.subheadline)
                        .foregroundStyle(AmbrosiaTheme.Colors.textSecondary)
                        .lineLimit(2)
                }
                
                Spacer()
            }
            .padding(AmbrosiaTheme.Spacing.xl)
        }
    }
}

// MARK: - Scroll Transition Effects

extension View {
    /// Applies parallax blur and scale effect on scroll
    @available(iOS 17.0, *)
    func bentoScrollTransition() -> some View {
        self.scrollTransition(.animated(.smooth)) { content, phase in
            content
                .scaleEffect(phase.isIdentity ? 1 : 0.95)
                .opacity(phase.isIdentity ? 1 : 0.8)
                .blur(radius: phase.isIdentity ? 0 : 2)
        }
    }
}
