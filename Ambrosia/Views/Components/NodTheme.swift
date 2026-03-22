import SwiftUI

// MARK: - Nod Design System (Modern Minimal / 2025)

struct NodTheme {
    
    // MARK: - Spacing Tokens
    struct Spacing {
        static let xs: CGFloat = 4
        static let sm: CGFloat = 8
        static let md: CGFloat = 12
        static let lg: CGFloat = 16
        static let xl: CGFloat = 24
        static let xxl: CGFloat = 32
        static let xxxl: CGFloat = 48
    }
    
    // MARK: - Awwwards Style (Radical Minimalism / 2026)
    struct Awwwards {
        // Colors
        static let paperWhite = Color(hex: "F4F4F0") // Premium textured paper
        static let inkBlack = Color(hex: "1A1A1A")   // Charcoal Off-Black
        static let subtleGrain = Color(hex: "E5E5E0") // Muted gray for lines
        
        // Typography
        static let editorialDisplay: Font = .system(size: 80, weight: .light, design: .serif)
        static let editorialTitle: Font = .system(size: 24, weight: .regular, design: .serif)
        static let monoDetail: Font = .system(size: 10, weight: .light, design: .monospaced)
        static let monoSubtitle: Font = .system(size: 12, weight: .light, design: .monospaced)
    }
    
    // MARK: - Cinematic Style (Netflix / Chef's Table / 2026)
    struct Cinematic {
        // Base Canvas
        static let deepBlack   = Color(hex: "101010") // True near-black
        static let richBrown   = Color(hex: "1A1209") // Warm chocolate shadow
        static let smokeGray   = Color(hex: "A3A3A3") // Secondary text
        static let pureWhite   = Color.white
        
        // Accent (saffron amber CTA)
        static let amber       = Color(hex: "E8930A") // Appetizing saffron
        static let amberDim    = Color(hex: "E8930A").opacity(0.15)
        
        // Glass Surfaces
        static let glassDark   = Color.black.opacity(0.55)
        static let glassBorder = Color.white.opacity(0.12)
        
        // Overlay gradients
        static let heroOverlay = LinearGradient(
            stops: [
                .init(color: .black.opacity(0.05), location: 0.0),
                .init(color: .black.opacity(0.50), location: 0.50),
                .init(color: Color(hex:"101010"),  location: 1.0)
            ],
            startPoint: .top, endPoint: .bottom
        )
        
        static let cardOverlay = LinearGradient(
            colors: [.clear, .black.opacity(0.85)],
            startPoint: .top, endPoint: .bottom
        )
        
        // Typography (bold-vs-light contrast system)
        static let displayHero:  Font = .system(size: 52, weight: .black, design: .default)
        // Typography (condensed bold contrast system — Netflix/Chef's Table inspired)
        // displayHero is built dynamically via condensedBlack() for true condensed letterforms
        static let sectionTitle: Font = .system(size: 13, weight: .semibold, design: .default)
        static let itemTitle:    Font = .system(size: 20, weight: .bold,   design: .default)
        static let body:         Font = .system(size: 14, weight: .regular, design: .default)
        static let caption:      Font = .system(size: 11, weight: .regular, design: .default)
        static let cta:          Font = .system(size: 16, weight: .bold,   design: .default)
    }
    
    // MARK: - Colors (Modern Minimal Palette)
    struct Colors {
        // Primary Accent (Premium Indigo)
        static let accent = Color(hex: "4F46E5")          // Linear Indigo
        static let accentLight = Color(hex: "6366F1")     // Soft Indigo
        static let accentSoft = Color(hex: "818CF8")      // Light Indigo
        
        // Legacy aliases
        static let coralStart = accent
        static let coralEnd = accentSoft
        static let warmOrange = Color(hex: "F59E0B")      // Amber
        static let sunsetPink = Color(hex: "E11D48")      // Rose
        
        // Surfaces (Ultra Clean)
        static let surface = Color(hex: "FFFFFF")         // Pure white
        static let surfaceElevated = Color(hex: "FFFFFF") // White (for clouds)
        static let surfaceSecondary = Color(hex: "F3F4F6") // Cool Gray 100
        
        // Legacy background aliases
        static let pureBlack = Color(hex: "000000")
        static let richBlack = Color(hex: "111827")       // Cool gray 900
        static let softWhite = Color(hex: "F9FAFB")
        
        // Text (High Contrast)
        static let textPrimary = Color(hex: "111827")     // Gray 900
        static let textSecondary = Color(hex: "6B7280")   // Gray 500
        static let textTertiary = Color(hex: "9CA3AF")    // Gray 400
        static let textDark = Color(hex: "111827")
        static let textOnAccent = Color.white
        
        // Glass Effects
        static let glassBorder = Color.white.opacity(0.4)
        static let glassHighlight = Color.white.opacity(0.8)
        static let glassShadow = Color.black.opacity(0.08)
    }
    
    // MARK: - Gradients (Refined)
    struct Gradients {
        // Primary Action (Indigo gradient)
        static let primary = LinearGradient(
            colors: [Colors.accent, Colors.accentLight],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
        
        // Legacy alias
        static let coralSunset = primary
        
        // Subtle warm gradient
        static let warmGlow = LinearGradient(
            colors: [Colors.warmOrange, Colors.sunsetPink],
            startPoint: .leading,
            endPoint: .trailing
        )
        
        // Clean background gradient
        static let softBackground = LinearGradient(
            colors: [
                Color(hex: "F9FAFB"), // Gray 50
                Color(hex: "EFF6FF")  // Blue 50
            ],
            startPoint: .top,
            endPoint: .bottom
        )
        
        // Legacy aliases
        static let goldenHour = warmGlow
        static let immersiveMesh = softBackground
    }
    
    // MARK: - Typography (SF Pro Rounded + Dynamic Type)
    struct Typography {
        // Large fixed sizes with Dynamic Type scaling
        static let displayLarge: Font = .system(size: 40, weight: .bold, design: .rounded)
        
        // System text styles (automatically support Dynamic Type)
        static let display: Font = .system(.largeTitle, design: .rounded).weight(.bold)
        static let header: Font = .system(.title2, design: .rounded).weight(.semibold)
        static let title: Font = .system(.title3, design: .rounded).weight(.semibold)
        static let headline: Font = .system(.headline, design: .rounded).weight(.semibold)
        static let body: Font = .system(.body, design: .rounded)
        static let subheadline: Font = .system(.subheadline, design: .rounded)
        static let caption: Font = .system(.caption, design: .rounded).weight(.medium)
        static let button: Font = .system(.callout, design: .rounded).weight(.semibold)
        
        // Large display numbers (for Bento tiles)
        static let bentoNumber: Font = .system(size: 48, weight: .bold, design: .rounded)
        
        // Accessibility-aware label font (scales with user settings)
        static func accessibleFont(size: CGFloat, weight: Font.Weight = .regular) -> Font {
            .system(size: size, weight: weight, design: .rounded)
        }
    }
    
    // MARK: - Corner Radii
    struct Radius {
        static let sm: CGFloat = 8
        static let md: CGFloat = 12
        static let lg: CGFloat = 16
        static let xl: CGFloat = 20
        static let xxl: CGFloat = 24 // Slightly tighter
        static let pill: CGFloat = 100
    }
    
    // MARK: - Shadows (Floating Effect)
    struct Shadows {
        static let glowColor = Colors.accent.opacity(0.3)
        static let glowRadius: CGFloat = 15
        static let cardShadowColor = Color.black.opacity(0.08)
        static let cardShadowRadius: CGFloat = 12
        static let cardShadowY: CGFloat = 6
    }
    
    // MARK: - Bento Grid
    struct Bento {
        static let spacing: CGFloat = 16
        static let tileMinHeight: CGFloat = 120
        static let tileLargeHeight: CGFloat = 160
    }
    
    // MARK: - Semantic Colors (Purpose-Based)
    struct SemanticColors {
        // Primary Actions
        static let primary = Colors.accent
        static let accent = Colors.warmOrange
        
        // Backgrounds
        static let backgroundPrimary = Colors.softWhite
        static let backgroundSecondary = Colors.surfaceSecondary
        static let surface = Color.white.opacity(0.6)
        static let surfaceElevated = Color.white.opacity(0.8)
        
        // Interactive States
        static let interactive = Colors.accent
        static let interactiveHover = Colors.accent.opacity(0.8)
        static let interactivePressed = Colors.accent.opacity(0.6)
        static let interactiveDisabled = Colors.textTertiary
        
        // Feedback
        static let success = Color(hex: "10B981") // Emerald
        static let warning = Color(hex: "F59E0B") // Amber
        static let error = Color(hex: "EF4444")   // Red
        static let info = Color(hex: "3B82F6")    // Blue
    }
    
    // MARK: - Animation Constants
    struct Animation {
        static let microInteraction: SwiftUI.Animation = .spring(response: 0.3, dampingFraction: 0.7)
        static let standard: SwiftUI.Animation = .easeInOut(duration: 0.25)
        static let slow: SwiftUI.Animation = .easeInOut(duration: 0.5)
        static let springy: SwiftUI.Animation = .spring(response: 0.5, dampingFraction: 0.6)
    }
}

// MARK: - Haptic Feedback Manager

enum HapticFeedback: Sendable {
    case light
    case medium
    case heavy
    case selection
    case success
    case warning
    case error
    
    @MainActor
    func trigger() {
        switch self {
        case .light:
            UIImpactFeedbackGenerator(style: .light).impactOccurred()
        case .medium:
            UIImpactFeedbackGenerator(style: .medium).impactOccurred()
        case .heavy:
            UIImpactFeedbackGenerator(style: .heavy).impactOccurred()
        case .selection:
            UISelectionFeedbackGenerator().selectionChanged()
        case .success:
            UINotificationFeedbackGenerator().notificationOccurred(.success)
        case .warning:
            UINotificationFeedbackGenerator().notificationOccurred(.warning)
        case .error:
            UINotificationFeedbackGenerator().notificationOccurred(.error)
        }
    }
}

// MARK: - Dynamic Type Support

extension View {
    /// Applies Dynamic Type scaling to a value
    func scaledValue(_ value: CGFloat, relativeTo textStyle: Font.TextStyle = .body) -> CGFloat {
        // This is a simple scaling approach; for more complex scenarios use @ScaledMetric
        return value
    }
}

// MARK: - Glass Card Modifier

struct GlassCardModifier: ViewModifier {
    var cornerRadius: CGFloat = NodTheme.Radius.xxl
    var addShadow: Bool = true
    
    func body(content: Content) -> some View {
        ZStack {
            // Background Material Layer
            RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                .fill(.ultraThinMaterial)
            
            RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                .fill(Color.white.opacity(0.35)) // Stronger white tint to make cards pop over dark/mesh backgrounds
            
            // Content Layer
            content
        }
        .clipShape(RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                .stroke(Color.white.opacity(0.8), lineWidth: 0.5) // Sharp edge
        )
        .shadow(
            color: addShadow ? Color.black.opacity(0.04) : .clear,
            radius: 4, x: 0, y: 2
        )
        .shadow(
            color: addShadow ? Color.black.opacity(0.08) : .clear,
            radius: 16, x: 0, y: 8
        )
    }
}

extension View {
    func glassCard(cornerRadius: CGFloat = NodTheme.Radius.xxl, shadow: Bool = true) -> some View {
        modifier(GlassCardModifier(cornerRadius: cornerRadius, addShadow: shadow))
    }
    
    // Legacy support
    func ambrosiaGlass(cornerRadius: CGFloat = NodTheme.Radius.xl, shadow: CGFloat = 12) -> some View {
        modifier(GlassCardModifier(cornerRadius: cornerRadius, addShadow: shadow > 0))
    }
}

// MARK: - Cinematic Typography (Netflix/Chef's Table condensed font system)
extension Font {
    /// Condensed black — mimics the heavy half of the "CHEF'S TABLE" title contrast.
    static func cinematicHero(size: CGFloat = 56) -> Font {
        let desc = UIFontDescriptor.preferredFontDescriptor(withTextStyle: .largeTitle)
            .withSymbolicTraits([.traitBold, .traitCondensed]) ?? UIFontDescriptor()
        return Font(UIFont(descriptor: desc, size: size) as CTFont)
    }
    
    /// Condensed regular — the thin complement pair and small labels.
    static func cinematicSubHero(size: CGFloat = 18) -> Font {
        let desc = UIFontDescriptor.preferredFontDescriptor(withTextStyle: .title3)
            .withSymbolicTraits([.traitCondensed]) ?? UIFontDescriptor()
        return Font(UIFont(descriptor: desc, size: size) as CTFont)
    }
}

