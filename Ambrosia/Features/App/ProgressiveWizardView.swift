import SwiftUI

// MARK: - Local StepperButton (duplicated from GroupSetupView — do not import)

private struct StepperButton: View {
    let icon: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Image(systemName: icon)
                .font(.system(size: 18, weight: .bold))
                .foregroundStyle(AmbrosiaTheme.Cinematic.pureWhite)
                .frame(width: 44, height: 44)
                .background(AmbrosiaTheme.Cinematic.glassDark)
                .clipShape(Circle())
                .contentShape(Circle())
        }
    }
}

// MARK: - Progressive UI Wizard

struct ProgressiveWizardView: View {
    @Bindable var store: AppStore
    @State private var currentStep: Int = 0
    @Namespace private var wizardNamespace

    let vetoOptions = [
        ("Pork", "🐷"), ("Peanuts", "🥜"), ("Cilantro", "🌿"),
        ("Spicy", "🌶️"), ("Shellfish", "🦐"), ("Gluten", "🌾")
    ]
    let cravingOptions = [
        ("Heavy & Meaty", "🥩"), ("Light & Fresh", "🥗"),
        ("Carb Comfort", "🍝"), ("Surprise Me", "✨")
    ]

    private var isGroup: Bool { store.mode == .group }
    private var isLastStep: Bool { currentStep == 2 }

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
                ProgressView(value: Double(currentStep + 1), total: 3.0)
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
                        .tag(1)

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
                        .tag(2)
                    } else {
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

                Spacer(minLength: 110)
            }

            // Floating Bottom Navigation
            FloatingBottomBar {
                HStack(spacing: AmbrosiaTheme.Spacing.md) {
                    if currentStep > 0 {
                        GlassButton(title: "Back", icon: "chevron.left", variant: .secondary) {
                            withAnimation { currentStep -= 1 }
                        }
                    }

                    if isLastStep {
                        GlassButton(title: "Let the AI Decide", icon: "wand.and.stars", variant: .primary) {
                            Task { await store.generateRecommendation() }
                        }
                    } else {
                        GlassButton(title: "Next", icon: "arrow.right", variant: .primary) {
                            withAnimation { currentStep += 1 }
                        }
                    }
                }
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
            VStack(spacing: AmbrosiaTheme.Spacing.xl) {
                Text("\(headcount)")
                    .font(.system(size: 80, weight: .bold, design: .rounded))
                    .foregroundColor(AmbrosiaTheme.Cinematic.pureWhite)

                HStack(spacing: AmbrosiaTheme.Spacing.xxl) {
                    StepperButton(icon: "minus") {
                        if headcount > 2 { onUpdate(headcount - 1) }
                    }
                    StepperButton(icon: "plus") {
                        if headcount < 12 { onUpdate(headcount + 1) }
                    }
                }
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
                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: AmbrosiaTheme.Spacing.md) {
                    ForEach(options, id: \.0) { option in
                        let isSelected = selections.contains(option.0)
                        Button(action: {
                            HapticFeedback.selection.trigger()
                            onToggle(option.0)
                        }) {
                            VStack(spacing: AmbrosiaTheme.Spacing.sm) {
                                Text(option.1).font(.system(size: 36))
                                Text(option.0)
                                    .font(AmbrosiaTheme.Typography.caption)
                                    .padding(.vertical, AmbrosiaTheme.Spacing.sm)
                                    .padding(.horizontal, AmbrosiaTheme.Spacing.md)
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, AmbrosiaTheme.Spacing.md)
                            .foregroundColor(isSelected ? AmbrosiaTheme.Cinematic.deepBlack : AmbrosiaTheme.Cinematic.pureWhite)
                            .background(.ultraThinMaterial)
                            .overlay(
                                RoundedRectangle(cornerRadius: AmbrosiaTheme.Radius.lg, style: .continuous)
                                    .fill(AmbrosiaTheme.Cinematic.amber.opacity(isSelected ? 0.85 : 0))
                            )
                            .clipShape(RoundedRectangle(cornerRadius: AmbrosiaTheme.Radius.lg, style: .continuous))
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
                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: AmbrosiaTheme.Spacing.md) {
                    ForEach(options, id: \.0) { option in
                        let isSelected = selections.contains(option.0)
                        Button(action: {
                            HapticFeedback.selection.trigger()
                            onToggle(option.0)
                        }) {
                            VStack(spacing: AmbrosiaTheme.Spacing.sm) {
                                Text(option.1).font(.system(size: 36))
                                Text(option.0)
                                    .font(AmbrosiaTheme.Typography.caption)
                                    .padding(.vertical, AmbrosiaTheme.Spacing.sm)
                                    .padding(.horizontal, AmbrosiaTheme.Spacing.md)
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, AmbrosiaTheme.Spacing.md)
                            .foregroundColor(isSelected ? AmbrosiaTheme.Cinematic.deepBlack : AmbrosiaTheme.Cinematic.pureWhite)
                            .background(.ultraThinMaterial)
                            .overlay(
                                RoundedRectangle(cornerRadius: AmbrosiaTheme.Radius.lg, style: .continuous)
                                    .fill(AmbrosiaTheme.Cinematic.amber.opacity(isSelected ? 0.85 : 0))
                            )
                            .clipShape(RoundedRectangle(cornerRadius: AmbrosiaTheme.Radius.lg, style: .continuous))
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
            VStack(spacing: AmbrosiaTheme.Spacing.md) {
                ForEach(moods, id: \.self) { m in
                    let isSelected = mood == m
                    Button(action: {
                        HapticFeedback.selection.trigger()
                        onUpdate(m)
                    }) {
                        Text(m)
                            .font(AmbrosiaTheme.Typography.headline)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, AmbrosiaTheme.Spacing.lg)
                            .foregroundColor(isSelected ? AmbrosiaTheme.Cinematic.deepBlack : AmbrosiaTheme.Cinematic.pureWhite)
                            .background(.ultraThinMaterial)
                            .overlay(
                                RoundedRectangle(cornerRadius: AmbrosiaTheme.Radius.lg, style: .continuous)
                                    .fill(AmbrosiaTheme.Cinematic.amber.opacity(isSelected ? 0.85 : 0))
                            )
                            .clipShape(RoundedRectangle(cornerRadius: AmbrosiaTheme.Radius.lg, style: .continuous))
                    }
                }
                TextField("Other...", text: .init(
                    get: { mood },
                    set: { onUpdate($0) }
                ))
                .font(AmbrosiaTheme.Typography.headline)
                .padding(.vertical, AmbrosiaTheme.Spacing.lg)
                .padding(.horizontal, AmbrosiaTheme.Spacing.lg)
                .background(.ultraThinMaterial)
                .clipShape(RoundedRectangle(cornerRadius: AmbrosiaTheme.Radius.lg, style: .continuous))
                .foregroundColor(AmbrosiaTheme.Cinematic.pureWhite)
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
                .font(AmbrosiaTheme.Typography.header)
                .foregroundColor(AmbrosiaTheme.Cinematic.pureWhite)
                .padding(.bottom, 10)

            content
        }
        .padding(30)
        .glassCard(cornerRadius: AmbrosiaTheme.Radius.xxl)
        .shadow(color: .black.opacity(0.3), radius: 20, y: 10)
        .padding(.horizontal, 20)
    }
}
