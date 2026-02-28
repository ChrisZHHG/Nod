import SwiftUI

// MARK: - Progressive UI Wizard
struct ProgressiveWizardView: View {
    @Bindable var store: AppStore
    @State private var currentStep: Int = 0
    @Namespace private var wizardNamespace
    
    // Quick Icon Definitions
    let vetoOptions = [
        ("Pork", "🐷"), ("Peanuts", "🥜"), ("Cilantro", "🌿"),
        ("Spicy", "🌶️"), ("Shellfish", "🦐"), ("Gluten", "🌾")
    ]
    let cravingOptions = [
        ("Heavy & Meaty", "🥩"), ("Light & Fresh", "🥗"),
        ("Carb Comfort", "🍝"), ("Surprise Me", "✨")
    ]
    
    // Derived Binding arrays to simplify selection logic
    private var isGroup: Bool { store.mode == .group }
    
    var body: some View {
        ZStack {
            // Background Layer: Cinematic Blurred Menu
            if let firstImg = store.capturedImages.first, let uiImage = UIImage(data: firstImg) {
                Image(uiImage: uiImage)
                    .resizable()
                    .scaledToFill()
                    .ignoresSafeArea()
                    .blur(radius: 40)
                    .overlay(Color.black.opacity(0.4))
            } else {
                AmbrosiaTheme.Cinematic.heroOverlay.ignoresSafeArea()
            }
            
            VStack {
                // Header Progress
                ProgressView(value: Double(currentStep + 1), total: isGroup ? 4.0 : 3.0)
                    .progressViewStyle(.linear)
                    .tint(AmbrosiaTheme.Cinematic.amber)
                    .padding(.horizontal, 40)
                    .padding(.top, 20)
                
                Spacer()
                
                // Cards Carousel
                TabView(selection: $currentStep) {
                    if isGroup {
                        GroupSizeCard(
                            headcount: store.groupProfile.headcount,
                            onUpdate: { newCount in store.updateGroupProfile { $0.headcount = newCount } }
                        )
                        .tag(0)
                        
                        ForkModeCard()
                            .tag(1)
                            
                        VetoCard(
                            selections: store.groupProfile.vetoes,
                            options: vetoOptions,
                            onToggle: { veto in
                                store.updateGroupProfile { p in
                                    if p.vetoes.contains(veto) { p.vetoes.removeAll(where: { $0 == veto }) }
                                    else { p.vetoes.append(veto) }
                                }
                            }
                        )
                        .tag(2)
                            
                        CravingCard(
                            selections: store.groupProfile.cravings,
                            options: cravingOptions,
                            onToggle: { craving in
                                store.updateGroupProfile { p in
                                    if p.cravings.contains(craving) { p.cravings.removeAll(where: { $0 == craving }) }
                                    else { p.cravings.append(craving) }
                                }
                            }
                        )
                        .tag(3)
                    } else {
                        // Solo Mode is shorter
                        VetoCard(
                            selections: store.individualProfile.vetoes,
                            options: vetoOptions,
                            onToggle: { veto in
                                store.updateIndividualProfile { p in
                                    if p.vetoes.contains(veto) { p.vetoes.removeAll(where: { $0 == veto }) }
                                    else { p.vetoes.append(veto) }
                                }
                            }
                        )
                        .tag(0)
                        
                        CravingCard(
                            selections: store.individualProfile.cravings,
                            options: cravingOptions,
                            onToggle: { craving in
                                store.updateIndividualProfile { p in
                                    if p.cravings.contains(craving) { p.cravings.removeAll(where: { $0 == craving }) }
                                    else { p.cravings.append(craving) }
                                }
                            }
                        )
                        .tag(1)
                            
                        MoodCard(
                            mood: store.individualProfile.mood,
                            onUpdate: { newMood in store.updateIndividualProfile { $0.mood = newMood } }
                        )
                        .tag(2)
                    }
                }
                .tabViewStyle(.page(indexDisplayMode: .never))
                .animation(.spring(response: 0.5, dampingFraction: 0.8), value: currentStep)
                
                Spacer()
                
                // Navigation Buttons
                HStack {
                    if currentStep > 0 {
                        Button("Back") {
                            withAnimation { currentStep -= 1 }
                        }
                        .foregroundColor(.white.opacity(0.7))
                        .padding()
                    }
                    
                    Spacer()
                    
                    let isLastStep = isGroup ? (currentStep == 3) : (currentStep == 2)
                    
                    Button(isLastStep ? "Generate Recommendations" : "Next") {
                        if isLastStep {
                            Task {
                                await store.generateRecommendation()
                            }
                        } else {
                            withAnimation { currentStep += 1 }
                        }
                    }
                    .font(.headline)
                    .padding(.horizontal, 24)
                    .padding(.vertical, 14)
                    .background(AmbrosiaTheme.Cinematic.amber)
                    .foregroundColor(.black)
                    .clipShape(Capsule())
                }
                .padding(30)
            }
        }
    }
}

// MARK: - Individual Wizard Cards

struct GroupSizeCard: View {
    let headcount: Int
    let onUpdate: (Int) -> Void
    
    var body: some View {
        WizardCard(title: "How many people?") {
            VStack(spacing: 30) {
                Text("\(headcount)")
                    .font(.system(size: 64, weight: .bold, design: .rounded))
                    .foregroundColor(.white)
                
                Slider(value: .init(
                    get: { Double(headcount) },
                    set: { onUpdate(Int($0)) }
                ), in: 2...10, step: 1)
                .accentColor(AmbrosiaTheme.Cinematic.amber)
            }
        }
    }
}

struct ForkModeCard: View {
    // To simplify: if 'Share', then we just rely on GroupProfile logic inside ChefAgent
    var body: some View {
        WizardCard(title: "Dining Style") {
            VStack(spacing: 20) {
                Button(action: {}) {
                    HStack {
                        Image(systemName: "tray.2.fill")
                        Text("Share Everything")
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(AmbrosiaTheme.Cinematic.amber.opacity(0.8))
                    .foregroundColor(.black)
                    .cornerRadius(12)
                }
                
                Button(action: {}) {
                    HStack {
                        Image(systemName: "person.crop.square.fill")
                        Text("Order Individually")
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(.ultraThinMaterial)
                    .foregroundColor(.white)
                    .cornerRadius(12)
                }
                .disabled(true) // Currently backend defaults to shared group combos.
            }
        }
    }
}

struct VetoCard: View {
    let selections: [String]
    let options: [(String, String)]
    let onToggle: (String) -> Void
    
    var body: some View {
        WizardCard(title: "Any absolute vetoes?") {
            ScrollView {
                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 15) {
                    ForEach(options, id: \.0) { option in
                        let isSelected = selections.contains(option.0)
                        Button(action: {
                            onToggle(option.0)
                        }) {
                            VStack(spacing: 8) {
                                Text(option.1).font(.system(size: 36))
                                Text(option.0).font(AmbrosiaTheme.Typography.headline)
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                            .background(isSelected ? AmbrosiaTheme.Cinematic.amber.opacity(0.8) : Color.clear)
                            .background(.ultraThinMaterial)
                            .cornerRadius(16)
                            .foregroundColor(isSelected ? .black : .white)
                        }
                    }
                }
            }
        }
    }
}

struct CravingCard: View {
    let selections: [String]
    let options: [(String, String)]
    let onToggle: (String) -> Void
    
    var body: some View {
        WizardCard(title: "What are we craving?") {
            ScrollView {
                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 15) {
                    ForEach(options, id: \.0) { option in
                        let isSelected = selections.contains(option.0)
                        Button(action: {
                            onToggle(option.0)
                        }) {
                            VStack(spacing: 8) {
                                Text(option.1).font(.system(size: 36))
                                Text(option.0).font(AmbrosiaTheme.Typography.headline)
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                            .background(isSelected ? AmbrosiaTheme.Cinematic.amber.opacity(0.8) : Color.clear)
                            .background(.ultraThinMaterial)
                            .cornerRadius(16)
                            .foregroundColor(isSelected ? .black : .white)
                        }
                    }
                }
            }
        }
    }
}

struct MoodCard: View {
    let mood: String
    let onUpdate: (String) -> Void
    
    let moods = ["Relaxed ✨", "Exhausted 😩", "Celebratory 🥂", "Adventurous 🧭"]
    
    var body: some View {
        WizardCard(title: "What's the vibe tonight?") {
            VStack(spacing: 15) {
                ForEach(moods, id: \.self) { m in
                    let isSelected = mood == m
                    Button(action: { onUpdate(m) }) {
                        Text(m)
                            .font(AmbrosiaTheme.Typography.headline)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                            .background(isSelected ? AmbrosiaTheme.Cinematic.amber.opacity(0.8) : Color.clear)
                            .background(.ultraThinMaterial)
                            .cornerRadius(16)
                            .foregroundColor(isSelected ? .black : .white)
                    }
                }
                TextField("Other...", text: .init(
                    get: { mood },
                    set: { onUpdate($0) }
                ))
                    .font(AmbrosiaTheme.Typography.headline)
                    .padding(.vertical, 16)
                    .padding(.horizontal)
                    .background(.ultraThinMaterial)
                    .cornerRadius(16)
                    .foregroundColor(.white)
            }
        }
    }
}

// MARK: - Reusable Wizard Card
struct WizardCard<Content: View>: View {
    let title: String
    let content: Content
    
    init(title: String, @ViewBuilder content: () -> Content) {
        self.title = title
        self.content = content()
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            Text(title)
                .font(.system(size: 28, weight: .bold, design: .rounded))
                .foregroundColor(.white)
                .padding(.bottom, 10)
            
            content
        }
        .padding(30)
        .background(Color.black.opacity(0.2))
        .background(.ultraThinMaterial)
        .cornerRadius(32)
        .shadow(color: .black.opacity(0.3), radius: 20, y: 10)
        .padding(.horizontal, 20)
    }
}
