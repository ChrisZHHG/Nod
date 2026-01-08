import SwiftUI

struct GroupSetupView: View {
    // Removed direct dependency on AmbrosiaManager for portability
    @State private var headcount: Int = 4
    @State private var budget: Double = 50 // More realistic default
    @State private var selectedAllergies: Set<String> = []
    
    let commonAllergies = ["Peanuts", "Shellfish", "Dairy", "Gluten", "Eggs", "Soy", "Tree Nuts", "Fish"]
    
    // Callback returns the constructed profile
    var onConfirm: (GroupProfile) -> Void
    
    var body: some View {
        ZStack {
            // Semi-transparent overlay
            Color.black.opacity(0.4)
                .ignoresSafeArea()
                // Explicitly allow hits on background to block interaction with underlying scanner
                .contentShape(Rectangle()) 
                .onTapGesture {
                    // Swallow taps to prevent them from reaching the scanner
                }
            
            // Content Container
            VStack(spacing: 0) {
                // Scrollable Content
                ScrollView {
                    VStack(spacing: 0) {
                        Spacer().frame(height: 60) // Top padding
                        
                        // Main Card
                        VStack(spacing: AmbrosiaTheme.Spacing.xl) {
                            // Header
                            Text("Group Profile")
                                .font(AmbrosiaTheme.Typography.header)
                                .foregroundStyle(AmbrosiaTheme.Colors.textPrimary)
                            
                            // Bento Grid
                            HStack(spacing: AmbrosiaTheme.Bento.spacing) {
                                // Headcount Tile
                                BentoTile {
                                    VStack(spacing: AmbrosiaTheme.Spacing.sm) {
                                        Text("\(headcount)")
                                            .font(AmbrosiaTheme.Typography.bentoNumber)
                                            .foregroundStyle(AmbrosiaTheme.Colors.warmOrange)
                                        
                                        Text("Diners")
                                            .font(AmbrosiaTheme.Typography.caption)
                                            .foregroundStyle(AmbrosiaTheme.Colors.textSecondary)
                                        
                                        // Stepper Controls
                                        HStack(spacing: AmbrosiaTheme.Spacing.lg) {
                                            StepperButton(icon: "minus") {
                                                if headcount > 2 { headcount -= 1 }
                                            }
                                            StepperButton(icon: "plus") {
                                                if headcount < 12 { headcount += 1 }
                                            }
                                        }
                                    }
                                    .contentShape(Rectangle()) // Ensure entire tile content is hit-testable
                                }
                                .frame(maxWidth: .infinity)
                                
                                // Budget Tile
                                BentoTile {
                                    VStack(spacing: AmbrosiaTheme.Spacing.sm) {
                                        Text("$\(Int(budget))")
                                            .font(.system(size: 36, weight: .bold, design: .rounded)) // Smaller font to fit
                                            .minimumScaleFactor(0.5) // Allow scaling down if needed
                                            .lineLimit(1)
                                            .foregroundStyle(AmbrosiaTheme.Colors.coralEnd)
                                        
                                        Text("Budget")
                                            .font(AmbrosiaTheme.Typography.caption)
                                            .foregroundStyle(AmbrosiaTheme.Colors.textSecondary)
                                        
                                        // Custom Slider
                                        Slider(value: $budget, in: 15...150, step: 5)
                                            .tint(AmbrosiaTheme.Gradients.coralSunset)
                                    }
                                    .contentShape(Rectangle())
                                }
                                .frame(maxWidth: .infinity)
                            }
                            .frame(height: AmbrosiaTheme.Bento.tileLargeHeight)
                            
                            // Restrictions Tile (Full Width)
                            BentoTile {
                                VStack(alignment: .leading, spacing: AmbrosiaTheme.Spacing.md) {
                                    HStack {
                                        Image(systemName: "exclamationmark.triangle.fill")
                                            .foregroundStyle(.red)
                                        Text("Dietary Restrictions")
                                            .font(AmbrosiaTheme.Typography.headline)
                                            .foregroundStyle(AmbrosiaTheme.Colors.textPrimary)
                                    }
                                    
                                    FlowLayout(spacing: AmbrosiaTheme.Spacing.sm) {
                                        ForEach(commonAllergies, id: \.self) { allergy in
                                            AllergyChip(
                                                label: allergy,
                                                isSelected: selectedAllergies.contains(allergy)
                                            ) {
                                                if selectedAllergies.contains(allergy) {
                                                    selectedAllergies.remove(allergy)
                                                } else {
                                                    selectedAllergies.insert(allergy)
                                                }
                                            }
                                        }
                                    }
                                }
                                .contentShape(Rectangle())
                            }
                        }
                        .padding(AmbrosiaTheme.Spacing.xl)
                        .glassCard()
                        .padding(.horizontal, AmbrosiaTheme.Spacing.lg)
                        .padding(.bottom, 120) // Extra padding for sticky footer
                    }
                }
                .scrollIndicators(.hidden)
                
                // Sticky Footer: Generate Feast Button
                VStack {
                    GlassButton(title: "Generate Feast", icon: "wand.and.stars") {
                        print("Generate Feast Tapped") // Debug log
                        var profile = GroupProfile()
                        profile.headcount = headcount
                        profile.budgetTotal = Int(budget)
                        profile.collectiveAllergies = Array(selectedAllergies)
                        // Pass profile back to parent
                        onConfirm(profile)
                    }
                }
                .padding(.horizontal, AmbrosiaTheme.Spacing.xxl)
                .padding(.vertical, AmbrosiaTheme.Spacing.xl)
                .padding(.bottom, 20) // Bottom safe area buffer
                .background(
                    LinearGradient(colors: [.clear, .black.opacity(0.1)], startPoint: .top, endPoint: .bottom)
                        .blur(radius: 10)
                )
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity) // Ensure full screen to align footer to bottom
        }
    }
}


// MARK: - Bento Components

struct BentoTile<Content: View>: View {
    let content: Content
    
    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }
    
    var body: some View {
        content
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .padding(AmbrosiaTheme.Spacing.lg)
            .glassCard() // Matches other Bento tiles
    }
}

struct StepperButton: View {
    let icon: String
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Image(systemName: icon)
                .font(.system(size: 18, weight: .bold)) // Slightly larger icon
                .foregroundStyle(AmbrosiaTheme.Colors.textPrimary)
                .frame(width: 44, height: 44) // 44pt minimum touch target
                .background(AmbrosiaTheme.Colors.surfaceSecondary)
                .clipShape(Circle())
                .contentShape(Circle()) // Explicit shape for hit testing
        }
    }
}

struct AllergyChip: View {
    let label: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text(label)
                .font(AmbrosiaTheme.Typography.caption)
                .fontWeight(.medium)
                .padding(.vertical, AmbrosiaTheme.Spacing.sm)
                .padding(.horizontal, AmbrosiaTheme.Spacing.md)
                .background(isSelected ? Color.red.opacity(0.8) : AmbrosiaTheme.Colors.surfaceSecondary)
                .foregroundStyle(AmbrosiaTheme.Colors.textPrimary)
                .clipShape(Capsule())
                .overlay(
                    Capsule()
                        .stroke(isSelected ? Color.red : .clear, lineWidth: 0.5)
                )
        }
    }
}

// MARK: - Flow Layout for Tags

struct FlowLayout: Layout {
    var spacing: CGFloat = 8
    
    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let result = arrangeSubviews(proposal: proposal, subviews: subviews)
        return result.size
    }
    
    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        let result = arrangeSubviews(proposal: proposal, subviews: subviews)
        for (index, frame) in result.frames.enumerated() {
            subviews[index].place(at: CGPoint(x: bounds.minX + frame.minX, y: bounds.minY + frame.minY), proposal: .unspecified)
        }
    }
    
    private func arrangeSubviews(proposal: ProposedViewSize, subviews: Subviews) -> (size: CGSize, frames: [CGRect]) {
        let maxWidth = proposal.width ?? .infinity
        var currentX: CGFloat = 0
        var currentY: CGFloat = 0
        var lineHeight: CGFloat = 0
        var frames: [CGRect] = []
        
        for subview in subviews {
            let size = subview.sizeThatFits(.unspecified)
            
            if currentX + size.width > maxWidth {
                currentX = 0
                currentY += lineHeight + spacing
                lineHeight = 0
            }
            
            frames.append(CGRect(origin: CGPoint(x: currentX, y: currentY), size: size))
            lineHeight = max(lineHeight, size.height)
            currentX += size.width + spacing
        }
        
        return (CGSize(width: maxWidth, height: currentY + lineHeight), frames)
    }
}

