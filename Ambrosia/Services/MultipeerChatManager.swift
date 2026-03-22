import Foundation
import MultipeerConnectivity
import OSLog

// MARK: - MultipeerChatManager
// Handles all P2P networking for the A2A Agent Chat feature.
// Responsibilities: peer discovery, session lifecycle, message broadcast,
// auto-reconnect with exponential backoff, and chat-history sync on rejoin.

@Observable
final class MultipeerChatManager: NSObject, Sendable {
    private let myPeerId: MCPeerID
    private let serviceType = "nod-a2a"
    private let session: MCSession
    private var advertiser: MCNearbyServiceAdvertiser?
    private var browser: MCNearbyServiceBrowser?

    // AsyncStream for delivering incoming payloads to the UI / Algorithms layer.
    private let incomingPayloadsContinuation: AsyncStream<A2APayload>.Continuation
    let incomingMessages: AsyncStream<A2APayload>

    /// Nearby peers detected by the browser (delegate view: pick a host to join).
    var availableHosts: [MCPeerID] = []

    /// Currently connected peers (host view: lobby headcount).
    var connectedPeers: [MCPeerID] = []

    // MARK: - Status

    /// True while trying to re-establish a dropped connection.
    var isReconnecting = false

    // Session role flags
    var isHosting = false
    var isBrowsing = false

    // MARK: - Reconnect State (private)

    /// Whether this device is running as Host (controls reconnect strategy).
    private var actingAsHost = false

    /// Retry attempt counter — reset on successful connection.
    private var reconnectAttempt = 0

    /// Maximum number of reconnect retries before giving up.
    private let maxReconnectAttempts = 5

    /// Backoff delays in seconds: 0 (immediate), 2, 5, 10, 20
    private let backoffDelays: [UInt64] = [0, 2, 5, 10, 20]

    // MARK: - Chat History (Host only)

    /// The Host stores a local copy of the transcript so it can sync it
    /// to any Delegate that reconnects mid-session.
    var chatHistory: [ChatMessage] = []

    // MARK: - Init

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
        incomingPayloadsContinuation.finish()
    }

    // MARK: - Hosting

    func startHosting() {
        guard !isHosting else { return }
        actingAsHost = true
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
        chatHistory.removeAll()
        actingAsHost = false
    }

    // MARK: - Browsing (Delegate)

    func startBrowsing() {
        guard !isBrowsing else { return }
        actingAsHost = false
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

    // MARK: - Broadcasting

    func broadcast(payload: A2APayload) throws {
        guard !session.connectedPeers.isEmpty else {
            Logger.network.warning("⚠️ Cannot broadcast: No connected peers.")
            return
        }
        let data = try JSONEncoder().encode(payload)
        if data.count > 100_000 {
            Logger.network.warning("⚠️ Payload is unusually large: \(data.count) bytes.")
        }
        try session.send(data, toPeers: session.connectedPeers, with: .reliable)
        Logger.network.info("📤 Broadcasted \(payload.type.rawValue) to \(self.session.connectedPeers.count) peers.")
    }

    /// Sends a payload to a single specific peer (used for history sync on rejoin).
    private func send(payload: A2APayload, to peer: MCPeerID) throws {
        let data = try JSONEncoder().encode(payload)
        try session.send(data, toPeers: [peer], with: .reliable)
    }

    // MARK: - Reconnect Logic

    /// Called when a peer disconnects. Applies role-appropriate reconnect strategy.
    private func handleDisconnect(peer: MCPeerID) {
        Logger.network.warning("❌ Peer disconnected: \(peer.displayName). Attempting reconnect...")
        isReconnecting = true
        reconnectAttempt = 0

        if actingAsHost {
            // Host re-advertises so the lost delegate can find and rejoin.
            scheduleHostReAdvertise()
        } else {
            // Delegate restarts browsing to find the host again.
            scheduleDelegateRejoin()
        }
    }

    private func scheduleHostReAdvertise() {
        guard reconnectAttempt < maxReconnectAttempts else {
            Logger.network.error("🚫 Host gave up re-advertising after \(self.maxReconnectAttempts) attempts.")
            DispatchQueue.main.async { self.isReconnecting = false }
            return
        }
        let delay = backoffDelays[min(reconnectAttempt, backoffDelays.count - 1)]
        Logger.network.info("♻️ Host re-advertise attempt \(self.reconnectAttempt + 1) in \(delay)s...")
        DispatchQueue.global().asyncAfter(deadline: .now() + Double(delay)) { [weak self] in
            guard let self else { return }
            // If a peer already reconnected while waiting, stop.
            guard !self.session.connectedPeers.isEmpty == false else {
                self.isReconnecting = false
                return
            }
            self.advertiser?.stopAdvertisingPeer()
            self.advertiser?.startAdvertisingPeer()
            self.reconnectAttempt += 1
            self.scheduleHostReAdvertise()
        }
    }

    private func scheduleDelegateRejoin() {
        guard reconnectAttempt < maxReconnectAttempts else {
            Logger.network.error("🚫 Delegate gave up rejoining after \(self.maxReconnectAttempts) attempts.")
            DispatchQueue.main.async { self.isReconnecting = false }
            return
        }
        let delay = backoffDelays[min(reconnectAttempt, backoffDelays.count - 1)]
        Logger.network.info("♻️ Delegate rejoin attempt \(self.reconnectAttempt + 1) in \(delay)s...")
        DispatchQueue.global().asyncAfter(deadline: .now() + Double(delay)) { [weak self] in
            guard let self else { return }
            guard !self.session.connectedPeers.isEmpty == false else {
                self.isReconnecting = false
                return
            }
            self.browser?.stopBrowsingForPeers()
            self.browser?.startBrowsingForPeers()
            self.reconnectAttempt += 1
            self.scheduleDelegateRejoin()
        }
    }

    /// Called when a peer reconnects successfully.
    /// If we are the Host, we send the full chat history to the rejoined peer.
    private func handleReconnect(peer: MCPeerID) {
        Logger.network.info("✅ Peer reconnected: \(peer.displayName). Reconnect attempt count reset.")
        reconnectAttempt = 0
        DispatchQueue.main.async { self.isReconnecting = false }

        guard actingAsHost, !chatHistory.isEmpty else { return }

        Logger.network.info("📜 Syncing \(self.chatHistory.count) messages to rejoined peer \(peer.displayName).")
        let syncPayload = ChatHistorySyncPayload(messages: chatHistory)
        guard let data = try? JSONEncoder().encode(syncPayload) else { return }
        let envelope = A2APayload(type: .chatHistorySync, senderID: UUID(), data: data)
        try? send(payload: envelope, to: peer)
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
            handleReconnect(peer: peerID)
        case .connecting:
            Logger.network.info("⏳ Peer Connecting: \(peerID.displayName)")
        case .notConnected:
            Logger.network.info("❌ Peer Disconnected: \(peerID.displayName)")
            // Only trigger reconnect if we were previously fully connected (not first-join failures).
            if isHosting || isBrowsing {
                handleDisconnect(peer: peerID)
            }
        @unknown default:
            break
        }
    }

    func session(_ session: MCSession, didReceive data: Data, fromPeer peerID: MCPeerID) {
        do {
            let payload = try JSONDecoder().decode(A2APayload.self, from: data)
            Logger.network.info("📥 Received \(payload.type.rawValue) from \(peerID.displayName) (\(data.count) bytes)")
            incomingPayloadsContinuation.yield(payload)
        } catch {
            Logger.network.error("💥 Failed to decode payload from \(peerID.displayName): \(error)")
        }
    }

    func session(_ session: MCSession, didReceive stream: InputStream, withName streamName: String, fromPeer peerID: MCPeerID) {}
    func session(_ session: MCSession, didStartReceivingResourceWithName resourceName: String, fromPeer peerID: MCPeerID, with progress: Progress) {}
    func session(_ session: MCSession, didFinishReceivingResourceWithName resourceName: String, fromPeer peerID: MCPeerID, at localURL: URL?, withError error: Error?) {}
}

// MARK: - MCNearbyServiceAdvertiserDelegate

extension MultipeerChatManager: MCNearbyServiceAdvertiserDelegate {
    func advertiser(_ advertiser: MCNearbyServiceAdvertiser, didReceiveInvitationFromPeer peerID: MCPeerID, withContext context: Data?, invitationHandler: @escaping (Bool, MCSession?) -> Void) {
        Logger.network.info("📬 Received invitation from \(peerID.displayName). Auto-accepting.")
        invitationHandler(true, session)
    }
}

// MARK: - MCNearbyServiceBrowserDelegate

extension MultipeerChatManager: MCNearbyServiceBrowserDelegate {
    func browser(_ browser: MCNearbyServiceBrowser, foundPeer peerID: MCPeerID, withDiscoveryInfo info: [String: String]?) {
        Logger.network.info("🔭 Found Host: \(peerID.displayName)")
        DispatchQueue.main.async {
            if !self.availableHosts.contains(peerID) {
                self.availableHosts.append(peerID)
            }
        }
        // If we are reconnecting, auto-rejoin the first host we find.
        if isReconnecting {
            Logger.network.info("♻️ Auto-rejoining \(peerID.displayName) after reconnect.")
            joinHost(peerID)
        }
    }

    func browser(_ browser: MCNearbyServiceBrowser, lostPeer peerID: MCPeerID) {
        Logger.network.info("💨 Lost Host: \(peerID.displayName)")
        DispatchQueue.main.async {
            self.availableHosts.removeAll { $0 == peerID }
        }
    }
}

// MARK: - Logger

extension Logger {
    static let network = Logger(subsystem: "com.nod.a2a", category: "Multipeer")
}
