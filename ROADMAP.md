# Nod (formerly Ambrosia) - Product Roadmap & Architecture Single Source of Truth (SSOT)

> **Vision:** Nod is the ultimate cognitive offloading tool for high-stress dining. It acts as a private cultural dining guide and allergy safety net for travelers and expats, empowered by a lifelong personal taste memory graph. We do not do reservations, we do not do delivery, we do not do B2B dashboards. We decode culture and protect health at the table.

## Table of Contents
1. [Current Architecture (V2)](#current-architecture-v2)
2. [Development History & Completed Phases](#development-history--completed-phases)
3. [Current Status & Strategic Pivot (V3)](#current-status--strategic-pivot-v3)
4. [Future Vision & The "Narrow" Moat](#future-vision--the-narrow-moat)

---

## 1. Current Architecture (V2)
The current architecture centers around strongly typed, concurrent multi-agent negotiation coordinated by `AppStore`.

*   **DecoderAgent:** Extracts structured JSON (`MenuData`) from physical menu photos via OCR.
*   **ResearchAgent:** Fetches live external context (Google Places ratings, popular dishes, general vibe) asynchronously.
*   **ChefAgent (The Brain):** Takes the `MenuData`, `User/Group Profiles`, and `ResearchData` to generate intelligent, personalized Combos or Individual recommendations. Computes cultural translation and hidden allergens.
*   **SafetyAgent:** A secondary validation layer that audits the `ChefAgent`'s output against strict health data (allergies, vetoes) ensuring zero fatal matches.
*   **VisualizerAgent:** Connects to generative image endpoints (e.g., Pollinations.ai) to synthesize high-quality food photography for dishes lacking native images.

---

## 2. Development History & Completed Phases

### Phase 1: Foundation & Core OCR (Completed)
- Established the base `Models.swift` containing standard menu data structuring.
- Built the `ScannerView` to capture physical menus.
- Integrated AI translation and OCR to parse images into `MenuData`.

### Phase 2: Agent Separation (Completed)
- Split monolithic logic into distinct Agents (`ChefAgent`, `SafetyAgent`, `DecoderAgent`).
- Introduced Swift Concurrency (`async/await`) for all agent network operations.

### Phase 3: Progressive Profiling & UI Polish (Completed)
- **Cinematic UI:** Replaced generic loading spinners with a blurred, dynamic `.ultraThinMaterial` typewriter interface.
- **Progressive Wizard (`ProgressiveWizardView`):** Implemented an "Effortless Consensus" flow—replacing raw text inputs with visual toggle grids.
- **Multi-Choice Output (`MultiChoiceResultCarousel`):** Evolved the UX from generating a single rigid dish to providing nuance (Safe, Secret, Adventurous).

### Phase 4: Group Mode & Combo Refinements (Completed)
- **Dish Validation:** Enforced strict `EXCLUDE` prompts in `ChefAgent` to stop hallucination.
- **Concurrent Images:** Overhauled `AppStore` to launch concurrent `VisualizerAgent` calls fetching real imagery.
- **Agent Chat & Consensus Parser:** Implemented A2A negotiation logic utilizing multipeer connectivity.

---

## 3. Current Status & Strategic Pivot (V3)

**Current Status:** The V2 application is fully stable and capable of generating safe, visually rich recommendations. However, to construct a long-term commercial moat and avoid the "use once and delete" trap of generic utilities, we are pivoting our strategic focus.

**The Pivot:** We are abandoning generic "what to eat" use cases to hyper-focus on two critical, high-willingness-to-pay scenarios:
1.  **The Expat/Tourist Cultural Decoder:** Users facing severe language barriers and cultural unfamiliarity (e.g. an American in a rural Japanese Izakaya).
2.  **The Medical Defense Line:** Users with severe allergies needing trusted, ingredient-level validation.

**Immediate Next Steps (Executing the Pivot):**
1.  **Wire the HistoryStore:** Our primary defensive moat is the "Personal Taste Memory Graph". We must wire the existing `HistoryStore.swift` into the `AppRootView` so the app begins remembering what users order and like.
2.  **Elevate Cultural Context:** Update the `ChefAgent` output and UI to explicitly highlight "Cultural Context" and "Hidden Allergens" as the primary value drivers, rather than just "Taste".
3.  **Language Detection & Translation:** Surface the detected menu language and provide seamless translations of exotic ingredients (e.g. explaining what "Katsuura" style means, not just translating the word).

---

## 4. Future Vision: BYOB & The Agentic Ecosystem (V3)

*(See `design_doc/Market_Fit_Evolution.md` for full market analysis)*

### We Will NOT Build:
*   **Direct POS Ordering:** We will not integrate with restaurant point-of-sale systems natively. It distracts from our consumer focus.
*   **Generic Text Chatbots:** Users facing cognitive fatigue do not want to type paragraphs to an AI as a primary interaction.

### The Agentic Engineering Roadmap (The Structural Moat):
1.  **The Lifelong Memory Graph (`HistoryStore`):** The absolute priority. Nod must record every meal feedback to build a cross-border personal taste graph. This forms the foundation for bypassing user input entirely.
2.  **Proxy Profiles & Memory Segregation:** To solve the multi-user "cold start" (e.g., family dining with children), the data layer will support "Household Managers." A parent's device can locally store a child's "red-line" dietary constraints (e.g., Peanut Allergy) without requiring the child to have an independent bot.
3.  **Silent A2A & Headless Consensus:** When multiple adults dine together, their agents will communicate via JSON-RPC over `MultipeerConnectivity` *silently* in the background. The app will bypass sequential "Chat UI" negotiation by default, instantly presenting the intersecting safe menu items.
4.  **The Chat Copilot (Fallback Engine):** The current `AgentChatView` will be repositioned. Instead of the default path, it serves as an easily accessible "Copilot Fallback" button. It handles long-tail, hyper-specific queries ("My throat hurts today, what's soft?") that structured Generative UI cannot predict.
5.  **MCP & AAuth Readiness:** We will format internal Tool-Calling payloads to model the emerging Model Context Protocol (MCP) standards. As the "Bring Your Own Bot" (BYOB) ecosystem matures, Nod will utilize Agentic Authorization (AAuth) concepts: emitting temporary constraint authorizations to external platforms without leaking the user's permanent medical history text.
