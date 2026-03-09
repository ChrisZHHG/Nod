# CLAUDE.md — Ambrosia / Nod Design Contract

This file is the authoritative contract for all code generation in this project.
Read it completely before writing any code. Do not deviate from these rules.

---

## 1. Project Identity

- **App name**: Nod ("The effortless consensus.")
- **Platform**: iOS 17+ (target iOS 18 for MeshGradient features, always provide fallback)
- **Language**: Swift / SwiftUI — no UIKit views unless bridging via UIViewRepresentable

---

## 2. Architecture Rules (Hard Boundaries)

| Layer | Location | Rule |
|---|---|---|
| Domain models | `Core/Domain/` | Zero UIKit/SwiftUI imports. Pure Swift structs, Codable, Sendable. |
| Algorithms / Agents | `Core/Algorithms/` | Zero UIKit/SwiftUI imports. Only `Foundation` + domain types. |
| Services | `Services/` | Only protocol conformances. Depends inward on domain only. |
| Views | `Views/` + `Features/` | SwiftUI only. Must use design system tokens — no magic numbers. |

**Never add `import SwiftUI` or `import UIKit` to anything inside `Core/`.**

### State Management
- Single source of truth: `AppStore` (`@Observable`, located in `Features/App/AppStore.swift`)
- All state mutations go through `AppStore` actions — never mutate store properties directly from views
- Navigation is managed by `store.navigationPath: [AppDestination]` (type-safe, `AppDestination` enum)

### AppDestination (routing)
```swift
enum AppDestination: Hashable {
    case scanner
    case wizard
    case agentChatLobby(isHost: Bool)
    case soloResult(SoloRecommendationSet)
    case groupResult(GroupRecommendationSet)
}
```

### AppStore Key API
```swift
store.mode: AppMode          // .individual | .group | .agentChat
store.appState: AppState     // .idle | .decoding | .reasoning | .verifying | .error(_)
store.capturedImages: [Data]
store.groupProfile: GroupProfile      // { headcount, vetoes, cravings, mood }
store.individualProfile: IndividualProfile // { partySize, vetoes, cravings, mood }
store.navigationPath: [AppDestination]

// Mutations
store.setMode(_ mode: AppMode)
store.startSession()
store.resetSession()
store.captureImage(_ data: Data)
store.updateGroupProfile { $0.xxx = yyy }
store.updateIndividualProfile { $0.xxx = yyy }
store.generateRecommendation() async  // triggers full AI pipeline
```

---

## 3. Design System — USE THESE, NOTHING ELSE

All design tokens live in `Views/Components/AmbrosiaTheme.swift`.

### Color Palette

**Primary visual language: Cinematic (dark, used everywhere)**
```swift
AmbrosiaTheme.Cinematic.deepBlack   // "#101010" — canvas
AmbrosiaTheme.Cinematic.richBrown   // "#1A1209" — warm shadow
AmbrosiaTheme.Cinematic.amber       // "#E8930A" — CTA / accent / highlight
AmbrosiaTheme.Cinematic.amberDim    // amber @ 15% — subtle tint
AmbrosiaTheme.Cinematic.smokeGray   // "#A3A3A3" — secondary text
AmbrosiaTheme.Cinematic.pureWhite   // .white — primary text
AmbrosiaTheme.Cinematic.glassDark   // black @ 55% — card background
AmbrosiaTheme.Cinematic.glassBorder // white @ 12% — card border
```

**Modern Light (used ONLY in BentoGrid / GroupSetupView contexts)**
```swift
AmbrosiaTheme.Colors.accent         // "#4F46E5" — indigo
AmbrosiaTheme.Colors.textPrimary    // "#111827"
AmbrosiaTheme.Colors.surfaceSecondary // "#F3F4F6"
```

> ⚠️ Do NOT mix Cinematic and Colors palettes in the same screen.

### Typography
```swift
AmbrosiaTheme.Typography.display     // largeTitle, rounded, bold
AmbrosiaTheme.Typography.header      // title2, rounded, semibold
AmbrosiaTheme.Typography.headline    // headline, rounded, semibold
AmbrosiaTheme.Typography.body        // body, rounded
AmbrosiaTheme.Typography.caption     // caption, rounded, medium
AmbrosiaTheme.Typography.button      // callout, rounded, semibold
AmbrosiaTheme.Typography.bentoNumber // 48pt, bold, rounded (large stat numbers)

// Cinematic condensed fonts (hero screens only)
Font.cinematicHero(size: 88)         // condensed black — for NOD branding
Font.cinematicSubHero(size: 18)      // condensed regular
```

### Spacing Tokens
```swift
AmbrosiaTheme.Spacing.xs  // 4
AmbrosiaTheme.Spacing.sm  // 8
AmbrosiaTheme.Spacing.md  // 12
AmbrosiaTheme.Spacing.lg  // 16
AmbrosiaTheme.Spacing.xl  // 24
AmbrosiaTheme.Spacing.xxl // 32
```

### Corner Radius Tokens
```swift
AmbrosiaTheme.Radius.sm  // 8
AmbrosiaTheme.Radius.md  // 12
AmbrosiaTheme.Radius.lg  // 16
AmbrosiaTheme.Radius.xl  // 20
AmbrosiaTheme.Radius.xxl // 24
```

### Animation Tokens
```swift
AmbrosiaTheme.Animation.microInteraction  // spring(response:0.3, damping:0.7)
AmbrosiaTheme.Animation.standard          // easeInOut(0.25)
AmbrosiaTheme.Animation.springy          // spring(response:0.5, damping:0.6)
```

---

## 4. Reusable Components — ALWAYS USE THESE

Never build button, card, or nav bar from scratch. Use these:

### GlassButton (`Views/Components/GlassButton.swift`)
```swift
GlassButton(title: "Label", icon: "sf.symbol.name", variant: .primary) { ... }
// variant: .primary (accent fill) | .secondary (white border) | .ghost (text only)
```
- `.primary` → indigo fill, white text — primary CTA
- `.secondary` → white bg, bordered — back / cancel
- `.ghost` → no bg, accent text — subtle link-style

### FloatingNavBar (`Views/Components/FloatingNavBar.swift`)
```swift
.floatingNavBar(title: "Optional Title", leading: .init(icon: "chevron.left") { ... })
```

### FloatingBottomBar (`Views/Components/FloatingNavBar.swift`)
```swift
FloatingBottomBar {
    GlassButton(...) { ... }
}
```
Use for sticky CTA at bottom of scrollable screens.

### glassCard modifier (`Views/Components/AmbrosiaTheme.swift`)
```swift
someView.glassCard()                           // default xxl radius
someView.glassCard(cornerRadius: AmbrosiaTheme.Radius.lg)
```

### GlassChip (for toggleable selection tags)
No dedicated component yet — construct inline:
```swift
Text(label)
    .font(AmbrosiaTheme.Typography.caption)
    .padding(.vertical, AmbrosiaTheme.Spacing.sm)
    .padding(.horizontal, AmbrosiaTheme.Spacing.md)
    .foregroundColor(isSelected ? AmbrosiaTheme.Cinematic.deepBlack : AmbrosiaTheme.Cinematic.pureWhite)
    .background(.ultraThinMaterial)
    .overlay(
        Capsule().fill(AmbrosiaTheme.Cinematic.amber.opacity(isSelected ? 0.85 : 0))
    )
    .clipShape(Capsule())
```

### HapticFeedback
```swift
HapticFeedback.light.trigger()      // subtle tap
HapticFeedback.selection.trigger()  // mode selection
HapticFeedback.medium.trigger()     // confirmation / CTA
HapticFeedback.success.trigger()    // completion
```

---

## 5. Domain Model Quick Reference

```swift
struct GroupProfile {
    var headcount: Int = 4    // range 2...12
    var vetoes: [String] = [] // e.g. ["Pork", "Gluten"]
    var cravings: [String] = []
    var mood: String = "Social"
}

struct IndividualProfile {
    var partySize: Int = 1
    var vetoes: [String] = []
    var cravings: [String] = []
    var mood: String = "Relaxed"
}
```

### Standard Veto Options
```swift
[("Pork","🐷"), ("Peanuts","🥜"), ("Cilantro","🌿"),
 ("Spicy","🌶️"), ("Shellfish","🦐"), ("Gluten","🌾")]
```

### Standard Craving Options
```swift
[("Heavy & Meaty","🥩"), ("Light & Fresh","🥗"),
 ("Carb Comfort","🍝"), ("Surprise Me","✨")]
```

### Standard Mood Options
```swift
["Relaxed ✨", "Exhausted 😩", "Celebratory 🥂", "Adventurous 🧭"]
```

---

## 6. Known Issues / Do Not Reintroduce

- **ForkModeCard is deleted**: The "Dining Style" step (Share/Order Individually) was a dead-end with empty actions. Never reintroduce it unless the backend supports individual-order mode.
- **GroupSetupView is legacy**: `Views/Screens/GroupSetupView.swift` is superseded by `ProgressiveWizardView`. Do not add new flows there.
- **Error alerts**: Never use `isPresented: .constant(...)`. Error state should be dismissible and should NOT call `resetSession()` as that clears all captured images.
- **Magic numbers are banned**: Corner radii, spacing, font sizes MUST come from `AmbrosiaTheme` tokens.

---

## 7. File Modification Policy

When asked to change UI behavior:
1. Identify the **single file** responsible — prefer surgical edits over cross-file changes
2. State which files you will touch before writing code
3. Never touch `Core/Domain/`, `Core/AgentProtocols.swift`, or `AmbrosiaApp.swift` unless explicitly asked
4. Never add new third-party dependencies
