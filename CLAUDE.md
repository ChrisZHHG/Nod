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

## 3. Design System & Components

All design tokens (Colors, Typography, Spacing, Radius) are centralized in `Views/Components/AmbrosiaTheme.swift`.
- **Primary Style**: Cinematic (dark). Do NOT use generic Swift colors (e.g. `.black`, `.gray`). Use `AmbrosiaTheme.Cinematic.XXX`
- **Magic numbers are banned**: padding, corner radius, and font sizes MUST come from `AmbrosiaTheme`.

Use established reusable components instead of building from scratch:
- `GlassButton` (for all CTAs)
- `FloatingNavBar` & `FloatingBottomBar`
- `.glassCard()` view modifier
See the source files in `Views/Components/` for usage examples.

---

## 4. Domain Models
Read `Core/Domain/A2AContracts.swift` or `Core/Domain/MenuModels.swift` directly for exact definitions of `GroupProfile`, `IndividualProfile`, etc. Do not drift from their schemas.

---

## 6. Known Issues / Do Not Reintroduce

- **ForkModeCard is deleted**: The "Dining Style" step (Share/Order Individually) was a dead-end with empty actions. Never reintroduce it unless the backend supports individual-order mode.
- **GroupSetupView is legacy**: `Views/Screens/GroupSetupView.swift` is superseded by `ProgressiveWizardView`. Do not add new flows there.
- **Error alerts**: Never use `isPresented: .constant(...)`. Error state should be dismissible and should NOT call `resetSession()` as that clears all captured images.
- **Magic numbers are banned**: Corner radii, spacing, font sizes MUST come from `AmbrosiaTheme` tokens.

---

## 7. File Modification Policy

When asked to change UI behavior:
1. **ACTIVATE FRONTEND DESIGNER SKILLS (WITH STRICT THEME CONSTRAINTS)**: You must act as a premium frontend designer to ensure high-contrast accessibility and rich micro-interactions. **HOWEVER**, your design choices MUST strictly use the `AmbrosiaTheme` design tokens. If there is a conflict between your general design knowledge and `AmbrosiaTheme`, the `AmbrosiaTheme` tokens take ABSOLUTE precedence. DO NOT invent new colors or spacing values.
2. Identify the **single file** responsible — prefer surgical edits over cross-file changes.
3. State which files you will touch before writing code.
4. Never touch `Core/Domain/`, `Core/AgentProtocols.swift`, or `AmbrosiaApp.swift` unless explicitly asked.
5. Never add new third-party dependencies.

---

## 8. Git & Version Control Policy

**CRITICAL RULE**: Do NOT commit directly to the current working branch when developing new features or bug fixes.
1. ALWAYS create a new branch for your work:
   - For features: `git checkout -b feature/your-feature-name`
   - For bug fixes: `git checkout -b fix/your-bug-name`
2. Keep branches modular and strictly scoped. Do not mix unrelated bug fixes and features in the same branch.
3. Use descriptive, conventional commit messages (e.g., `feat: ...`, `fix: ...`, `refactor: ...`).
