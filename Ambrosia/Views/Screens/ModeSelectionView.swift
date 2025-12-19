import SwiftUI

struct ModeSelectionView: View {
    @EnvironmentObject var manager: AmbrosiaManager
    
    var body: some View {
        ZStack {
            LiquidBackground() // Shared background
            
            VStack(spacing: 40) {
                // Header
                VStack(spacing: 10) {
                    Text("Ambrosia")
                        .font(.custom("Didot", size: 48))
                        .fontWeight(.bold)
                        .foregroundStyle(.white)
                    
                    Text("How are we dining today?")
                        .font(.system(size: 18, weight: .medium, design: .serif))
                        .foregroundStyle(.white.opacity(0.8))
                }
                .padding(.top, 60)
                
                // Cards
                VStack(spacing: 24) {
                    // Option A: Individual
                    ModeCard(
                        title: "For Myself",
                        subtitle: "Translator • Discovery • Personal",
                        icon: "person.fill",
                        color: .cyan
                    ) {
                        manager.setMode(.individual)
                        manager.startSession() // Go to Scanner
                    }
                    
                    // Option B: Group
                    ModeCard(
                        title: "We Are Sharing",
                        subtitle: "Diplomat • Consensus • Safety",
                        icon: "person.3.fill",
                        color: .purple
                    ) {
                        manager.setMode(.group)
                        // In real flow: Show SetupWizard first.
                        // For MVP: Start session -> Scanner -> THEN Setup Logic?
                        // Let's stick to flow: Select Mode -> Scan -> Setup Logic -> Result
                        manager.startSession()
                    }
                }
                .padding(.horizontal, 24)
                
                Spacer()
            }
        }
    }
}

struct ModeCard: View {
    let title: String
    let subtitle: String
    let icon: String
    let color: Color
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 20) {
                ZStack {
                    Circle()
                        .fill(color.opacity(0.2))
                        .frame(width: 60, height: 60)
                    
                    Image(systemName: icon)
                        .font(.system(size: 24))
                        .foregroundStyle(color)
                }
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(title)
                        .font(.title3)
                        .fontWeight(.bold)
                        .foregroundStyle(.white)
                    
                    Text(subtitle)
                        .font(.caption)
                        .foregroundStyle(.white.opacity(0.7))
                }
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .foregroundStyle(.white.opacity(0.3))
            }
            .padding(20)
            .background(.ultraThinMaterial)
            .clipShape(RoundedRectangle(cornerRadius: 24))
            .overlay(
                RoundedRectangle(cornerRadius: 24)
                    .stroke(.white.opacity(0.2), lineWidth: 1)
            )
        }
        .buttonStyle(PlainButtonStyle()) // Needed to prevent whole list highlight
    }
}
