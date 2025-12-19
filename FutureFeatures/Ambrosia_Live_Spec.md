# Ambrosia Live: Multimodal Group Decision Assistant (Future Feature)

> **Status**: Draft / Deferred (Post-MVP)
> **Goal**: Enable a real-time, "Group Decision" experience where users can converse with AI while it "sees" the menu via the camera.

## 1. Feature Overview

**The Prompt**: "We are a group of 4, one person hates cilantro, we want something spicy but shareable. What should we get?"
**The Experience**: Users place the phone on the table or hold it up to the menu. They talk naturally. The AI hears them AND sees where they are pointing on the menu, responding via voice (Audio).

## 2. Technical Architecture

Unlike the MVP (REST API, Request/Response), this feature requires a persistent **WebSocket** connection for low-latency streaming.

### A. The Pipeline
1.  **Input (iOS Client)**:
    *   **Video**: `AVCaptureSession` captures frames.
    *   **Audio**: `AVAudioEngine` captures microphone input.
2.  **Transport (WebSocket)**:
    *   Connect to `wss://generativelanguage.googleapis.com/v1alpha/models/gemini-1.5-pro-latest:compute` (or equivalent Live endpoint).
    *   Send `BidiGenerateContentClientMessage` (Real-time Input).
3.  **Processing (Gemini)**:
    *   Model consumes interleaved Audio + Video frames.
    *    Maintains context window of the conversation.
4.  **Output (iOS Client)**:
    *   Receive `BidiGenerateContentServerMessage` (Real-time Output).
    *   Play raw PCM audio via `AVAudioPlayerNode`.

### B. Cost & Performance Strategy (CRITICAL)

Streaming 30fps video tokens is prohibitively expensive and unnecessary for a static menu.

*   **Video Strategy**: "Low-FPS Context"
    *   **Frame Rate**: Cap transmission at **0.5 FPS** (1 frame every 2 seconds).
    *   **Logic**: The menu doesn't move much. We only need to update the model when the camera moves significantly or user points to a new section.
    *   **Savings**: ~98% reduction in token usage compared to standard video calls.
*   **Audio Strategy**: "High-Fidelity"
    *   Stream audio continuously for natural interruption handling.

## 3. Implementation Modules

### `LiveCameraManager` (New)
*   Replaces `DataScannerViewController` for this mode.
*   Manages `AVCaptureSession`.
*   extracts `CMSampleBuffer` -> converts to `Data` (JPEG/HEIC) -> Resize to 512x512 (sufficient for text).

### `LiveAudioSession` (New)
*   Manages Microphone permissions and `AVAudioEngine`.
*   Handles Echo Cancellation (VoiceProcessingIO).

### `GeminiSocketClient` (New)
*   Manages the WebSocket connection.
*   Handles the handshake and session configuration (System Instructions: "You are a helpful waiter assisting a group...").

## 4. User Interface (UI)

*   **Entry Point**: A "Live Partner" button on the main screen.
*   **Main View**:
    *   **Background**: Full-screen camera feed.
    *   **Overlay**: Minimalist.
    *   **Visualizer**: A dynamic waveform at the bottom (Siri-like) reacting to user voice and AI voice.
    *   **Controls**: Mute Mic, End Session.

## 5. Potential Roadmap

1.  **Phase 1**: Blind Audio Mode (Audio-only Live). Easier to implement, tests WebSocket latency.
2.  **Phase 2**: The "Eye" (Add Video Stream at 0.5 FPS).
3.  **Phase 3**: "Pointer Awareness" (If possible, detect finger pointing coordinates to crop regions).
