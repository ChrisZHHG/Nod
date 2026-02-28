# Nod (formerly Ambrosia) - Product Roadmap & Architecture Single Source of Truth (SSOT)

> **Vision:** Nod is the effortless consensus engine for dining. It transitions the dining experience from a human-to-computer data entry task into a seamless Multi-Agent System (MAS) arbitration.

## Table of Contents
1. [Current Architecture (V2)](#current-architecture-v2)
2. [Development History & Completed Phases](#development-history--completed-phases)
3. [Current Status & Immediate Next Steps](#current-status--immediate-next-steps)
4. [Future Vision: Agent-to-Agent (A2A) Architecture (V3)](#future-vision-agent-to-agent-a2a-architecture-v3)

---

## 1. Current Architecture (V2)
The current architecture centers around strongly typed, concurrent multi-agent negotiation coordinated by `AppStore`.

*   **DecoderAgent:** Extracts structured JSON (`MenuData`) from physical menu photos via OCR.
*   **ResearchAgent:** Fetches live external context (Google Places ratings, popular dishes, general vibe) asynchronously.
*   **ChefAgent (The Brain):** Takes the `MenuData`, `User/Group Profiles`, and `ResearchData` to generate intelligent, personalized Combos or Individual recommendations. Enforces strict headcount constraints and exclusion rules.
*   **SafetyAgent:** A secondary validation layer that audits the `ChefAgent`'s output against strict health data (allergies, vetoes) ensuring zero fatal matches.
*   **VisualizerAgent:** Connects to generative image endpoints (e.g., Pollinations.ai) to synthesize high-quality food photography for dishes lacking native images.

---

## 2. Development History & Completed Phases

### Phase 1: Foundation & Core OCR (Completed)
- Established the base `Models.swift` containing standard menu data structuring.
- Built the `ScannerView` to capture physical menus.
- Integrated `GeminiService` to parse images into `MenuData`.

### Phase 2: Agent Separation (Completed)
- Split monolithic logic into distinct Agents (`ChefAgent`, `SafetyAgent`, `DecoderAgent`).
- Introduced Swift Concurrency (`async/await`) for all agent network operations.

### Phase 3: Progressive Profiling & UI Polish (Completed)
- **Cinematic UI:** Replaced generic loading spinners with a blurred, dynamic `.ultraThinMaterial` typewriter interface.
- **Progressive Wizard (`ProgressiveWizardView`):** Implemented an "Effortless Consensus" flow—replacing raw text inputs with visual toggle grids for Party Size, Share vs. Individual, Vetoes, and Cravings.
- **AppStore Caching:** Cached parsed OCR data so that if users use the fallback input or change their minds, re-triggering recommendations is immediate.
- **Multi-Choice Output (`MultiChoiceResultCarousel`):** Evolved the UX from generating a single rigid dish to providing 3 nuanced options (e.g., Safe, Secret, Adventurous).

### Phase 4.1: Group Mode & Combo Refinements (Completed)
- **Dish Validation:** Enforced strict `EXCLUDE ANY DISH` prompts in `ChefAgent` to stop hallucination and `SafetyAgent` veto alerts.
- **Concurrent Images:** Overhauled `AppStore` to launch concurrent `VisualizerAgent` calls fetching real imagery for every single dish inside a Group Combo concurrently.
- **Quantity Math:** Instructed `ChefAgent` to automatically calculate the right volume of food based on `group.headcount`.

---

## 3. Current Status & Immediate Next Steps

**Current Status:** The V2 application is fully stable, successfully compiling (`Build Succeeded: 0 errors`), and capable of intelligently navigating complex group constraints to generate safe, visually rich, and deeply reasoned menu combinations.

**Immediate Next Steps (Pre-V3):**
1.  **Rebranding Polish:** Ensure the new name "Nod" is consistently applied across all Xcode targets, bundle identifiers, and UI copy.
2.  **App Store Readiness:** Audit the final `Info.plist` permissions (Camera, Network) and ensure the landing UX meets Apple Human Interface Guidelines.
3.  **Real-World Stress Testing:** Test the OCR and `ChefAgent` boundaries with highly complex, multi-lingual physical menus in low-light environments.

---

## 4. Future Vision: Agent-to-Agent (A2A) Architecture (V3)
*(See `design_doc/Agent_To_Agent_Architecture.md` for full technical specifications)*

### The Effortless Consensus
In V3, Nod transitions from a GUI app to a **System-Level Multi-Agent (MAS) Host**. Users will no longer tap buttons to declare their allergies or cravings.

1.  **The Host (Nod):** Owns the objective reality (the scanned menu, the restaurant vibe, the prices).
2.  **The Delegates (Personal Bots):** Each user's private AI assistant (e.g., Apple Intelligence) holds their strict medical data, budget history, and current mood.
3.  **The Negotiation:** When the Host initiates a session, the Delegates connect via a secure protocol (e.g., Model Context Protocol). They pass structured JSON constraint payloads silently to Nod.
4.  **The Loop:** Nod's `ChefAgent` creates draft combos. The Personal Bots review and reject/accept drafts based on their users' hidden preferences. 
5.  **The Result:** Within 3 seconds of scanning a menu, the humans are presented with a flawless consensus. No arguments, no reading, no cognitive overhead.
