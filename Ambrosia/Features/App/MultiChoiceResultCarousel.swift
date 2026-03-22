import SwiftUI

struct MultiChoiceResultCarousel: View {
    let store: AppStore
    let mode: AppMode
    let soloSet: SoloRecommendationSet?
    let groupSet: GroupRecommendationSet?
    
    @State private var currentIndex: Int = 0
    @State private var fallbackText: String = ""
    
    var body: some View {
        ZStack(alignment: .bottom) {
            Color.black.ignoresSafeArea()
            
            // Carousel
            TabView(selection: $currentIndex) {
                if let options = soloSet?.options {
                    ForEach(Array(options.enumerated()), id: \.offset) { index, rec in
                        ChefCardView(recommendation: rec, isEmbedded: true, onReset: {})
                            .tag(index)
                    }
                } else if let combos = groupSet?.combos {
                    ForEach(Array(combos.enumerated()), id: \.offset) { index, combo in
                        ComboResultView(combo: combo, isEmbedded: true, onRefine: { _ in })
                            .tag(index)
                    }
                }
            }
            .tabViewStyle(.page(indexDisplayMode: .always))
            .ignoresSafeArea()
            
            // Bottom Fallback Action Bar
            VStack {
                HStack(spacing: 8) {
                    TextField("I want something else...", text: $fallbackText)
                        .padding(14)
                        .background(.ultraThinMaterial)
                        .environment(\.colorScheme, .dark)
                        .cornerRadius(12)
                        .foregroundColor(.white)
                    
                    Button(action: {
                        retriggerAI()
                    }) {
                        Image(systemName: "arrow.right")
                            .font(.system(size: 18, weight: .bold))
                            .foregroundColor(NodTheme.Cinematic.deepBlack)
                            .padding()
                            .background(NodTheme.Cinematic.amber)
                            .clipShape(Circle())
                    }
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 20) // Push below the tab indicators
            }
            .background(
                Rectangle()
                    .fill(LinearGradient(colors: [.black.opacity(0.8), .clear], startPoint: .bottom, endPoint: .top))
                    .frame(height: 120)
                    .offset(y: 40)
            )
            .ignoresSafeArea(edges: .bottom)
        }
        .overlay(alignment: .topLeading) {
            Button(action: {
                store.navigationPath.removeLast()
            }) {
                Image(systemName: "chevron.left")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundStyle(.white)
                    .frame(width: 44, height: 44)
                    .background(.ultraThinMaterial)
                    .clipShape(Circle())
                    .overlay(Circle().stroke(Color.white.opacity(0.3), lineWidth: 0.5))
            }
            .padding(.leading, 20)
            .padding(.top, 56) // Safe area estimation
        }
        .preferredColorScheme(.dark)
    }
    
    private func retriggerAI() {
        guard !fallbackText.isEmpty else { return }
        let query = fallbackText
        fallbackText = ""
        
        // Append their refinement to the context
        if mode == .individual {
            store.updateIndividualProfile { $0.cravings.append(query) }
        } else {
            store.updateGroupProfile { $0.cravings.append(query) }
        }
        
        // Pop back to Wizard and immediately trigger AI regeneration
        store.navigationPath.removeLast()
        Task {
            await store.generateRecommendation()
        }
    }
}
