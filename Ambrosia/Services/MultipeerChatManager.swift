import Foundation
import MultipeerConnectivity
import OSLog

// MARK: - Step 3: Inside-Out Build Order (Networking)
// Depends inward on Core Types (`A2APayload`, `ChatMessage`).

@Observable
final class MultipeerChatManager: NSObject, Sendable {
    private let myPeerId: MCPeerID
    private let serviceType = "nod-a2a"
    private let session: MCSession
    private var advertiser: MCNearbyServiceAdvertiser?
    private var browser: MCNearbyServiceBrowser?
    
    // Using an AsyncStream continuation to safely stream incoming network payloads to the UI/Algorithms
    private let incomingPayloadsContinuation: AsyncStream<A2APayload>.Continuation
    let incomingMessages: AsyncStream<A2APayload>
    
    /// Published array of detected nearby peers so the DelegateJoinView can show them
    var availableHosts: [MCPeerID] = []
    
    /// Published array of connected peers for the Host to monitor the Lobby
    var connectedPeers: [MCPeerID] = []
    
    // Status flags
    var isHosting = false
    var isBrowsing = false
    
    init(displayName: String) {
        self.myPeerId = MCPeerID(displayName: displayName)
        self.session = MCSession(peer: myPeerId, securityIdentity: nil, encryptionPreference: .required)
        
        let (stream, continuation) = AsyncStream.makeStream(of: A2APayload.self)
        self.incomingMessages = stream
        self.incomingPayloadsContinuation = continuation
        
        super.init()
        self.session.delegate = self
    }
    
    deinit {
        advertiser?.stopAdvertisingPeer()
        browser?.stopBrowsingForPeers()
        session.disconnect()
    }
    
    // MARK: - Hosting (The Moderator)
    
    func startHosting() {
        guard !isHosting else { return }
        advertiser = MCNearbyServiceAdvertiser(peer: myPeerId, discoveryInfo: nil, serviceType: serviceType)
        advertiser?.delegate = self
        advertiser?.startAdvertisingPeer()
        isHosting = true
        Logger.network.info("📡 Started advertising Nod A2A Lobby as \(self.myPeerId.displayName)")
    }
    
    func stopHosting() {
        advertiser?.stopAdvertisingPeer()
        advertiser = nil
        isHosting = false
        session.disconnect()
        connectedPeers.removeAll()
    }
    
    // MARK: - Browsing (The Delegate)
    
    func startBrowsing() {
        guard !isBrowsing else { return }
        availableHosts.removeAll()
        browser = MCNearbyServiceBrowser(peer: myPeerId, serviceType: serviceType)
        browser?.delegate = self
        browser?.startBrowsingForPeers()
        isBrowsing = true
        Logger.network.info("🔍 Started browsing for Nod A2A Hosts")
    }
    
    func stopBrowsing() {
        browser?.stopBrowsingForPeers()
        browser = nil
        isBrowsing = false
    }
    
    func joinHost(_ hostPeer: MCPeerID) {
        guard isBrowsing else { return }
        Logger.network.info("🤝 Attempting to join Host: \(hostPeer.displayName)")
        browser?.invitePeer(hostPeer, to: session, withContext: nil, timeout: 30)
    }
    
    // MARK: - Broadcasting (Data Transmission)
    
    func broadcast(payload: A2APayload) throws {
        guard !session.connectedPeers.isEmpty else {
            Logger.network.warning("⚠️ Cannot broadcast: No connected peers.")
            return
        }
        
        let data = try JSONEncoder().encode(payload)
        // Ensure data isn't massively exceeding Multipeer limits implicitly (Principle 6: Memory as distilled truth)
        if data.count > 100_000 {
            Logger.network.warning("⚠️ Payload is unusually large: \(data.count) bytes. Might drop.")
        }
        
        try session.send(data, toPeers: session.connectedPeers, with: .reliable)
        Logger.network.info("📤 Broadcasted payload of type \(payload.type.rawValue) to \(self.session.connectedPeers.count) peers.")
    }
}

// MARK: - MCSessionDelegate
extension MultipeerChatManager: MCSessionDelegate {
    func session(_ session: MCSession, peer peerID: MCPeerID, didChange state: MCSessionState) {
        DispatchQueue.main.async {
            self.connectedPeers = session.connectedPeers
        }
        switch state {
        case .connected:
            Logger.network.info("✅ Peer Connected: \(peerID.displayName)")
        case .connecting:
            Logger.network.info("⏳ Peer Connecting: \(peerID.displayName)")
        case .notConnected:
            Logger.network.info("❌ Peer Disconnected: \(peerID.displayName)")
        @unknown default:
            break
        }
    }
    
    func session(_ session: MCSession, didReceive data: Data, fromPeer peerID: MCPeerID) {
        do {
            let payload = try JSONDecoder().decode(A2APayload.self, from: data)
            Logger.network.info("📥 Received \(payload.type.rawValue) payload from \(peerID.displayName) (\(data.count) bytes)")
            incomingPayloadsContinuation.yield(payload)
        } catch {
            Logger.network.error("💥 Failed to decode incoming payload from \(peerID.displayName): \(error)")
        }
    }
    
    func session(_ session: MCSession, didReceive stream: InputStream, withName streamName: String, fromPeer peerID: MCPeerID) {}
    func session(_ session: MCSession, didStartReceivingResourceWithName resourceName: String, fromPeer peerID: MCPeerID, with progress: Progress) {}
    func session(_ session: MCSession, didFinishReceivingResourceWithName resourceName: String, fromPeer peerID: MCPeerID, at localURL: URL?, withError error: Error?) {}
}

// MARK: - MCNearbyServiceAdvertiserDelegate
extension MultipeerChatManager: MCNearbyServiceAdvertiserDelegate {
    func advertiser(_ advertiser: MCNearbyServiceAdvertiser, didReceiveInvitationFromPeer peerID: MCPeerID, withContext context: Data?, invitationHandler: @escaping (Bool, MCSession?) -> Void) {
        Logger.network.info("📬 Received invitation from Delegate: \(peerID.displayName). Auto-accepting into Lobby.")
        // For Nod V3 MVP, the Host auto-accepts all delegates who find the lobby.
        invitationHandler(true, session)
    }
}

// MARK: - MCNearbyServiceBrowserDelegate
extension MultipeerChatManager: MCNearbyServiceBrowserDelegate {
    func browser(_ browser: MCNearbyServiceBrowser, foundPeer peerID: MCPeerID, withDiscoveryInfo info: [String : String]?) {
        Logger.network.info("🔭 Found Host: \(peerID.displayName)")
        DispatchQueue.main.async {
            if !self.availableHosts.contains(peerID) {
                self.availableHosts.append(peerID)
            }
        }
    }
    
    func browser(_ browser: MCNearbyServiceBrowser, lostPeer peerID: MCPeerID) {
        Logger.network.info("💨 Lost Host: \(peerID.displayName)")
        DispatchQueue.main.async {
            self.availableHosts.removeAll { $0 == peerID }
        }
    }
}

// Helper generic logger
extension Logger {
    static let network = Logger(subsystem: "com.nod.a2a", category: "Multipeer")
}
