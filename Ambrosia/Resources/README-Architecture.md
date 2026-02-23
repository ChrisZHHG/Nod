# Ambrosia Architecture Documentation

## Overview

Ambrosia is an AI-powered menu recommendation app built with SwiftUI, featuring a multi-agent architecture powered by Google Gemini.

---

## Architecture Diagram

```mermaid
flowchart TD
    subgraph UI["SwiftUI Layer"]
        ModeSelection[ModeSelectionView]
        Scanner[ScannerView]
        Result[ChefCardView / ComboResultView]
    end
    
    subgraph Core["State Management"]
        Store[AppStore]
    end
    
    subgraph Agents["AI Agent Pipeline"]
        Decoder[DecoderAgent]
        Chef[ChefAgent]
        Safety[SafetyAgent]
        Visualizer[VisualizerAgent]
    end
    
    subgraph Services["External Services"]
        Gemini[GeminiService]
    end
    
    ModeSelection --> Store
    Store --> Scanner
    Scanner -- "Images" --> Store
    Store --> Decoder
    Decoder -- "MenuData" --> Chef
    Chef -- "Recommendation" --> Safety
    Safety -- "Verified" --> Visualizer
    Visualizer -- "ImageURL" --> Store
    Store --> Result
    
    Decoder --> Gemini
    Chef --> Gemini
    Safety --> Gemini
    Visualizer --> Gemini
```

---

## Component Responsibilities

| Component | Responsibility |
|-----------|----------------|
| **AppStore** | Central state machine, coordinates agents, manages navigation (TCA-style) |
| **DecoderAgent** | Extracts menu data from scanned images via OCR + LLM |
| **ChefAgent** | Generates recommendations based on profile and menu |
| **SafetyAgent** | Audits recommendations for allergens and dietary restrictions |
| **VisualizerAgent** | Generates dish visualization images |
| **GeminiService** | Handles all Google Gemini API communication |

---

## State Flow

```mermaid
stateDiagram-v2
    [*] --> idle
    idle --> scanning : startSession()
    scanning --> decoding : generateRecommendation()
    decoding --> reasoning : Menu decoded
    reasoning --> verifying : Recommendation ready
    verifying --> idle : Safety passed
    idle --> [*] : Navigate to result
    
    scanning --> error : Capture failed
    decoding --> error : API error
    reasoning --> error : Generation failed
    error --> scanning : Retry
```

---

## Design System

The app uses `AmbrosiaTheme` for consistent styling:
- **Colors**: Coral Sunset palette with semantic tokens
- **Typography**: SF Pro Rounded with Dynamic Type
- **Effects**: Glass morphism via `.ultraThinMaterial`
- **Backgrounds**: `ImmersiveBackground` with MeshGradient (iOS 18+)
