# Ambrosia V2: Design Evolution

## 1. Context & Motivation
The initial "Ambrosia V1" suffered from a "Dictator Model" problem: it treated every session as a single user ("The Leader") making decisions for a group. This failed to address the distinct psychological needs of dining:

- **Individual Mode**: Curiosity, exploration, "What is this?", "Will I like it?".
- **Share Mode (Group)**: Safety, consensus, "Avoid bombs", "Feed everyone".

**V2 Goal**: Split the product into two distinct modes at the entry point to serve these conflicting needs effectively.

## 2. Core Architecture: The Mode Split

### Entry Point (WelcomeView)
Instead of just "Tap to Scan", the user selects a mode immediately:
1.  **"Order for Myself" (Individual)** -> Launches Decoder + Translator.
2.  **"We are Sharing" (Group)** -> Launches Decoder + Consensus Engine.

## 3. Mode A: Individual (The Explorer)
**User Intent**: "I want to know what this is and find my dish."

**Key Features**:
-   **Visual Translation**: Overlay English/Explanation on the menu items.
-   **Personal Match**: "Match Score" (0-100%) based on my taste profile (e.g., "Spicy Lover").
-   **The "Helper"**: A chatbot that answers "Is this spicy?", "What is 'Husband Wife Lung Slices'?".

**Data Model Changes**:
-   `UserProfile` remains simple (1 person).
-   Output is a List of Items sorted by Match Score.

## 4. Mode B: The "Spontaneous Group" Scenario

### Philosophy: Decision Velocity
**Core Problem**: The "Lowest Common Denominator" effect. The group moves as slow as its most indecisive member (who knows what they *don't* want, but not what they *do* want).
**Core Solution**:
1.  **Multiple Choice Only**: Never ask open-ended questions like "What do you want?". Always ask "Do you prefer A, B, or C?".
2.  **Source-Grounded**: Choices are backed by "Research" (Reviews/Specialties) + "Reality" (Menu Content).

### The Revised Workflow (The Loop)
1.  **Scan Phase**: User scans Menu + Drink List.
2.  **Wizard Phase**: Headcount -> Budget -> Taboos.
3.  **Recommendation Phase (The "Happy Path")**:
    -   **Logic**: The AI generates a **"Virtual Combo"**.
        -   *Scenario A*: The menu has a "Family Set for 4". AI evaluates if it fits the filters. If yes, recommend it.
        -   *Scenario B use case (Most Common)*: Menu is a la carte. **AI assembles** individual dishes (1 Soup + 2 Hot + 1 Cold) into a cohesive "Set" and names it (e.g., "The Spicy Lover's Feast").
    -   **Output**: AI presents **3 Options**:
        1.  "The Safe Bet" (Popular items).
        2.  "The Local Experience" (Authentic/Spicy).
        3.  "The Value Choice" (Best bang for buck).
    -   User selects one. -> Done.
4.  **Refinement Phase (The "Something Else" Loop)**:
    -   User says: "I don't like these. I want something else, like 'Seafood' or 'Fried'."
    -   AI Action: Re-scans the *original menu data*, filters by keyword, checks constraints.
    -   AI Output: Presents **3 NEW Options** matching the keyword. "Here are 3 Seafood dishes that fit your budget."
5.  **Sommelier Phase**:
    -   AI asks "Drinks?". Output: 3x Alcoholic, 3x Non-Alcoholic.

**Data Model Changes**:
```swift
struct GroupProfile {
    var headcount: Int
    var budgetTotal: Int
    var dietaryRestrictions: [String]
    var collectiveAllergies: [String]
    // The Refinement Loop
    var refinementKeywords: [String] = [] // "Seafood", "Fried"
}

struct ComboRecommendation {
    let name: String
    let dishes: [MenuItem]
    let drinks: [DrinkRecommendation] // Added
    let totalPrice: Double
    let reasoning: String
}

struct DrinkRecommendation: Codable {
    let name: String
    let type: String // "Alcoholic" or "Zero-Proof"
    let reason: String
}
```

## 5. Technical Implementation Strategy

### Phase 2.1: UI Fork
-   **WelcomeView**: Add detailed toggle or two large distinct cards.
-   **SetupFlow**:
    -   Individual: "What do you like?" (Taste)
    -   Group: "Who is eating?" (Count + Allergies)

### Phase 2.2: CultureAgent Upgrade
-   **Prompt Engineering**: separate `buildIndividualPrompt` vs `buildGroupPrompt`.
-   **Group Prompt**: Instructs Gemini to output a JSON array of dishes (The Combo) and validate constraints explicitly.

### Phase 2.3: State Machine Update
-   Update `AmbrosiaManager` state to track mode: `.individual | .group`.
-   Pass distinct context to Agents based on mode.

## 6. Success Metrics (V2)
-   **Group Mode**: "Time to Order" reduced. Users accept the "Safe Combo" quickly.
-   **Individual Mode**: "Engagement Depth". Users click into dishes to read cultural stories.
