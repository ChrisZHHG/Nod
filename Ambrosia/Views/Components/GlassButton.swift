import SwiftUI

struct GlassButton: View {
    let title: String
    var icon: String? = nil
    var variant: Variant = .primary
    let action: () -> Void
    
    enum Variant {
        case primary    // Solid accent color
        case secondary  // White background with border
        case ghost      // Minimal, accent text only
    }
    
    var body: some View {
        Button(action: {
            HapticFeedback.light.trigger()
            action()
        }) {
            HStack(spacing: NodTheme.Spacing.sm) {
                if let icon = icon {
                    Image(systemName: icon)
                        .font(.system(size: 18, weight: .semibold))
                        .symbolRenderingMode(.hierarchical)
                }
                Text(title)
                    .font(NodTheme.Typography.button)
            }
            .padding(.vertical, NodTheme.Spacing.lg)
            .padding(.horizontal, NodTheme.Spacing.xl)
            .frame(maxWidth: .infinity)
            .foregroundColor(foregroundColor)
            .background(backgroundView)
            .clipShape(RoundedRectangle(cornerRadius: NodTheme.Radius.xl, style: .continuous))
            .overlay(overlayView)
            .contentShape(Rectangle()) // Ensures entire button area catches taps
            .shadow(
                color: shadowColor,
                radius: shadowRadius,
                x: 0,
                y: shadowY
            )
        }
        .buttonStyle(FloatingButtonStyle())
    }
    
    @ViewBuilder
    private var backgroundView: some View {
        switch variant {
        case .primary:
            NodTheme.Colors.accent
        case .secondary:
            Color.white
        case .ghost:
            Color.clear
        }
    }
    
    @ViewBuilder
    private var overlayView: some View {
        switch variant {
        case .primary:
            EmptyView()
        case .secondary:
            RoundedRectangle(cornerRadius: NodTheme.Radius.xl, style: .continuous)
                .stroke(NodTheme.Colors.glassBorder, lineWidth: 1)
        case .ghost:
            EmptyView()
        }
    }
    
    private var foregroundColor: Color {
        switch variant {
        case .primary:
            return NodTheme.Colors.textOnAccent
        case .secondary:
            return NodTheme.Colors.textPrimary
        case .ghost:
            return NodTheme.Colors.accent
        }
    }
    
    private var shadowColor: Color {
        switch variant {
        case .primary:
            return NodTheme.Colors.accent.opacity(0.3)
        case .secondary:
            return NodTheme.Colors.glassShadow
        case .ghost:
            return .clear
        }
    }
    
    private var shadowRadius: CGFloat {
        switch variant {
        case .primary: return 12
        case .secondary: return 8
        case .ghost: return 0
        }
    }
    
    private var shadowY: CGFloat {
        switch variant {
        case .primary: return 4
        case .secondary: return 4
        case .ghost: return 0
        }
    }
}

// Floating press animation (Crisp Spring)
struct FloatingButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.94 : 1.0)
            .opacity(configuration.isPressed ? 0.85 : 1.0)
            .animation(.interactiveSpring(response: 0.25, dampingFraction: 0.6, blendDuration: 0.1), value: configuration.isPressed)
    }
}

// Keep ScaleButtonStyle for backward compatibility
struct ScaleButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.97 : 1.0)
            .opacity(configuration.isPressed ? 0.9 : 1.0)
            .animation(.easeOut(duration: 0.15), value: configuration.isPressed)
    }
}

