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

## 4. Future Vision & The "Narrow" Moat

*(See `design_doc/Market_Fit_Evolution.md` for full market analysis)*

### We Will NOT Build:
*   **Direct POS Ordering:** We will not integrate with restaurant point-of-sale systems. It is a B2B sales nightmare that distracts from our consumer focus.
*   **Uber Eats Integration:** We are an "at-the-table" tool, not a delivery aggregator.
*   **Generic Text Chatbots:** Users facing cognitive fatigue do not want to type paragraphs to an AI.

### We WILL Build (The Moat):
1.  **The Lifelong Taste Profile:** By recording feedback on every meal (via `HistoryStore`), Nod becomes the only app that truly knows the user's evolving palate and strict health boundaries across borders and platforms. This is a data asset Yelp and OpenTable cannot replicate.
2.  **Agentic UI (AUI):** We will move away from static results towards dynamic UI generation. If a user has a complex request ("Find a non-spicy, nut-free kid's meal"), Nod won't reply with a text block; it will instantly synthesize a custom, visual carousel card specific to that micro-need.
3.  **The "Invisible" Copilot:** Nod should require zero typing by default. It cross-references the OCR'd menu against the user's `HistoryStore` silently, highlighting the safest and most culturally relevant dishes instantly. Text/Voice chat only surfaces as an optional fallback for highly complex edge-cases.
