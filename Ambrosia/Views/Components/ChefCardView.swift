import SwiftUI

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
