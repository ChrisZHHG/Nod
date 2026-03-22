import Foundation
import SwiftUI
import UIKit

// MARK: - App Domain (State, Action, Effect)

/// Application-wide state following TCA patterns
@Observable
@MainActor
final class AppStore {
    // MARK: - State
    
    var mode: AppMode = .individual
    var appState: AppState = .idle
    // Enforce private(set) to stop external UI mutations
    private(set) var individualProfile: IndividualProfile = .init()
    private(set) var groupProfile: GroupProfile = .init()
    var capturedImages: [Data] = []
    var cachedParsedMenu: MenuData? = nil
    private var decodingTask: Task<MenuData, Error>?
    var timelineLog: [String] = []
    
    // Navigation (using enum path for type-safe navigation)
    var navigationPath: [AppDestination] = []
    
    // A2A Chat State
    let chatManager = MultipeerChatManager(displayName: UIDevice.current.name)
    var chatTranscript: [ChatMessage] = []
    
    // Dependencies
    private let dependencies: DependencyContainer
    
    init(dependencies: DependencyContainer = .shared) {
        self.dependencies = dependencies
    }
    
    // MARK: - Actions (via methods that mirror TCA Action enum)
    
    func setMode(_ mode: AppMode) {
        self.mode = mode
        self.appState = .idle
        self.capturedImages = []
        log("🔄 Switched to \(mode) mode.")
    }
    
    // Explicit Intent to modify profiles centrally
    func updateIndividualProfile(_ update: (inout IndividualProfile) -> Void) {
        update(&individualProfile)
        log("👤 Individual Profile Updated: Vetoes[\(individualProfile.vetoes.count)] Cravings[\(individualProfile.cravings.count)]")
    }
    
    func updateGroupProfile(_ update: (inout GroupProfile) -> Void) {
        update(&groupProfile)
        log("👥 Group Profile Updated: Size[\(groupProfile.headcount)] Vetoes[\(groupProfile.vetoes.count)] Cravings[\(groupProfile.cravings.count)]")
    }
    
    func startSession() {
        self.appState = .scanning
        navigationPath.append(.scanner)
        log("👨‍✈️ Session Started (\(mode)).")
    }
    
    func resetSession() {
        self.appState = .idle
        self.navigationPath = []
        self.capturedImages = []
        self.cachedParsedMenu = nil
        self.chatTranscript = []
        self.chatManager.stopHosting()
        self.chatManager.stopBrowsing()
        self.decodingTask?.cancel()
        self.decodingTask = nil
        log("🔄 Session Reset.")
    }
    
    func captureImage(_ imageData: Data) {
        guard appState == .scanning else { return }
        capturedImages.append(imageData)
        self.cachedParsedMenu = nil // Invalidate on new photo
        self.decodingTask?.cancel()
        log("📸 Image Captured. Total: \(capturedImages.count)")
        
        // CONCURRENCY TRICK: Start the heavy OCR immediately, 
        // hiding the latency behind the upcoming Progressive UI Wizard.
        // If this background task fails, surface a recoverable error immediately
        // instead of silently hanging when the user hits 'Analyze'.
        let imagesSnapshot = capturedImages
        self.decodingTask = Task {
            do {
                log("👀 Decoder Agent: Background Scanning Menu...")
                let data = try await dependencies.decoder.decode(images: imagesSnapshot)
                await MainActor.run {
                    self.cachedParsedMenu = data
                    self.log("👀 Decoder Agent: Background Scan Complete.")
                }
                return data
            } catch {
                await MainActor.run {
                    // Only surface the error if no result was cached from a previous capture.
                    if self.cachedParsedMenu == nil {
                        self.log("❌ Decoder Agent: Background Scan Failed — \(error.localizedDescription)")
                        self.appState = .error(.decodingFailed(reason: error.localizedDescription))
                    }
                }
                throw error
            }
        }
    }
    
    // MARK: - Effects (Async Operations)
    
    func generateRecommendation() async {
        guard !capturedImages.isEmpty else {
            self.appState = .error(.noImagesCaptured)
            return
        }
        
        let orchestrator = WorkflowOrchestrator(dependencies: dependencies)
        
        let result = await orchestrator.executePipeline(
            mode: mode,
            images: capturedImages,
            individualProfile: individualProfile,
            groupProfile: groupProfile,
            cachedMenu: cachedParsedMenu,
            pendingDecodingTask: decodingTask
        ) { [weak self] progress, stage in
            Task { @MainActor in
                guard let self = self else { return }
                if progress < 0.2 {
                    self.appState = .decoding(progress: progress)
                } else if progress < 0.9 {
                    self.appState = .reasoning(stage: stage)
                } else {
                    self.appState = .verifying
                }
                self.log("⚙️ Pipeline Progress: \(stage)")
            }
        }
        
        switch result {
        case .success(let output):
            self.appState = .idle
            switch output {
            case .individual(let soloSet, let menuData):
                self.cachedParsedMenu = menuData 
                self.navigationPath.append(.soloResult(soloSet))
                self.log("🎉 Individual Recommendations Ready.")
            case .group(let groupSet, let menuData):
                self.cachedParsedMenu = menuData
                self.navigationPath.append(.groupResult(groupSet))
                self.log("🎉 Group Feast Options Ready and Verified.")
            }
        case .failure(let error):
            self.appState = .error(error)
            self.log("❌ Pipeline Error: \(error.localizedDescription)")
        }
    }
    
    // MARK: - Logging
    
    private func log(_ message: String) {
        print("[AppStore] \(message)")
        timelineLog.append(message)
    }
}
