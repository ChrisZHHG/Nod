import SwiftUI

// MARK: - Floating Glass Navigation Bar

/// A floating navigation bar with glass morphism effect, adapts to safe areas including Dynamic Island
struct FloatingNavBar: View {
    @Environment(\.safeAreaInsets) private var safeAreaInsets
    
    let title: String?
    let leadingAction: NavBarAction?
    let trailingAction: NavBarAction?
    
    struct NavBarAction {
        let icon: String
        let action: () -> Void
    }
    
    init(
        title: String? = nil,
        leading: NavBarAction? = nil,
        trailing: NavBarAction? = nil
    ) {
        self.title = title
        self.leadingAction = leading
        self.trailingAction = trailing
    }
    
    var body: some View {
        GeometryReader { geometry in
            let topSafeArea = geometry.safeAreaInsets.top
            let hasDynamicIsland = topSafeArea > 50 // Dynamic Island devices have ~59pt top safe area
            
            VStack(spacing: 0) {
                // Nav Bar Content
                HStack(spacing: AmbrosiaTheme.Spacing.md) {
                    // Leading Button
                    if let leading = leadingAction {
                        NavBarButton(icon: leading.icon, action: leading.action)
                    } else {
                        Spacer().frame(width: 44)
                    }
                    
                    Spacer()
                    
                    // Title
                    if let title = title {
                        Text(title)
                            .font(AmbrosiaTheme.Typography.headline)
                            .foregroundStyle(AmbrosiaTheme.Colors.textPrimary)
                    }
                    
                    Spacer()
                    
                    // Trailing Button
                    if let trailing = trailingAction {
                        NavBarButton(icon: trailing.icon, action: trailing.action)
                    } else {
                        Spacer().frame(width: 44)
                    }
                }
                .padding(.horizontal, AmbrosiaTheme.Spacing.lg)
                .padding(.vertical, AmbrosiaTheme.Spacing.md)
                .padding(.top, hasDynamicIsland ? 8 : 0) // Extra padding for Dynamic Island
                
                Spacer()
            }
            .ignoresSafeArea(edges: .top)
        }
    }
}

// MARK: - Nav Bar Button

struct NavBarButton: View {
    let icon: String
    let action: () -> Void
    
    var body: some View {
        Button(action: {
            HapticFeedback.light.trigger()
            action()
        }) {
            Image(systemName: icon)
                .font(.system(size: 18, weight: .semibold))
                .foregroundStyle(AmbrosiaTheme.Colors.textPrimary)
                .frame(width: 44, height: 44)
                .background(.ultraThinMaterial)
                .clipShape(Circle())
                .overlay(
                    Circle()
                        .stroke(AmbrosiaTheme.Colors.glassBorder, lineWidth: 0.5)
                )
        }
        .buttonStyle(ScaleButtonStyle())
    }
}

// MARK: - Floating Bottom Bar

/// A floating action bar at the bottom of the screen
struct FloatingBottomBar<Content: View>: View {
    @ViewBuilder let content: () -> Content
    
    var body: some View {
        GeometryReader { geometry in
            VStack {
                Spacer()
                
                content()
                    .padding(.horizontal, AmbrosiaTheme.Spacing.lg)
                    .padding(.vertical, AmbrosiaTheme.Spacing.lg)
                    .padding(.bottom, geometry.safeAreaInsets.bottom > 0 ? 0 : AmbrosiaTheme.Spacing.lg)
                    .background(
                        RoundedRectangle(cornerRadius: AmbrosiaTheme.Radius.xxl, style: .continuous)
                            .fill(.ultraThinMaterial)
                            .overlay(
                                RoundedRectangle(cornerRadius: AmbrosiaTheme.Radius.xxl, style: .continuous)
                                    .stroke(AmbrosiaTheme.Colors.glassBorder, lineWidth: 0.5)
                            )
                            .shadow(color: AmbrosiaTheme.Shadows.cardShadowColor, radius: 20, x: 0, y: -5)
                    )
            }
            .ignoresSafeArea(edges: .bottom)
        }
    }
}

// MARK: - Safe Area Environment Key

private struct SafeAreaInsetsKey: EnvironmentKey {
    static let defaultValue: EdgeInsets = EdgeInsets()
}

extension EnvironmentValues {
    var safeAreaInsets: EdgeInsets {
        get { self[SafeAreaInsetsKey.self] }
        set { self[SafeAreaInsetsKey.self] = newValue }
    }
}

// MARK: - View Modifier for Nav Bar Overlay

struct FloatingNavBarModifier: ViewModifier {
    let title: String?
    let leadingAction: FloatingNavBar.NavBarAction?
    let trailingAction: FloatingNavBar.NavBarAction?
    
    func body(content: Content) -> some View {
        ZStack(alignment: .top) {
            content
            
            FloatingNavBar(
                title: title,
                leading: leadingAction,
                trailing: trailingAction
            )
        }
    }
}

extension View {
    /// Adds a floating glass navigation bar overlay
    func floatingNavBar(
        title: String? = nil,
        leading: FloatingNavBar.NavBarAction? = nil,
        trailing: FloatingNavBar.NavBarAction? = nil
    ) -> some View {
        modifier(FloatingNavBarModifier(
            title: title,
            leadingAction: leading,
            trailingAction: trailing
        ))
    }
}

// MARK: - Minimal Back Button

/// A simple floating back button for detail views
struct FloatingBackButton: View {
    @Environment(\.safeAreaInsets) private var safeAreaInsets
    let action: () -> Void
    
    var body: some View {
        VStack {
            HStack {
                NavBarButton(icon: "chevron.left", action: action)
                    .padding(.leading, AmbrosiaTheme.Spacing.lg)
                    .padding(.top, safeAreaInsets.top + AmbrosiaTheme.Spacing.sm)
                
                Spacer()
            }
            Spacer()
        }
        .ignoresSafeArea(edges: .top)
    }
}
