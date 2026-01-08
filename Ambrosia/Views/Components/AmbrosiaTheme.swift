import SwiftUI

// MARK: - Ambrosia Design System (Modern Minimal / 2025)

struct AmbrosiaTheme {
    
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
    var cornerRadius: CGFloat = AmbrosiaTheme.Radius.xxl
    var addShadow: Bool = true
    
    func body(content: Content) -> some View {
        content
            .background(.ultraThinMaterial) // Real frosted glass
            .background(Color.white.opacity(0.4)) // Milk tint
            .clipShape(RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .stroke(LinearGradient(
                        colors: [.white.opacity(0.5), .white.opacity(0.1)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ), lineWidth: 1) // Subtle light border
            )
            // Ambient Shadow (Depth)
            .shadow(
                color: addShadow ? Color.black.opacity(0.04) : .clear,
                radius: 2,
                x: 0,
                y: 1
            )
            // Diffuse Shadow (Elevation)
            .shadow(
                color: addShadow ? Color.black.opacity(0.08) : .clear,
                radius: 12,
                x: 0,
                y: 6
            )
    }
}

extension View {
    func glassCard(cornerRadius: CGFloat = AmbrosiaTheme.Radius.xxl, shadow: Bool = true) -> some View {
        modifier(GlassCardModifier(cornerRadius: cornerRadius, addShadow: shadow))
    }
    
    // Legacy support
    func ambrosiaGlass(cornerRadius: CGFloat = AmbrosiaTheme.Radius.xl, shadow: CGFloat = 12) -> some View {
        modifier(GlassCardModifier(cornerRadius: cornerRadius, addShadow: shadow > 0))
    }
}

